module Tax
  class PropertyTaxCalculator
    # 標準税率 (1.4%)
    STANDARD_TAX_RATE = 0.014

    # 免税点（単位: 円）
    EXEMPTION_THRESHOLDS = {
      land: 300_000,
      building: 200_000,
      depreciable_group: 1_500_000
    }.freeze

    def initialize(tenant:, municipality:, fiscal_year:)
      @tenant = tenant
      @municipality = municipality
      @fiscal_year = fiscal_year
    end

    def call
      begin
        calculation_run = create_calculation_run

        properties = @tenant.properties.where(municipality: @municipality)

        # カテゴリごとに合計課税標準額を計算して免税点を判定するため、
        # まず全propertyの評価額と課税標準額を計算
        property_data = properties.map do |property|
          valuation = find_or_create_valuation(property)
          assessed_value = valuation.assessed_value || 0
          tax_base = calculate_tax_base_value(assessed_value, property)

          {
            property: property,
            assessed_value: assessed_value,
            tax_base: tax_base
          }
        end

        # カテゴリごとに課税標準額の合計を計算（免税点判定対象のみ）
        # depreciation_yearがある資産は既に申告済みとして免税点判定対象外
        exemption_check_data = property_data.select do |data|
          property = data[:property]
          # 償却資産グループの場合、depreciation_yearの有無をチェック
          if property.category == "depreciable_group"
            property.fixed_assets.none? { |fa| fa.depreciation_years.exists?(fiscal_year: @fiscal_year) }
          else
            true
          end
        end

        category_totals = exemption_check_data.group_by { |data| data[:property].category }
          .transform_values { |data_list| data_list.sum { |data| data[:tax_base] } }

        # 各propertyの税額を計算（カテゴリごとの免税点判定を適用）
        property_data.each do |data|
          property = data[:property]
          assessed_value = data[:assessed_value]
          tax_base = data[:tax_base]

          # 免税点判定対象かチェック
          is_exemption_check_target = exemption_check_data.include?(data)
          category_total = category_totals[property.category] || 0

          # カテゴリごとの合計課税標準額で免税点判定（免税点判定対象のみ）
          if is_exemption_check_target && below_exemption_threshold?(category_total, property.category)
            tax_amount = 0
            exempt_reason = "Below exemption threshold"
          else
            tax_amount = tax_base * tax_rate
            exempt_reason = nil
          end

          breakdown = {
            assessed_value: assessed_value.to_i,
            tax_base_value: tax_base.to_i,
            tax_rate: tax_rate,
            tax_amount: tax_amount.to_i,
            exempt_reason: exempt_reason
          }

          CalculationResult.create!(
            tenant: @tenant,
            calculation_run: calculation_run,
            property: property,
            tax_amount: tax_amount,
            breakdown_json: breakdown
          )
        end

        calculation_run.update!(status: "succeeded")
        { success: true, calculation_run: calculation_run }
      rescue => e
        calculation_run&.update!(status: "failed", error_message: e.message)
        { success: false, error: e.message }
      end
    end

    private

    def create_calculation_run
      CalculationRun.create!(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year,
        status: "running"
      )
    end

    def find_or_create_valuation(property)
      AssetValuation.find_or_initialize_by(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year,
        property: property
      ).tap do |valuation|
        if valuation.new_record?
          # デフォルト値を設定
          assessed_value = estimate_assessed_value(property)
          valuation.assessed_value = assessed_value
          valuation.tax_base_value = calculate_tax_base_value(assessed_value, property)
          valuation.source = "auto_estimated"
          valuation.save!
        end
      end
    end

    # 課税標準額の計算（特例・減額措置を適用）
    def calculate_tax_base_value(assessed_value, property)
      case property.category
      when "land"
        apply_residential_land_exemption(assessed_value, property)
      when "building"
        apply_new_construction_reduction(assessed_value, property)
      else
        assessed_value
      end
    end

    # 住宅用地の課税標準の特例
    def apply_residential_land_exemption(assessed_value, property)
      # プロパティが住宅用地かどうかをチェック
      # 簡易的な実装: property_type が residential の場合に適用
      return assessed_value unless property.property_type == "residential"

      parcel = property.land_parcels.first
      return assessed_value unless parcel&.area_sqm

      total_area = parcel.area_sqm

      # 小規模住宅用地（200㎡以下）: 評価額 × 1/6
      # 一般住宅用地（200㎡超）: 評価額 × 1/3
      if total_area <= 200
        # 全て小規模住宅用地
        assessed_value / 6.0
      else
        # 200㎡までは1/6、超える部分は1/3
        small_scale_portion = (200.0 / total_area) * assessed_value
        general_portion = ((total_area - 200.0) / total_area) * assessed_value

        (small_scale_portion / 6.0) + (general_portion / 3.0)
      end
    end

    # 新築住宅の減額特例
    def apply_new_construction_reduction(assessed_value, property)
      # 新築住宅の減額: 3年間（または5年間）、税額の1/2を減額
      # 簡易的な実装: 新築後3年以内の場合に適用

      fixed_asset = property.fixed_assets.first
      return assessed_value unless fixed_asset

      acquired_year = fixed_asset.acquired_on.year
      current_year = @fiscal_year.year
      years_elapsed = current_year - acquired_year

      # 新築後3年以内の場合、評価額の1/2を課税標準額とする
      if years_elapsed < 3
        assessed_value / 2.0
      else
        assessed_value
      end
    end

    # 免税点の判定
    def below_exemption_threshold?(tax_base, category)
      threshold = EXEMPTION_THRESHOLDS[category.to_sym]
      return false unless threshold

      tax_base < threshold
    end

    def estimate_assessed_value(property)
      case property.category
      when "land"
        estimate_land_value(property)
      when "building"
        estimate_building_value(property)
      when "depreciable_group"
        estimate_depreciable_group_value(property)
      else
        0
      end
    end

    def estimate_land_value(property)
      # 簡易計算: 土地面積 × 単価
      parcel = property.land_parcels.first
      return 0 unless parcel&.area_sqm

      parcel.area_sqm * 100_000 # 仮の単価: 10万円/㎡
    end

    def estimate_building_value(property)
      # 家屋の評価額は固定資産税評価上の減価を使用
      fixed_asset = property.fixed_assets.first
      return 0 unless fixed_asset

      # 固定資産税評価上の減価計算を使用
      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call
      result[:success] ? result[:valuation] : fixed_asset.acquisition_cost
    end

    def estimate_depreciable_group_value(property)
      # 償却資産グループの合計評価額
      # 会計上の減価償却年データがあればそれを使用、なければ固定資産税評価上の減価計算を使用
      property.fixed_assets.sum do |fixed_asset|
        # 今年度の減価償却年データがあるかチェック
        depreciation_year = fixed_asset.depreciation_years.find_by(fiscal_year: @fiscal_year)

        if depreciation_year
          # 減価償却年データがある場合は、その帳簿価額を使用
          depreciation_year.closing_book_value || depreciation_year.opening_book_value
        else
          # 減価償却年データがない場合は、固定資産税評価上の減価計算を使用
          calculator = FixedAssetTaxValuationCalculator.new(
            fixed_asset: fixed_asset,
            fiscal_year: @fiscal_year
          )

          result = calculator.call
          result[:success] ? result[:valuation] : fixed_asset.acquisition_cost
        end
      end
    end

    def tax_rate
      # 実際には自治体ごとに異なる税率を持つべきだが、ここでは標準税率を使用
      STANDARD_TAX_RATE
    end
  end
end
