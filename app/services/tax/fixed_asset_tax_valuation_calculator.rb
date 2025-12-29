module Tax
  # 固定資産税評価上の減価計算
  # 会計上の減価償却とは別の、固定資産税評価額を算出するための計算
  class FixedAssetTaxValuationCalculator
    # 固定資産税評価用の減価率テーブル（耐用年数別）
    # 旧定率法の減価率を使用
    DEPRECIATION_RATES = {
      2 => 0.684,
      3 => 0.536,
      4 => 0.438,
      5 => 0.369,
      6 => 0.319,
      7 => 0.280,
      8 => 0.250,
      9 => 0.226,
      10 => 0.206,
      15 => 0.142,
      20 => 0.109,
      25 => 0.088,
      30 => 0.074
    }.freeze

    # 最低限度率（取得価額の5%）
    MINIMUM_RATE = 0.05

    def initialize(fixed_asset:, fiscal_year:)
      @fixed_asset = fixed_asset
      @fiscal_year = fiscal_year
    end

    def call
      return failure("Fixed asset not found") unless @fixed_asset
      return failure("Fiscal year not found") unless @fiscal_year

      # 取得年を計算
      acquired_year = @fixed_asset.acquired_on.year
      current_year = @fiscal_year.year
      years_elapsed = current_year - acquired_year

      if years_elapsed < 0
        return failure("Fiscal year is before acquisition date")
      end

      if years_elapsed == 0
        # 初年度: 半年償却
        calculate_first_year_valuation
      else
        # 2年目以降: 前年度評価額 × (1 - 減価率)
        calculate_subsequent_year_valuation(years_elapsed)
      end
    end

    private

    def calculate_first_year_valuation
      rate = depreciation_rate
      acquisition_cost = @fixed_asset.acquisition_cost

      # 初年度は半年分の減価
      valuation = acquisition_cost * (1 - rate * 0.5)

      # 最低限度額チェック
      min_valuation = acquisition_cost * MINIMUM_RATE
      final_valuation = [ valuation, min_valuation ].max

      {
        success: true,
        years_elapsed: 0,
        valuation: final_valuation.round,
        depreciation_rate: rate,
        is_minimum: final_valuation <= min_valuation
      }
    end

    def calculate_subsequent_year_valuation(years_elapsed)
      # 前年度の評価額を取得
      previous_valuation = get_previous_valuation

      unless previous_valuation
        # 前年度の評価額がない場合は、遡って計算
        previous_valuation = calculate_valuation_retroactively(years_elapsed - 1)
      end

      rate = depreciation_rate
      acquisition_cost = @fixed_asset.acquisition_cost

      # 当年度の評価額 = 前年度評価額 × (1 - 減価率)
      valuation = previous_valuation * (1 - rate)

      # 最低限度額チェック
      min_valuation = acquisition_cost * MINIMUM_RATE
      final_valuation = [ valuation, min_valuation ].max

      {
        success: true,
        years_elapsed: years_elapsed,
        valuation: final_valuation.round,
        previous_valuation: previous_valuation.round,
        depreciation_rate: rate,
        is_minimum: final_valuation <= min_valuation
      }
    end

    # 前年度の評価額を取得（asset_valuationsテーブルから）
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

    # 評価額を遡って計算（前年度のデータがない場合）
    def calculate_valuation_retroactively(target_years_elapsed)
      acquisition_cost = @fixed_asset.acquisition_cost
      rate = depreciation_rate

      # 初年度の評価額
      valuation = acquisition_cost * (1 - rate * 0.5)

      # 2年目以降を計算
      (target_years_elapsed).times do
        valuation = valuation * (1 - rate)

        # 最低限度額チェック
        min_valuation = acquisition_cost * MINIMUM_RATE
        valuation = [ valuation, min_valuation ].max

        # 最低限度額に達したら計算終了
        break if valuation <= min_valuation
      end

      valuation
    end

    # 固定資産税評価用の減価率を取得
    def depreciation_rate
      # depreciation_policyから耐用年数を取得
      useful_life = @fixed_asset.depreciation_policy&.useful_life_years

      # 耐用年数が設定されていない場合は、デフォルト値を使用
      useful_life ||= estimate_useful_life

      # テーブルに存在する場合はそれを使用
      return DEPRECIATION_RATES[useful_life] if DEPRECIATION_RATES[useful_life]

      # テーブルにない場合は、近い値を補間
      interpolate_depreciation_rate(useful_life)
    end

    # 耐用年数を推定
    def estimate_useful_life
      # depreciation_policyがない場合のデフォルト耐用年数
      # 実際には資産の種類に応じて適切な耐用年数を設定する必要がある
      10 # デフォルト: 10年
    end

    # 減価率を補間
    def interpolate_depreciation_rate(useful_life)
      # テーブルから最も近い2つの値を見つけて線形補間
      sorted_lives = DEPRECIATION_RATES.keys.sort
      lower = sorted_lives.select { |l| l <= useful_life }.last
      upper = sorted_lives.select { |l| l >= useful_life }.first

      return DEPRECIATION_RATES[useful_life] if lower == upper

      if lower.nil?
        return DEPRECIATION_RATES[upper]
      elsif upper.nil?
        return DEPRECIATION_RATES[lower]
      end

      # 線形補間
      rate_lower = DEPRECIATION_RATES[lower]
      rate_upper = DEPRECIATION_RATES[upper]

      ratio = (useful_life - lower).to_f / (upper - lower)
      rate_lower + (rate_upper - rate_lower) * ratio
    end

    def failure(message)
      { success: false, error: message }
    end
  end
end
