module Tax
  class DepreciationCalculator
    # 200%定率法の保証率テーブル（耐用年数別）
    GUARANTEE_RATES = {
      2 => 0.50847,
      3 => 0.34776,
      4 => 0.26505,
      5 => 0.21600,
      6 => 0.18327,
      7 => 0.15909,
      8 => 0.14065,
      9 => 0.12577,
      10 => 0.11430,
      15 => 0.07909,
      20 => 0.06141
    }.freeze

    # 200%定率法の改定償却率テーブル（耐用年数別）
    REVISED_RATES = {
      2 => 0.500,
      3 => 0.334,
      4 => 0.250,
      5 => 0.200,
      6 => 0.167,
      7 => 0.143,
      8 => 0.125,
      9 => 0.112,
      10 => 0.100,
      15 => 0.067,
      20 => 0.050
    }.freeze

    def initialize(fixed_asset:, fiscal_year:)
      @fixed_asset = fixed_asset
      @fiscal_year = fiscal_year
      @policy = fixed_asset.depreciation_policy
    end

    def call
      return failure("Depreciation policy not found") unless @policy

      previous_year = find_previous_depreciation_year
      opening_value = previous_year&.closing_book_value || @fixed_asset.acquisition_cost

      # 既に残存価額以下の場合は償却なし
      min_value = @fixed_asset.acquisition_cost * @policy.residual_rate
      if opening_value <= min_value
        return {
          success: true,
          opening_book_value: opening_value,
          depreciation_amount: 0,
          closing_book_value: opening_value
        }
      end

      depreciation_amount = calculate_depreciation(opening_value, previous_year)

      # 残存価額を下回らないように調整
      closing_value = [opening_value - depreciation_amount, min_value].max

      # 調整後の実際の償却額
      actual_depreciation = opening_value - closing_value

      {
        success: true,
        opening_book_value: opening_value,
        depreciation_amount: actual_depreciation,
        closing_book_value: closing_value
      }
    end

    private

    def find_previous_depreciation_year
      return nil unless @fiscal_year

      previous_fiscal_year = FiscalYear.where("year < ?", @fiscal_year.year).order(year: :desc).first
      return nil unless previous_fiscal_year

      @fixed_asset.depreciation_years.find_by(fiscal_year: previous_fiscal_year)
    end

    def calculate_depreciation(opening_value, previous_year)
      case @policy.method
      when "straight_line"
        calculate_straight_line(opening_value)
      when "declining_balance"
        calculate_declining_balance(opening_value, previous_year)
      else
        0
      end
    end

    def calculate_straight_line(opening_value)
      # 償却可能額
      depreciable_amount = @fixed_asset.acquisition_cost * (1 - @policy.residual_rate)

      # 年間償却額
      annual_depreciation = depreciable_amount / @policy.useful_life_years

      # 残存価額を下回らないように調整
      min_value = @fixed_asset.acquisition_cost * @policy.residual_rate
      max_depreciation = opening_value - min_value

      # 既に残存価額以下の場合、または max_depreciation が負の場合は償却なし
      return 0 if max_depreciation <= 0

      [annual_depreciation, max_depreciation].min
    end

    def calculate_declining_balance(opening_value, previous_year)
      # 定額法の償却率
      straight_line_rate = 1.0 / @policy.useful_life_years

      # 200%定率法の償却率（定額法の2倍）
      declining_rate = straight_line_rate * 2.0

      # 当期償却額（通常償却）
      depreciation = opening_value * declining_rate

      # 残存価額を下回らないように調整（最優先）
      min_value = @fixed_asset.acquisition_cost * @policy.residual_rate
      max_depreciation = opening_value - min_value

      # 既に残存価額以下の場合は償却なし
      return 0 if max_depreciation <= 0

      # 通常償却額を残存価額制限内に収める
      normal_depreciation_limited = [depreciation, max_depreciation].min

      # 償却保証額（取得価額 × 保証率）
      guarantee_amount = @fixed_asset.acquisition_cost * guarantee_rate

      # 償却保証額を下回る場合は改定償却率を使用
      # ただし、残存価額制限がかかっている場合は通常償却額を優先
      if depreciation < guarantee_amount
        # 改定取得価額 = 通常償却額が保証額を下回った最初の年の期首帳簿価額
        revised_acquisition = find_revised_acquisition_value(opening_value, previous_year)
        revised_depreciation = revised_acquisition * revised_depreciation_rate

        # 改定償却額も残存価額制限を適用
        revised_depreciation_limited = [revised_depreciation, max_depreciation].min

        # 残存価額制限後の通常償却額と改定償却額を比較
        # 残存価額制限がかかっている場合（通常償却額が制限された場合）は、通常償却額を優先
        if normal_depreciation_limited < depreciation
          # 残存価額制限がかかっている → 通常償却額を使用
          return normal_depreciation_limited
        else
          # 残存価額制限がかかっていない → 改定償却額を使用
          return revised_depreciation_limited
        end
      end

      # 保証額を上回っている場合は通常償却（残存価額制限適用済み）
      normal_depreciation_limited
    end

    # 保証率を取得（耐用年数に応じた値）
    def guarantee_rate
      years = @policy.useful_life_years

      # テーブルに存在する場合はそれを使用
      return GUARANTEE_RATES[years] if GUARANTEE_RATES[years]

      # テーブルにない場合は、定額法償却率 × 保証率係数で計算
      # 200%定率法の保証率係数は約0.11430（耐用年数10年の値を基準）
      straight_line_rate = 1.0 / years
      straight_line_rate * 0.11430
    end

    # 改定償却率を取得
    def revised_depreciation_rate
      years = @policy.useful_life_years

      # テーブルに存在する場合はそれを使用
      return REVISED_RATES[years] if REVISED_RATES[years]

      # テーブルにない場合は、定額法償却率を使用
      1.0 / years
    end

    # 改定取得価額を取得
    # 通常償却額が償却保証額を下回った最初の年の期首帳簿価額を返す
    def find_revised_acquisition_value(current_opening_value, previous_year)
      guarantee_amount = @fixed_asset.acquisition_cost * guarantee_rate
      straight_line_rate = 1.0 / @policy.useful_life_years
      declining_rate = straight_line_rate * 2.0

      # 今年度の通常償却額が保証額を下回っているかチェック
      current_normal_depreciation = current_opening_value * declining_rate

      # 前年度がない場合、または前年度の通常償却額が保証額以上の場合
      # 今年度が最初に保証額を下回った年 → 今年度の期首を返す
      unless previous_year
        return current_opening_value
      end

      # 前年度の通常償却額を計算
      previous_normal_depreciation = previous_year.opening_book_value * declining_rate

      # 前年度の通常償却額が保証額以上の場合、今年度が最初の年
      if previous_normal_depreciation >= guarantee_amount
        return current_opening_value
      end

      # 前年度の通常償却額が保証額を下回っている場合、
      # さらに遡って最初に保証額を下回った年を探す
      all_years = @fixed_asset.depreciation_years
        .joins(:fiscal_year)
        .where("fiscal_years.year < ?", @fiscal_year.year)
        .order("fiscal_years.year ASC")

      # 最初に保証額を下回った年を探す
      first_switch_year = nil
      all_years.each do |year|
        normal_depreciation = year.opening_book_value * declining_rate
        if normal_depreciation < guarantee_amount
          first_switch_year = year
          break
        end
      end

      # 最初に保証額を下回った年が見つかった場合、その期首を返す
      # 見つからない場合は今年度の期首を返す
      first_switch_year&.opening_book_value || current_opening_value
    end

    def failure(message)
      { success: false, error: message }
    end
  end
end
