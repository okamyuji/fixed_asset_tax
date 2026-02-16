module Tax
  # 固定資産税評価上の減価計算
  # 会計上の減価償却とは別の、固定資産税評価額を算出するための計算
  # 減価率は旧定率法の償却率を使用（地方税法）
  class FixedAssetTaxValuationCalculator
    # 最低限度率（取得価額の5%）
    MINIMUM_RATE = 0.05

    def initialize(fixed_asset:, fiscal_year:)
      @fixed_asset = fixed_asset
      @fiscal_year = fiscal_year
    end

    def call
      return failure("Fixed asset not found") unless @fixed_asset
      return failure("Fiscal year not found") unless @fiscal_year

      first_year = first_assessment_year
      current_year = @fiscal_year.year
      years_elapsed = current_year - first_year

      if years_elapsed < 0
        return failure("Fiscal year is before acquisition date")
      end

      if years_elapsed == 0
        calculate_first_year_valuation
      else
        calculate_subsequent_year_valuation(years_elapsed)
      end
    end

    private

    # 初回賦課年度を求める
    # 賦課期日は1月1日。前年中に取得した資産が初年度の対象。
    # 1月1日取得はその年の賦課期日に所有 → 同年が初年度。
    def first_assessment_year
      acquired_on = @fixed_asset.acquired_on
      if acquired_on.month == 1 && acquired_on.day == 1
        acquired_on.year
      else
        acquired_on.year + 1
      end
    end

    def calculate_first_year_valuation
      rate = depreciation_rate
      acquisition_cost = @fixed_asset.acquisition_cost

      # 初年度は半年分の減価
      valuation = acquisition_cost * (1 - rate * 0.5)

      # 最低限度額チェック
      min_valuation = acquisition_cost * MINIMUM_RATE
      final_valuation = [valuation, min_valuation].max

      {
        success: true,
        years_elapsed: 0,
        valuation: final_valuation.round,
        depreciation_rate: rate,
        is_minimum: final_valuation <= min_valuation
      }
    end

    def calculate_subsequent_year_valuation(years_elapsed)
      previous_valuation = get_previous_valuation

      unless previous_valuation
        previous_valuation = calculate_valuation_retroactively(years_elapsed - 1)
      end

      rate = depreciation_rate
      acquisition_cost = @fixed_asset.acquisition_cost

      # 当年度の評価額 = 前年度評価額 × (1 - 減価率)
      valuation = previous_valuation * (1 - rate)

      # 最低限度額チェック
      min_valuation = acquisition_cost * MINIMUM_RATE
      final_valuation = [valuation, min_valuation].max

      {
        success: true,
        years_elapsed: years_elapsed,
        valuation: final_valuation.round,
        previous_valuation: previous_valuation.round,
        depreciation_rate: rate,
        is_minimum: final_valuation <= min_valuation
      }
    end

    def get_previous_valuation
      previous_fiscal_year = FiscalYear.where("year < ?", @fiscal_year.year).order(year: :desc).first
      return nil unless previous_fiscal_year

      valuation = AssetValuation.find_by(
        tenant_id: @fixed_asset.tenant_id,
        fiscal_year: previous_fiscal_year,
        property_id: @fixed_asset.property_id
      )

      valuation&.assessed_value
    end

    def calculate_valuation_retroactively(target_years_elapsed)
      acquisition_cost = @fixed_asset.acquisition_cost
      rate = depreciation_rate

      # 初年度の評価額
      valuation = acquisition_cost * (1 - rate * 0.5)

      # 2年目以降を計算
      (target_years_elapsed).times do
        valuation = valuation * (1 - rate)

        min_valuation = acquisition_cost * MINIMUM_RATE
        valuation = [valuation, min_valuation].max

        break if valuation <= min_valuation
      end

      valuation
    end

    # 固定資産税評価用の減価率を取得
    # 旧定率法の償却率テーブル（全2-52年網羅）を使用
    def depreciation_rate
      useful_life = @fixed_asset.depreciation_policy&.useful_life_years
      useful_life ||= estimate_useful_life

      rate = DepreciationRates::OLD_DECLINING_BALANCE_RATES[useful_life]
      rate || DepreciationRates::OLD_DECLINING_BALANCE_RATES[estimate_useful_life]
    end

    def estimate_useful_life
      10
    end

    def failure(message)
      { success: false, error: message }
    end
  end
end
