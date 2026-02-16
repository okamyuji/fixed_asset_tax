module Tax
  class DepreciationCalculator
    def initialize(fixed_asset:, fiscal_year:)
      @fixed_asset = fixed_asset
      @fiscal_year = fiscal_year
      @policy = fixed_asset.depreciation_policy
    end

    def call
      return failure("Depreciation policy not found") unless @policy

      case @policy.depreciation_type
      when "immediate"
        calculate_immediate_depreciation
      when "lump_sum"
        calculate_lump_sum_depreciation
      when "small_value"
        calculate_small_value_depreciation
      when "special"
        calculate_special_depreciation
      when "accelerated"
        calculate_accelerated_depreciation
      else
        calculate_normal_depreciation
      end
    end

    private

    # ========== 通常償却 ==========

    def calculate_normal_depreciation
      previous_year = find_previous_depreciation_year
      cost = acquisition_cost_for_calculation
      opening_value = previous_year&.closing_book_value || cost

      if opening_value <= 1
        return success_result(opening_value, 0, opening_value)
      end

      depreciation_amount = calculate_by_method(opening_value, previous_year)

      closing_value = [opening_value - depreciation_amount, 1].max
      actual_depreciation = opening_value - closing_value

      success_result(opening_value, actual_depreciation, closing_value)
    end

    def calculate_by_method(opening_value, previous_year)
      case @policy.method
      when "old_straight_line"
        calculate_old_straight_line(opening_value)
      when "old_declining_balance"
        calculate_old_declining_balance(opening_value)
      when "straight_line"
        calculate_straight_line(opening_value)
      when "declining_balance_250"
        calculate_declining_balance(opening_value, previous_year, DepreciationRates::DECLINING_BALANCE_250_RATES)
      when "declining_balance_200"
        calculate_declining_balance(opening_value, previous_year, DepreciationRates::DECLINING_BALANCE_200_RATES)
      else
        0
      end
    end

    # --- 旧定額法 ---
    # 償却基礎額 = 取得価額 × 90%
    # 年間償却額 = 償却基礎額 × 旧定額法償却率
    # 累計95%到達後（簿価5%）→ 均等償却: (取得価額×5% - 1) / 5.0
    # 最終簿価: 1円（備忘価額）
    def calculate_old_straight_line(opening_value)
      cost = acquisition_cost_for_calculation
      rate = DepreciationRates.rate_for(method: "old_straight_line", useful_life: @policy.useful_life_years)
      return 0 unless rate

      threshold_5pct = cost * 0.05

      if opening_value > threshold_5pct
        depreciable_base = cost * 0.9
        annual = depreciable_base * rate
        [annual, opening_value - threshold_5pct].min
      else
        equal_amount = (threshold_5pct - 1) / 5.0
        [equal_amount, opening_value - 1].min
      end
    end

    # --- 旧定率法 ---
    # 年間償却額 = 期首未償却残高 × 旧定率法償却率
    # 累計95%到達後（簿価5%）→ 均等償却（旧定額法と同じ）
    # 最終簿価: 1円
    def calculate_old_declining_balance(opening_value)
      cost = acquisition_cost_for_calculation
      rate = DepreciationRates.rate_for(method: "old_declining_balance", useful_life: @policy.useful_life_years)
      return 0 unless rate

      threshold_5pct = cost * 0.05

      if opening_value > threshold_5pct
        annual = opening_value * rate
        [annual, opening_value - threshold_5pct].min
      else
        equal_amount = (threshold_5pct - 1) / 5.0
        [equal_amount, opening_value - 1].min
      end
    end

    # --- 定額法（新） ---
    # 年間償却額 = 取得価額 × 定額法償却率
    # 残存価額概念なし、最終1円まで償却
    def calculate_straight_line(opening_value)
      cost = acquisition_cost_for_calculation
      rate = DepreciationRates.rate_for(method: "straight_line", useful_life: @policy.useful_life_years)
      return 0 unless rate

      annual = cost * rate
      [annual, opening_value - 1].min
    end

    # --- 定率法 (250%/200% 共通) ---
    # 通常償却 = 期首帳簿価額 × rate
    # 償却保証額 = 取得価額 × guarantee_rate
    # 通常償却 < 償却保証額 → 改定償却率に切り替え
    # 改定取得価額 = 通常償却が保証額を下回った最初の年の期首簿価
    # 最終簿価: 1円
    def calculate_declining_balance(opening_value, previous_year, rate_table)
      rates = rate_table[@policy.useful_life_years]
      return 0 unless rates

      rate = rates[:rate]
      guarantee_rate = rates[:guarantee_rate]
      revised_rate = rates[:revised_rate]

      cost = acquisition_cost_for_calculation
      normal_depreciation = opening_value * rate

      # 耐用年数2年は保証率なし（rate=1.000）
      return [normal_depreciation, opening_value - 1].min unless guarantee_rate

      guarantee_amount = cost * guarantee_rate

      if normal_depreciation >= guarantee_amount
        [normal_depreciation, opening_value - 1].min
      else
        revised_acquisition = find_revised_acquisition_value(opening_value, previous_year, rate, guarantee_amount)
        revised_depreciation = revised_acquisition * revised_rate
        [revised_depreciation, opening_value - 1].min
      end
    end

    # 改定取得価額を探索
    # 通常償却額が償却保証額を下回った最初の年の期首帳簿価額を返す
    def find_revised_acquisition_value(current_opening_value, previous_year, rate, guarantee_amount)
      return current_opening_value unless previous_year

      # 前年度の通常償却額が保証額以上の場合、今年度が最初の年
      previous_normal = previous_year.opening_book_value * rate
      return current_opening_value if previous_normal >= guarantee_amount

      # 前年度も保証額を下回っている場合、さらに遡って最初に下回った年を探す
      all_years = @fixed_asset.depreciation_years
        .joins(:fiscal_year)
        .where("fiscal_years.year < ?", @fiscal_year.year)
        .order("fiscal_years.year ASC")

      all_years.each do |year|
        if year.opening_book_value * rate < guarantee_amount
          return year.opening_book_value
        end
      end

      current_opening_value
    end

    # ========== 特殊償却タイプ（既存ロジック維持） ==========

    # 即時償却（10万円未満、全額償却）
    def calculate_immediate_depreciation
      cost = acquisition_cost_for_calculation
      success_result(cost, cost, 0)
    end

    # 一括償却資産（3年均等償却、10万円以上20万円未満）
    def calculate_lump_sum_depreciation
      cost = acquisition_cost_for_calculation
      annual_depreciation = cost / 3.0

      previous_year = find_previous_depreciation_year
      opening_value = previous_year&.closing_book_value || cost

      # 3年経過したら償却完了
      years_elapsed = count_depreciation_years
      if years_elapsed >= 3
        return success_result(opening_value, 0, opening_value)
      end

      depreciation_amount = [annual_depreciation, opening_value].min
      closing_value = opening_value - depreciation_amount

      success_result(opening_value, depreciation_amount, closing_value)
    end

    # 少額減価償却資産（青色申告者の特例、10万円以上30万円未満）
    def calculate_small_value_depreciation
      cost = acquisition_cost_for_calculation

      # 初年度に全額償却
      previous_year = find_previous_depreciation_year
      if previous_year
        return success_result(0, 0, 0)
      end

      success_result(cost, cost, 0)
    end

    # 特別償却（法人向け）: 通常償却 + 特別償却
    def calculate_special_depreciation
      normal_result = calculate_normal_depreciation
      return normal_result unless normal_result[:success]

      special_amount = if @policy.special_depreciation_rate
        acquisition_cost_for_calculation * @policy.special_depreciation_rate
      else
        0
      end

      total_depreciation = normal_result[:depreciation_amount] + special_amount
      closing_value = [normal_result[:opening_book_value] - total_depreciation, 0].max

      {
        success: true,
        opening_book_value: normal_result[:opening_book_value],
        depreciation_amount: total_depreciation,
        closing_book_value: closing_value,
        normal_depreciation: normal_result[:depreciation_amount],
        special_depreciation: special_amount
      }
    end

    # 割増償却（法人向け）: 通常償却 × (1 + 割増率)
    def calculate_accelerated_depreciation
      normal_result = calculate_normal_depreciation
      return normal_result unless normal_result[:success]

      accelerated_rate = @policy.special_depreciation_rate || 0
      accelerated_amount = normal_result[:depreciation_amount] * (1 + accelerated_rate)

      closing_value = [normal_result[:opening_book_value] - accelerated_amount, 0].max

      success_result(normal_result[:opening_book_value], accelerated_amount, closing_value)
    end

    # ========== ヘルパー ==========

    # 事業利用割合を考慮した取得価額
    def acquisition_cost_for_calculation
      @fixed_asset.business_acquisition_cost
    end

    # 償却年数をカウント
    def count_depreciation_years
      @fixed_asset.depreciation_years.count
    end

    def find_previous_depreciation_year
      return nil unless @fiscal_year

      previous_fiscal_year = FiscalYear.where("year < ?", @fiscal_year.year).order(year: :desc).first
      return nil unless previous_fiscal_year

      @fixed_asset.depreciation_years.find_by(fiscal_year: previous_fiscal_year)
    end

    def success_result(opening_value, depreciation_amount, closing_value)
      {
        success: true,
        opening_book_value: opening_value,
        depreciation_amount: depreciation_amount,
        closing_book_value: closing_value
      }
    end

    def failure(message)
      { success: false, error: message }
    end
  end
end
