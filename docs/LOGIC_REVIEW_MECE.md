# 固定資産税・減価償却ロジック MECE レビュー

## エグゼクティブサマリー

本レビューでは、固定資産税計算アプリケーションのロジックをMECE（Mutually Exclusive, Collectively Exhaustive）原則に基づいて分析しました。

**重大な問題点:**

- ❌ **定率法の実装が完全に誤っている**（単純な均等償却になっている）
- ❌ 固定資産税評価上の減価計算が実装されていない
- ❌ 課税標準額の特例・減額措置が未実装
- ⚠️ 評価額の算出方法が簡易的すぎる

---

## 1. MECEロジックツリー: 固定資産税計算

```text
固定資産税計算
├── 1. 固定資産の分類（MECE）
│   ├── 1.1 土地
│   ├── 1.2 家屋
│   └── 1.3 償却資産
│
├── 2. 評価額の決定（分類別にMECE）
│   ├── 2.1 土地の評価
│   │   ├── 2.1.1 路線価方式
│   │   └── 2.1.2 標準地比準方式
│   ├── 2.2 家屋の評価
│   │   ├── 2.2.1 再建築価格の算出
│   │   └── 2.2.2 経年減点補正率の適用
│   └── 2.3 償却資産の評価
│       ├── 2.3.1 前年中取得: 取得価額 × (1 - 減価率 × 1/2)
│       ├── 2.3.2 前年前取得: 前年度評価額 × (1 - 減価率)
│       └── 2.3.3 最低限度額: 取得価額 × 5%
│
├── 3. 課税標準額の算出
│   ├── 3.1 特例・減額措置
│   │   ├── 3.1.1 住宅用地の特例（小規模: 1/6、一般: 1/3）
│   │   ├── 3.1.2 新築住宅の減額（3年間または5年間）
│   │   └── 3.1.3 その他の特例
│   ├── 3.2 負担調整措置
│   └── 3.3 免税点の判定
│       ├── 3.3.1 土地: 30万円
│       ├── 3.3.2 家屋: 20万円
│       └── 3.3.3 償却資産: 150万円
│
└── 4. 税額の計算
    ├── 4.1 固定資産税: 課税標準額 × 1.4%（標準税率）
    └── 4.2 都市計画税: 課税標準額 × 0.3%（上限）
```

---

## 2. MECEロジックツリー: 減価償却

```text
減価償却
├── A. 会計上の減価償却（企業会計・税務会計）
│   ├── A.1 定額法
│   │   ├── A.1.1 基本計算
│   │   │   - 償却額 = (取得価額 - 残存価額) / 耐用年数
│   │   │   - 平成19年4月以降: 残存価額 = 1円
│   │   │   - 平成19年3月以前: 残存価額 = 取得価額 × 10%
│   │   └── A.1.2 償却保証額との比較（調整額の適用）
│   │
│   └── A.2 定率法
│       ├── A.2.1 200%定率法（平成24年4月以降取得）
│       │   - 償却率 = 定額法の償却率 × 2.0
│       │   - 償却額 = 期首帳簿価額 × 償却率
│       │   - 改定償却率への切替（償却保証額を下回る場合）
│       ├── A.2.2 250%定率法（平成19年4月～平成24年3月取得）
│       │   - 償却率 = 定額法の償却率 × 2.5
│       └── A.2.3 旧定率法（平成19年3月以前取得）
│           - 償却率 = 1 - (残存価額/取得価額)^(1/耐用年数)
│
└── B. 固定資産税評価上の減価（償却資産）
    ├── B.1 減価率の決定
    │   - 旧定率法の減価率を使用（耐用年数別に設定）
    │   - 例: 耐用年数10年 → 減価率0.206
    │
    ├── B.2 評価額の計算
    │   ├── B.2.1 前年中取得（初年度）
    │   │   - 評価額 = 取得価額 × (1 - 減価率 × 1/2)
    │   └── B.2.2 前年前取得（2年目以降）
    │       - 評価額 = 前年度評価額 × (1 - 減価率)
    │
    └── B.3 最低限度額の適用
        - 評価額が取得価額の5%を下回らない
        - 最低限度額到達後は据え置き
```

---

## 3. 現在の実装の問題点（ファイル別）

### 3.1 `app/services/tax/depreciation_calculator.rb`

#### ❌ **重大な誤り: 定率法の実装**

**現在のコード（46-54行目）:**

```ruby
def calculate_declining_balance(opening_value)
  rate = 1.0 / @policy.useful_life_years
  opening_value * rate
end
```

**問題点:**

- これは定率法ではなく、単純な「帳簿価額 ÷ 耐用年数」の計算
- 結果的に均等償却になり、定率法の特性（初期に多く償却）が全く反映されない

**正しい実装（200%定率法の例）:**

```ruby
def calculate_declining_balance(opening_value)
  # 定額法の償却率
  straight_line_rate = 1.0 / @policy.useful_life_years

  # 200%定率法の償却率（定額法の2倍）
  declining_rate = straight_line_rate * 2.0

  # 当期償却額
  depreciation = opening_value * declining_rate

  # 償却保証額（取得価額 × 保証率）
  guarantee_amount = @fixed_asset.acquisition_cost * guarantee_rate(straight_line_rate)

  # 償却保証額を下回る場合は改定償却率を使用
  if depreciation < guarantee_amount
    # 改定取得価額 = 償却保証額を下回った年の期首帳簿価額
    revised_acquisition_value = opening_value
    # 改定償却率を使用
    depreciation = revised_acquisition_value * revised_depreciation_rate(straight_line_rate)
  end

  depreciation
end

# 保証率テーブル（耐用年数別）
def guarantee_rate(straight_line_rate)
  # 実際には耐用年数に応じた保証率テーブルを使用
  # 例: 耐用年数10年 → 保証率0.10800
  0.10800
end

# 改定償却率テーブル
def revised_depreciation_rate(straight_line_rate)
  # 実際には耐用年数に応じた改定償却率テーブルを使用
  # 例: 耐用年数10年 → 改定償却率0.250
  0.250
end
```

#### ⚠️ **定額法の不完全な実装**

**現在のコード（46-49行目）:**

```ruby
def calculate_straight_line(opening_value)
  depreciable_amount = @fixed_asset.acquisition_cost * (1 - @policy.residual_rate)
  depreciable_amount / @policy.useful_life_years
end
```

**問題点:**

- `opening_value`を全く使用していない
- 累計償却額が帳簿価額を超えないかのチェックがない
- 残存簿価が1円（または残存価額）を下回らないようにする制御がない

**改善例:**

```ruby
def calculate_straight_line(opening_value)
  # 償却可能額
  depreciable_amount = @fixed_asset.acquisition_cost * (1 - @policy.residual_rate)

  # 年間償却額
  annual_depreciation = depreciable_amount / @policy.useful_life_years

  # 残存簿価が残存価額を下回らないように調整
  min_book_value = @fixed_asset.acquisition_cost * @policy.residual_rate
  max_depreciation = opening_value - min_book_value

  [annual_depreciation, max_depreciation, 0].max.min(max_depreciation)
end
```

### 3.2 `app/services/tax/property_tax_calculator.rb`

#### ❌ **欠落: 固定資産税評価上の減価計算**

**問題点:**

- 償却資産の評価額計算に、会計上の減価償却（`closing_book_value`）を使用している
- 固定資産税の償却資産評価は独自の減価率を使用する必要がある

**現在のコード（106-108行目）:**

```ruby
def estimate_building_value(property)
  fixed_asset = property.fixed_assets.first
  return 0 unless fixed_asset

  depreciation_year = fixed_asset.depreciation_years.find_by(fiscal_year: @fiscal_year)
  depreciation_year&.closing_book_value || fixed_asset.acquisition_cost
end
```

**必要な実装:**

```ruby
def estimate_depreciable_asset_value(fixed_asset)
  # 固定資産税評価用の減価計算
  acquired_year = fixed_asset.acquired_on.year
  current_year = @fiscal_year.year
  years_elapsed = current_year - acquired_year

  # 固定資産税評価用の減価率を取得
  depreciation_rate = get_fixed_asset_tax_depreciation_rate(
    fixed_asset.asset_category,
    fixed_asset.useful_life_years
  )

  if years_elapsed == 0
    # 初年度: 半年償却
    @fixed_asset.acquisition_cost * (1 - depreciation_rate * 0.5)
  else
    # 2年目以降: 前年度評価額 × (1 - 減価率)
    previous_valuation = get_previous_year_valuation(fixed_asset)
    current_valuation = previous_valuation * (1 - depreciation_rate)

    # 最低限度額（取得価額の5%）を下回らない
    min_valuation = @fixed_asset.acquisition_cost * 0.05
    [current_valuation, min_valuation].max
  end
end

# 固定資産税評価用の減価率テーブル
def get_fixed_asset_tax_depreciation_rate(asset_category, useful_life_years)
  # 耐用年数に応じた減価率
  # 例:
  # 10年 → 0.206
  # 15年 → 0.142
  # 実際にはマスタテーブルから取得
  DEPRECIATION_RATE_TABLE[useful_life_years] || 0.206
end
```

#### ⚠️ **評価額の簡易計算**

**現在のコード（93-99行目）:**

```ruby
def estimate_land_value(property)
  parcel = property.land_parcels.first
  return 0 unless parcel&.area_sqm

  parcel.area_sqm * 100_000 # 仮の単価: 10万円/㎡
end
```

**問題点:**

- 単価100,000円/㎡は固定値（実際は路線価や標準地価格による）
- 地域や立地条件が全く考慮されていない

**改善の方向性:**

```ruby
def estimate_land_value(property)
  parcel = property.land_parcels.first
  return 0 unless parcel&.area_sqm

  # 路線価または標準地価格を取得
  unit_price = get_land_unit_price(
    municipality: @municipality,
    district: parcel.district,
    land_use: parcel.land_use
  )

  # 評価額 = 面積 × 単価 × 補正率
  parcel.area_sqm * unit_price * parcel.correction_factor
end
```

#### ❌ **欠落: 課税標準額の特例・減額措置**

**問題点:**

- 住宅用地の課税標準の特例が実装されていない
    - 小規模住宅用地（200㎡以下）: 評価額 × 1/6
    - 一般住宅用地（200㎡超）: 評価額 × 1/3
- 新築住宅の減額特例が実装されていない
    - 一般住宅: 3年間、税額の1/2を減額
    - 3階建以上の耐火・準耐火建築物: 5年間

**必要な実装:**

```ruby
def calculate_tax_base_value(valuation, property)
  assessed_value = valuation.assessed_value

  case property.category
  when "land"
    apply_residential_land_exemption(assessed_value, property)
  when "building"
    apply_new_construction_reduction(assessed_value, property)
  else
    assessed_value
  end
end

def apply_residential_land_exemption(assessed_value, property)
  return assessed_value unless property.residential_land?

  small_scale_area = [property.area_sqm, 200].min
  general_area = [property.area_sqm - 200, 0].max

  # 小規模住宅用地: 1/6、一般住宅用地: 1/3
  (small_scale_area / property.area_sqm * assessed_value / 6) +
  (general_area / property.area_sqm * assessed_value / 3)
end
```

#### ❌ **欠落: 免税点の判定**

**問題点:**

- 免税点のチェックがない
    - 土地: 30万円未満は非課税
    - 家屋: 20万円未満は非課税
    - 償却資産: 150万円未満は非課税

**必要な実装:**

```ruby
def calculate_property_tax(calculation_run, property)
  valuation = find_or_create_valuation(property)
  tax_base = calculate_tax_base_value(valuation, property)

  # 免税点の判定
  if below_exemption_threshold?(tax_base, property.category)
    tax_amount = 0
  else
    tax_amount = tax_base * tax_rate
  end

  # ... 結果の保存
end

def below_exemption_threshold?(tax_base, category)
  threshold = case category
              when "land" then 300_000
              when "building" then 200_000
              when "depreciable_group" then 1_500_000
              else 0
              end

  tax_base < threshold
end
```

#### ⚠️ **税率の不完全な実装**

**現在のコード（118-121行目）:**

```ruby
def tax_rate
  # 実際には自治体ごとに異なる税率を持つべきだが、ここでは標準税率を使用
  STANDARD_TAX_RATE
end
```

**問題点:**

- 都市計画税（最大0.3%）が考慮されていない
- 自治体独自の税率変更に対応していない

**改善例:**

```ruby
def tax_rate
  # 固定資産税率（自治体が独自に設定可能）
  @municipality.property_tax_rate || STANDARD_TAX_RATE
end

def city_planning_tax_rate
  # 都市計画税率（市街化区域内のみ、最大0.3%）
  return 0 unless @municipality.has_city_planning_tax?
  @municipality.city_planning_tax_rate || 0.003
end

def total_tax_amount(tax_base)
  property_tax = tax_base * tax_rate
  city_planning_tax = tax_base * city_planning_tax_rate
  property_tax + city_planning_tax
end
```

---

## 4. データモデルの不足

### 4.1 必要だが欠落しているテーブル

#### A. 固定資産税評価用の減価率マスタ

```ruby
# app/models/fixed_asset_tax_depreciation_rate.rb
class FixedAssetTaxDepreciationRate < ApplicationRecord
  # columns: asset_category, useful_life_years, depreciation_rate
  # 例: "機械装置", 10, 0.206
end
```

#### B. 路線価・標準地価格マスタ

```ruby
# app/models/land_price.rb
class LandPrice < ApplicationRecord
  belongs_to :municipality

  # columns: municipality_id, fiscal_year_id, district,
  #          unit_price_per_sqm, land_use_category
end
```

#### C. 経年減点補正率マスタ（家屋用）

```ruby
# app/models/building_depreciation_factor.rb
class BuildingDepreciationFactor < ApplicationRecord
  # columns: structure_type, years_elapsed, depreciation_factor
  # 例: "木造", 10, 0.500
end
```

#### D. 保証率・改定償却率テーブル（200%定率法用）

```ruby
# app/models/depreciation_guarantee_rate.rb
class DepreciationGuaranteeRate < ApplicationRecord
  # columns: useful_life_years, guarantee_rate, revised_depreciation_rate
  # 例: 10, 0.10800, 0.250
end
```

---

## 5. 優先度別の修正推奨事項

### 🔴 優先度: 高（重大な誤り）

1. **定率法の実装を完全に書き直す**
   - ファイル: `app/services/tax/depreciation_calculator.rb`
   - 200%定率法、250%定率法、旧定率法を正しく実装
   - 償却保証額と改定償却率の処理を追加

2. **固定資産税評価上の減価計算を実装**
   - 新規サービスクラス: `Tax::FixedAssetTaxValuationCalculator`
   - 償却資産の評価額を正しく計算

### 🟡 優先度: 中（機能不足）

1. **課税標準額の特例・減額措置を実装**
   - 住宅用地の特例（1/6、1/3）
   - 新築住宅の減額特例

2. **免税点の判定を追加**
   - 土地30万円、家屋20万円、償却資産150万円

3. **都市計画税の計算を追加**

### 🟢 優先度: 低（改善事項）

1. **評価額算出方法の精緻化**
   - 路線価マスタの整備
   - 経年減点補正率の適用

2. **自治体別の税率設定機能**

---

## 6. 結論

現在の実装には、日本の固定資産税・減価償却の正しいロジックから見て、以下の重大な問題があります:

1. ❌ **定率法の計算が完全に誤っている**（最優先で修正が必要）
2. ❌ 固定資産税評価上の減価計算が未実装
3. ❌ 課税標準額の特例・減額措置が未実装
4. ⚠️ 評価額の算出が簡易的すぎる

これらの問題を修正しない限り、**本アプリケーションは正確な固定資産税の計算ができません**。

MECEに基づいた分析により、必要な機能が漏れなく洗い出され、重複なく整理されました。上記の優先度に従って修正を進めることを強く推奨します。

---

## 参考文献

- 地方税法 第341条～第388条（固定資産税）
- 地方税法 第702条の6～第702条の8（都市計画税）
- 減価償却資産の耐用年数等に関する省令
- 固定資産評価基準（総務省）
- 償却資産申告の手引き（各市区町村）
