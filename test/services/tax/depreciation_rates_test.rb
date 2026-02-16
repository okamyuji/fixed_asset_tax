require "test_helper"

module Tax
  class DepreciationRatesTest < ActiveSupport::TestCase
    # ========================================================================
    # 旧定額法の償却率検証（NTA Table 1 左側）
    # ========================================================================
    test "旧定額法: 代表的な耐用年数の償却率がNTAテーブルと一致" do
      assert_equal 0.500, DepreciationRates::OLD_STRAIGHT_LINE_RATES[2]
      assert_equal 0.333, DepreciationRates::OLD_STRAIGHT_LINE_RATES[3]
      assert_equal 0.250, DepreciationRates::OLD_STRAIGHT_LINE_RATES[4]
      assert_equal 0.200, DepreciationRates::OLD_STRAIGHT_LINE_RATES[5]
      assert_equal 0.100, DepreciationRates::OLD_STRAIGHT_LINE_RATES[10]
      assert_equal 0.066, DepreciationRates::OLD_STRAIGHT_LINE_RATES[15]
      assert_equal 0.050, DepreciationRates::OLD_STRAIGHT_LINE_RATES[20]
      assert_equal 0.040, DepreciationRates::OLD_STRAIGHT_LINE_RATES[25]
      assert_equal 0.034, DepreciationRates::OLD_STRAIGHT_LINE_RATES[30]
      assert_equal 0.025, DepreciationRates::OLD_STRAIGHT_LINE_RATES[40]
      assert_equal 0.020, DepreciationRates::OLD_STRAIGHT_LINE_RATES[50]
    end

    # ========================================================================
    # 定額法の償却率検証（NTA Table 1 右側）
    # ========================================================================
    test "定額法: 代表的な耐用年数の償却率がNTAテーブルと一致" do
      assert_equal 0.500, DepreciationRates::STRAIGHT_LINE_RATES[2]
      assert_equal 0.334, DepreciationRates::STRAIGHT_LINE_RATES[3]
      assert_equal 0.250, DepreciationRates::STRAIGHT_LINE_RATES[4]
      assert_equal 0.200, DepreciationRates::STRAIGHT_LINE_RATES[5]
      assert_equal 0.100, DepreciationRates::STRAIGHT_LINE_RATES[10]
      assert_equal 0.067, DepreciationRates::STRAIGHT_LINE_RATES[15]
      assert_equal 0.050, DepreciationRates::STRAIGHT_LINE_RATES[20]
      assert_equal 0.040, DepreciationRates::STRAIGHT_LINE_RATES[25]
      assert_equal 0.034, DepreciationRates::STRAIGHT_LINE_RATES[30]
      assert_equal 0.025, DepreciationRates::STRAIGHT_LINE_RATES[40]
      assert_equal 0.020, DepreciationRates::STRAIGHT_LINE_RATES[50]
    end

    # ========================================================================
    # 旧定率法の償却率検証（NTA Table 2 左側、固定資産税でも使用）
    # ========================================================================
    test "旧定率法: 代表的な耐用年数の償却率がNTAテーブルと一致" do
      assert_equal 0.684, DepreciationRates::OLD_DECLINING_BALANCE_RATES[2]
      assert_equal 0.536, DepreciationRates::OLD_DECLINING_BALANCE_RATES[3]
      assert_equal 0.438, DepreciationRates::OLD_DECLINING_BALANCE_RATES[4]
      assert_equal 0.369, DepreciationRates::OLD_DECLINING_BALANCE_RATES[5]
      assert_equal 0.206, DepreciationRates::OLD_DECLINING_BALANCE_RATES[10]
      assert_equal 0.142, DepreciationRates::OLD_DECLINING_BALANCE_RATES[15]
      assert_equal 0.109, DepreciationRates::OLD_DECLINING_BALANCE_RATES[20]
      assert_equal 0.088, DepreciationRates::OLD_DECLINING_BALANCE_RATES[25]
      assert_equal 0.074, DepreciationRates::OLD_DECLINING_BALANCE_RATES[30]
      assert_equal 0.056, DepreciationRates::OLD_DECLINING_BALANCE_RATES[40]
      assert_equal 0.045, DepreciationRates::OLD_DECLINING_BALANCE_RATES[50]
    end

    test "旧定率法: 東京都手引き拡張レート（耐用年数51-52）" do
      assert_equal 0.044, DepreciationRates::OLD_DECLINING_BALANCE_RATES[51]
      assert_equal 0.043, DepreciationRates::OLD_DECLINING_BALANCE_RATES[52]
    end

    # 固定資産税の減価残存率表との一致確認
    # 東京都の電算システムは小数点以下第4位を四捨五入（数値処理の差異は±0.001以内）
    test "旧定率法: 東京都減価残存率表のA値(半年分)と一致" do
      # A = 1 - r/2 （前年中取得）
      { 2 => 0.658, 5 => 0.815, 10 => 0.897, 15 => 0.929, 20 => 0.945 }.each do |years, expected_a|
        r = DepreciationRates::OLD_DECLINING_BALANCE_RATES[years]
        calculated_a = 1 - r / 2.0
        assert_in_delta expected_a, calculated_a, 0.001,
          "耐用年数#{years}: A値の不一致 (r=#{r}, 期待値=#{expected_a}, 計算値=#{calculated_a})"
      end
    end

    test "旧定率法: 東京都減価残存率表のB値(1年分)と一致" do
      # B = 1 - r （前年前取得）
      { 2 => 0.316, 5 => 0.631, 10 => 0.794, 15 => 0.858, 20 => 0.891 }.each do |years, expected_b|
        r = DepreciationRates::OLD_DECLINING_BALANCE_RATES[years]
        calculated_b = 1 - r
        assert_in_delta expected_b, calculated_b, 0.001,
          "耐用年数#{years}: B値の不一致 (r=#{r}, 期待値=#{expected_b}, 計算値=#{calculated_b})"
      end
    end

    # ========================================================================
    # 250%定率法の検証（NTA Table 2 中央）
    # ========================================================================
    test "250%定率法: 耐用年数2の特殊ケース（改定償却率・保証率なし）" do
      rate_2 = DepreciationRates::DECLINING_BALANCE_250_RATES[2]
      assert_equal 1.000, rate_2[:rate]
      assert_nil rate_2[:revised_rate]
      assert_nil rate_2[:guarantee_rate]
    end

    test "250%定率法: 代表的な耐用年数の率がNTAテーブルと一致" do
      rate_3 = DepreciationRates::DECLINING_BALANCE_250_RATES[3]
      assert_equal 0.833, rate_3[:rate]
      assert_equal 1.000, rate_3[:revised_rate]
      assert_equal 0.02789, rate_3[:guarantee_rate]

      rate_10 = DepreciationRates::DECLINING_BALANCE_250_RATES[10]
      assert_equal 0.250, rate_10[:rate]
      assert_equal 0.334, rate_10[:revised_rate]
      assert_equal 0.04448, rate_10[:guarantee_rate]

      rate_20 = DepreciationRates::DECLINING_BALANCE_250_RATES[20]
      assert_equal 0.125, rate_20[:rate]
      assert_equal 0.143, rate_20[:revised_rate]
      assert_equal 0.02517, rate_20[:guarantee_rate]

      rate_50 = DepreciationRates::DECLINING_BALANCE_250_RATES[50]
      assert_equal 0.050, rate_50[:rate]
      assert_equal 0.053, rate_50[:revised_rate]
      assert_equal 0.01072, rate_50[:guarantee_rate]
    end

    # ========================================================================
    # 200%定率法の検証（NTA Table 2 右側）
    # ========================================================================
    test "200%定率法: 耐用年数2の特殊ケース（改定償却率・保証率なし）" do
      rate_2 = DepreciationRates::DECLINING_BALANCE_200_RATES[2]
      assert_equal 1.000, rate_2[:rate]
      assert_nil rate_2[:revised_rate]
      assert_nil rate_2[:guarantee_rate]
    end

    test "200%定率法: 代表的な耐用年数の率がNTAテーブルと一致" do
      rate_3 = DepreciationRates::DECLINING_BALANCE_200_RATES[3]
      assert_equal 0.667, rate_3[:rate]
      assert_equal 1.000, rate_3[:revised_rate]
      assert_equal 0.11089, rate_3[:guarantee_rate]

      rate_10 = DepreciationRates::DECLINING_BALANCE_200_RATES[10]
      assert_equal 0.200, rate_10[:rate]
      assert_equal 0.250, rate_10[:revised_rate]
      assert_equal 0.06552, rate_10[:guarantee_rate]

      rate_20 = DepreciationRates::DECLINING_BALANCE_200_RATES[20]
      assert_equal 0.100, rate_20[:rate]
      assert_equal 0.112, rate_20[:revised_rate]
      assert_equal 0.03486, rate_20[:guarantee_rate]

      rate_50 = DepreciationRates::DECLINING_BALANCE_200_RATES[50]
      assert_equal 0.040, rate_50[:rate]
      assert_equal 0.042, rate_50[:revised_rate]
      assert_equal 0.01440, rate_50[:guarantee_rate]
    end

    # ========================================================================
    # テーブル網羅性の検証
    # ========================================================================
    test "全テーブルが耐用年数2-50を網羅" do
      (2..50).each do |years|
        assert DepreciationRates::OLD_STRAIGHT_LINE_RATES.key?(years),
          "旧定額法に耐用年数#{years}がない"
        assert DepreciationRates::STRAIGHT_LINE_RATES.key?(years),
          "定額法に耐用年数#{years}がない"
        assert DepreciationRates::OLD_DECLINING_BALANCE_RATES.key?(years),
          "旧定率法に耐用年数#{years}がない"
        assert DepreciationRates::DECLINING_BALANCE_250_RATES.key?(years),
          "250%定率法に耐用年数#{years}がない"
        assert DepreciationRates::DECLINING_BALANCE_200_RATES.key?(years),
          "200%定率法に耐用年数#{years}がない"
      end
    end

    test "定率法テーブルの各エントリに必要なキーが存在" do
      [ DepreciationRates::DECLINING_BALANCE_250_RATES,
       DepreciationRates::DECLINING_BALANCE_200_RATES ].each do |table|
        table.each do |years, entry|
          assert entry.key?(:rate), "耐用年数#{years}にrateがない"
          assert entry.key?(:revised_rate), "耐用年数#{years}にrevised_rateがない"
          assert entry.key?(:guarantee_rate), "耐用年数#{years}にguarantee_rateがない"

          # 耐用年数2以外は改定償却率・保証率が存在すること
          if years > 2
            assert_not_nil entry[:revised_rate], "耐用年数#{years}のrevised_rateがnil"
            assert_not_nil entry[:guarantee_rate], "耐用年数#{years}のguarantee_rateがnil"
          end
        end
      end
    end

    # ========================================================================
    # 取得時期による自動判定
    # ========================================================================
    test "recommended_method: 定額法系 - H19.3.31以前は旧定額法" do
      assert_equal "old_straight_line",
        DepreciationRates.recommended_method(acquired_on: Date.new(2007, 3, 31), method_type: :straight_line)
    end

    test "recommended_method: 定額法系 - H19.4.1以後は定額法" do
      assert_equal "straight_line",
        DepreciationRates.recommended_method(acquired_on: Date.new(2007, 4, 1), method_type: :straight_line)
    end

    test "recommended_method: 定率法系 - H19.3.31以前は旧定率法" do
      assert_equal "old_declining_balance",
        DepreciationRates.recommended_method(acquired_on: Date.new(2007, 3, 31), method_type: :declining_balance)
    end

    test "recommended_method: 定率法系 - H19.4.1〜H24.3.31は250%定率法" do
      assert_equal "declining_balance_250",
        DepreciationRates.recommended_method(acquired_on: Date.new(2007, 4, 1), method_type: :declining_balance)
      assert_equal "declining_balance_250",
        DepreciationRates.recommended_method(acquired_on: Date.new(2012, 3, 31), method_type: :declining_balance)
    end

    test "recommended_method: 定率法系 - H24.4.1以後は200%定率法" do
      assert_equal "declining_balance_200",
        DepreciationRates.recommended_method(acquired_on: Date.new(2012, 4, 1), method_type: :declining_balance)
    end

    test "recommended_method: 不正なmethod_typeでArgumentError" do
      assert_raises(ArgumentError) do
        DepreciationRates.recommended_method(acquired_on: Date.today, method_type: :invalid)
      end
    end

    # ========================================================================
    # rate_for ヘルパーメソッド
    # ========================================================================
    test "rate_for: 各償却方法の率を正しく返す" do
      assert_equal 0.100, DepreciationRates.rate_for(method: "old_straight_line", useful_life: 10)
      assert_equal 0.100, DepreciationRates.rate_for(method: "straight_line", useful_life: 10)
      assert_equal 0.206, DepreciationRates.rate_for(method: "old_declining_balance", useful_life: 10)

      rate_250 = DepreciationRates.rate_for(method: "declining_balance_250", useful_life: 10)
      assert_equal 0.250, rate_250[:rate]

      rate_200 = DepreciationRates.rate_for(method: "declining_balance_200", useful_life: 10)
      assert_equal 0.200, rate_200[:rate]
    end

    test "rate_for: 存在しない耐用年数はnilを返す" do
      assert_nil DepreciationRates.rate_for(method: "old_straight_line", useful_life: 100)
    end

    test "rate_for: 存在しないメソッド名はnilを返す" do
      assert_nil DepreciationRates.rate_for(method: "invalid_method", useful_life: 10)
    end
  end
end
