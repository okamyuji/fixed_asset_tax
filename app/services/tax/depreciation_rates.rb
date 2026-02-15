module Tax
  # 国税庁公式「減価償却資産の償却率等表」に基づく全償却率テーブル
  # 出典: 国税庁 034.pdf/037.pdf 5ページ目 (令和5年分)
  # 固定資産税（旧定率法）は東京都主税局「償却資産 申告の手引き」減価残存率表と一致
  module DepreciationRates
    # ========================================================================
    # Table 1: 定額法の償却率等表
    # ========================================================================

    # 旧定額法の償却率（平成19年3月31日以前取得）
    # 償却基礎額 = 取得価額 × 90%（残存割合10%）
    # 年間償却額 = 償却基礎額 × 旧定額法償却率
    OLD_STRAIGHT_LINE_RATES = {
      2 => 0.500, 3 => 0.333, 4 => 0.250, 5 => 0.200,
      6 => 0.166, 7 => 0.142, 8 => 0.125, 9 => 0.111, 10 => 0.100,
      11 => 0.090, 12 => 0.083, 13 => 0.076, 14 => 0.071, 15 => 0.066,
      16 => 0.062, 17 => 0.058, 18 => 0.055, 19 => 0.052, 20 => 0.050,
      21 => 0.048, 22 => 0.046, 23 => 0.044, 24 => 0.042, 25 => 0.040,
      26 => 0.039, 27 => 0.037, 28 => 0.036, 29 => 0.035, 30 => 0.034,
      31 => 0.033, 32 => 0.032, 33 => 0.031, 34 => 0.030, 35 => 0.029,
      36 => 0.028, 37 => 0.027, 38 => 0.027, 39 => 0.026, 40 => 0.025,
      41 => 0.025, 42 => 0.024, 43 => 0.024, 44 => 0.023, 45 => 0.023,
      46 => 0.022, 47 => 0.022, 48 => 0.021, 49 => 0.021, 50 => 0.020
    }.freeze

    # 定額法の償却率（平成19年4月1日以後取得）
    # 年間償却額 = 取得価額 × 定額法償却率（残存価額なし、最終1円まで償却）
    STRAIGHT_LINE_RATES = {
      2 => 0.500, 3 => 0.334, 4 => 0.250, 5 => 0.200,
      6 => 0.167, 7 => 0.143, 8 => 0.125, 9 => 0.112, 10 => 0.100,
      11 => 0.091, 12 => 0.084, 13 => 0.077, 14 => 0.072, 15 => 0.067,
      16 => 0.063, 17 => 0.059, 18 => 0.056, 19 => 0.053, 20 => 0.050,
      21 => 0.048, 22 => 0.046, 23 => 0.044, 24 => 0.042, 25 => 0.040,
      26 => 0.039, 27 => 0.038, 28 => 0.036, 29 => 0.035, 30 => 0.034,
      31 => 0.033, 32 => 0.032, 33 => 0.031, 34 => 0.030, 35 => 0.029,
      36 => 0.028, 37 => 0.028, 38 => 0.027, 39 => 0.026, 40 => 0.025,
      41 => 0.025, 42 => 0.024, 43 => 0.024, 44 => 0.023, 45 => 0.023,
      46 => 0.022, 47 => 0.022, 48 => 0.021, 49 => 0.021, 50 => 0.020
    }.freeze

    # ========================================================================
    # Table 2: 旧定率法、定率法の償却率等表
    # ========================================================================

    # 旧定率法の償却率（平成19年3月31日以前取得）
    # 固定資産税（償却資産）の減価率としても使用
    # 年間償却額 = 未償却残高 × 旧定率法償却率
    OLD_DECLINING_BALANCE_RATES = {
      2 => 0.684, 3 => 0.536, 4 => 0.438, 5 => 0.369,
      6 => 0.319, 7 => 0.280, 8 => 0.250, 9 => 0.226, 10 => 0.206,
      11 => 0.189, 12 => 0.175, 13 => 0.162, 14 => 0.152, 15 => 0.142,
      16 => 0.134, 17 => 0.127, 18 => 0.120, 19 => 0.114, 20 => 0.109,
      21 => 0.104, 22 => 0.099, 23 => 0.095, 24 => 0.092, 25 => 0.088,
      26 => 0.085, 27 => 0.082, 28 => 0.079, 29 => 0.076, 30 => 0.074,
      31 => 0.072, 32 => 0.069, 33 => 0.067, 34 => 0.066, 35 => 0.064,
      36 => 0.062, 37 => 0.060, 38 => 0.059, 39 => 0.057, 40 => 0.056,
      41 => 0.055, 42 => 0.053, 43 => 0.052, 44 => 0.051, 45 => 0.050,
      46 => 0.049, 47 => 0.048, 48 => 0.047, 49 => 0.046, 50 => 0.045,
      # 以下は東京都主税局「償却資産 申告の手引き」減価残存率表より（耐用年数51-75年）
      51 => 0.044, 52 => 0.043
    }.freeze

    # 250%定率法（平成19年4月1日〜平成24年3月31日取得）
    # 各耐用年数について {rate: 償却率, revised_rate: 改定償却率, guarantee_rate: 保証率}
    DECLINING_BALANCE_250_RATES = {
      2 => { rate: 1.000, revised_rate: nil, guarantee_rate: nil },
      3 => { rate: 0.833, revised_rate: 1.000, guarantee_rate: 0.02789 },
      4 => { rate: 0.625, revised_rate: 1.000, guarantee_rate: 0.05274 },
      5 => { rate: 0.500, revised_rate: 1.000, guarantee_rate: 0.06249 },
      6 => { rate: 0.417, revised_rate: 0.500, guarantee_rate: 0.05776 },
      7 => { rate: 0.357, revised_rate: 0.500, guarantee_rate: 0.05496 },
      8 => { rate: 0.313, revised_rate: 0.334, guarantee_rate: 0.05111 },
      9 => { rate: 0.278, revised_rate: 0.334, guarantee_rate: 0.04731 },
      10 => { rate: 0.250, revised_rate: 0.334, guarantee_rate: 0.04448 },
      11 => { rate: 0.227, revised_rate: 0.250, guarantee_rate: 0.04123 },
      12 => { rate: 0.208, revised_rate: 0.250, guarantee_rate: 0.03870 },
      13 => { rate: 0.192, revised_rate: 0.200, guarantee_rate: 0.03633 },
      14 => { rate: 0.179, revised_rate: 0.200, guarantee_rate: 0.03389 },
      15 => { rate: 0.167, revised_rate: 0.200, guarantee_rate: 0.03217 },
      16 => { rate: 0.156, revised_rate: 0.167, guarantee_rate: 0.03063 },
      17 => { rate: 0.147, revised_rate: 0.167, guarantee_rate: 0.02905 },
      18 => { rate: 0.139, revised_rate: 0.143, guarantee_rate: 0.02757 },
      19 => { rate: 0.132, revised_rate: 0.143, guarantee_rate: 0.02616 },
      20 => { rate: 0.125, revised_rate: 0.143, guarantee_rate: 0.02517 },
      21 => { rate: 0.119, revised_rate: 0.125, guarantee_rate: 0.02408 },
      22 => { rate: 0.114, revised_rate: 0.125, guarantee_rate: 0.02296 },
      23 => { rate: 0.109, revised_rate: 0.112, guarantee_rate: 0.02226 },
      24 => { rate: 0.104, revised_rate: 0.112, guarantee_rate: 0.02157 },
      25 => { rate: 0.100, revised_rate: 0.112, guarantee_rate: 0.02058 },
      26 => { rate: 0.096, revised_rate: 0.100, guarantee_rate: 0.01989 },
      27 => { rate: 0.093, revised_rate: 0.100, guarantee_rate: 0.01902 },
      28 => { rate: 0.089, revised_rate: 0.091, guarantee_rate: 0.01866 },
      29 => { rate: 0.086, revised_rate: 0.091, guarantee_rate: 0.01803 },
      30 => { rate: 0.083, revised_rate: 0.084, guarantee_rate: 0.01766 },
      31 => { rate: 0.081, revised_rate: 0.084, guarantee_rate: 0.01688 },
      32 => { rate: 0.078, revised_rate: 0.084, guarantee_rate: 0.01655 },
      33 => { rate: 0.076, revised_rate: 0.077, guarantee_rate: 0.01585 },
      34 => { rate: 0.074, revised_rate: 0.077, guarantee_rate: 0.01532 },
      35 => { rate: 0.071, revised_rate: 0.072, guarantee_rate: 0.01532 },
      36 => { rate: 0.069, revised_rate: 0.072, guarantee_rate: 0.01494 },
      37 => { rate: 0.068, revised_rate: 0.072, guarantee_rate: 0.01425 },
      38 => { rate: 0.066, revised_rate: 0.067, guarantee_rate: 0.01393 },
      39 => { rate: 0.064, revised_rate: 0.067, guarantee_rate: 0.01370 },
      40 => { rate: 0.063, revised_rate: 0.067, guarantee_rate: 0.01317 },
      41 => { rate: 0.061, revised_rate: 0.063, guarantee_rate: 0.01306 },
      42 => { rate: 0.060, revised_rate: 0.063, guarantee_rate: 0.01261 },
      43 => { rate: 0.058, revised_rate: 0.059, guarantee_rate: 0.01248 },
      44 => { rate: 0.057, revised_rate: 0.059, guarantee_rate: 0.01210 },
      45 => { rate: 0.056, revised_rate: 0.059, guarantee_rate: 0.01175 },
      46 => { rate: 0.054, revised_rate: 0.056, guarantee_rate: 0.01175 },
      47 => { rate: 0.053, revised_rate: 0.056, guarantee_rate: 0.01153 },
      48 => { rate: 0.052, revised_rate: 0.053, guarantee_rate: 0.01126 },
      49 => { rate: 0.051, revised_rate: 0.053, guarantee_rate: 0.01102 },
      50 => { rate: 0.050, revised_rate: 0.053, guarantee_rate: 0.01072 }
    }.freeze

    # 200%定率法（平成24年4月1日以後取得）
    # 各耐用年数について {rate: 償却率, revised_rate: 改定償却率, guarantee_rate: 保証率}
    DECLINING_BALANCE_200_RATES = {
      2 => { rate: 1.000, revised_rate: nil, guarantee_rate: nil },
      3 => { rate: 0.667, revised_rate: 1.000, guarantee_rate: 0.11089 },
      4 => { rate: 0.500, revised_rate: 1.000, guarantee_rate: 0.12499 },
      5 => { rate: 0.400, revised_rate: 0.500, guarantee_rate: 0.10800 },
      6 => { rate: 0.333, revised_rate: 0.334, guarantee_rate: 0.09911 },
      7 => { rate: 0.286, revised_rate: 0.334, guarantee_rate: 0.08680 },
      8 => { rate: 0.250, revised_rate: 0.334, guarantee_rate: 0.07909 },
      9 => { rate: 0.222, revised_rate: 0.250, guarantee_rate: 0.07126 },
      10 => { rate: 0.200, revised_rate: 0.250, guarantee_rate: 0.06552 },
      11 => { rate: 0.182, revised_rate: 0.200, guarantee_rate: 0.05992 },
      12 => { rate: 0.167, revised_rate: 0.200, guarantee_rate: 0.05566 },
      13 => { rate: 0.154, revised_rate: 0.167, guarantee_rate: 0.05180 },
      14 => { rate: 0.143, revised_rate: 0.167, guarantee_rate: 0.04854 },
      15 => { rate: 0.133, revised_rate: 0.143, guarantee_rate: 0.04565 },
      16 => { rate: 0.125, revised_rate: 0.143, guarantee_rate: 0.04294 },
      17 => { rate: 0.118, revised_rate: 0.125, guarantee_rate: 0.04038 },
      18 => { rate: 0.111, revised_rate: 0.112, guarantee_rate: 0.03884 },
      19 => { rate: 0.105, revised_rate: 0.112, guarantee_rate: 0.03693 },
      20 => { rate: 0.100, revised_rate: 0.112, guarantee_rate: 0.03486 },
      21 => { rate: 0.095, revised_rate: 0.100, guarantee_rate: 0.03335 },
      22 => { rate: 0.091, revised_rate: 0.100, guarantee_rate: 0.03182 },
      23 => { rate: 0.087, revised_rate: 0.091, guarantee_rate: 0.03052 },
      24 => { rate: 0.083, revised_rate: 0.084, guarantee_rate: 0.02969 },
      25 => { rate: 0.080, revised_rate: 0.084, guarantee_rate: 0.02841 },
      26 => { rate: 0.077, revised_rate: 0.084, guarantee_rate: 0.02716 },
      27 => { rate: 0.074, revised_rate: 0.077, guarantee_rate: 0.02624 },
      28 => { rate: 0.071, revised_rate: 0.072, guarantee_rate: 0.02568 },
      29 => { rate: 0.069, revised_rate: 0.072, guarantee_rate: 0.02463 },
      30 => { rate: 0.067, revised_rate: 0.072, guarantee_rate: 0.02366 },
      31 => { rate: 0.065, revised_rate: 0.067, guarantee_rate: 0.02286 },
      32 => { rate: 0.063, revised_rate: 0.067, guarantee_rate: 0.02216 },
      33 => { rate: 0.061, revised_rate: 0.063, guarantee_rate: 0.02161 },
      34 => { rate: 0.059, revised_rate: 0.063, guarantee_rate: 0.02097 },
      35 => { rate: 0.057, revised_rate: 0.059, guarantee_rate: 0.02051 },
      36 => { rate: 0.056, revised_rate: 0.059, guarantee_rate: 0.01974 },
      37 => { rate: 0.054, revised_rate: 0.056, guarantee_rate: 0.01950 },
      38 => { rate: 0.053, revised_rate: 0.056, guarantee_rate: 0.01882 },
      39 => { rate: 0.051, revised_rate: 0.053, guarantee_rate: 0.01860 },
      40 => { rate: 0.050, revised_rate: 0.053, guarantee_rate: 0.01791 },
      41 => { rate: 0.049, revised_rate: 0.050, guarantee_rate: 0.01741 },
      42 => { rate: 0.048, revised_rate: 0.050, guarantee_rate: 0.01694 },
      43 => { rate: 0.047, revised_rate: 0.048, guarantee_rate: 0.01664 },
      44 => { rate: 0.045, revised_rate: 0.046, guarantee_rate: 0.01664 },
      45 => { rate: 0.044, revised_rate: 0.046, guarantee_rate: 0.01634 },
      46 => { rate: 0.043, revised_rate: 0.044, guarantee_rate: 0.01601 },
      47 => { rate: 0.043, revised_rate: 0.044, guarantee_rate: 0.01532 },
      48 => { rate: 0.042, revised_rate: 0.044, guarantee_rate: 0.01499 },
      49 => { rate: 0.041, revised_rate: 0.042, guarantee_rate: 0.01475 },
      50 => { rate: 0.040, revised_rate: 0.042, guarantee_rate: 0.01440 }
    }.freeze

    # ========================================================================
    # 取得時期による償却方法の自動判定
    # ========================================================================

    # 平成19年3月31日 = 2007年3月31日
    BOUNDARY_H19 = Date.new(2007, 3, 31).freeze
    # 平成24年3月31日 = 2012年3月31日
    BOUNDARY_H24 = Date.new(2012, 3, 31).freeze

    # 取得時期と償却方式タイプに基づく推奨償却方法を返す
    # @param acquired_on [Date] 取得日
    # @param method_type [Symbol] :straight_line または :declining_balance
    # @return [String] 償却方法名
    def self.recommended_method(acquired_on:, method_type:)
      case method_type
      when :straight_line
        acquired_on <= BOUNDARY_H19 ? "old_straight_line" : "straight_line"
      when :declining_balance
        if acquired_on <= BOUNDARY_H19
          "old_declining_balance"
        elsif acquired_on <= BOUNDARY_H24
          "declining_balance_250"
        else
          "declining_balance_200"
        end
      else
        raise ArgumentError, "Unknown method_type: #{method_type}"
      end
    end

    # 指定された償却方法と耐用年数に対応する償却率を取得
    # @param method [String] 償却方法名
    # @param useful_life [Integer] 耐用年数
    # @return [Float, Hash, nil] 償却率（定率法の場合は{rate:, revised_rate:, guarantee_rate:}）
    def self.rate_for(method:, useful_life:)
      case method
      when "old_straight_line"
        OLD_STRAIGHT_LINE_RATES[useful_life]
      when "straight_line"
        STRAIGHT_LINE_RATES[useful_life]
      when "old_declining_balance"
        OLD_DECLINING_BALANCE_RATES[useful_life]
      when "declining_balance_250"
        DECLINING_BALANCE_250_RATES[useful_life]
      when "declining_balance_200"
        DECLINING_BALANCE_200_RATES[useful_life]
      end
    end
  end
end
