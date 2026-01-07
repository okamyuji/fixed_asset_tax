module AssetClassifications
  extend ActiveSupport::Concern

  # 資産分類
  ASSET_CLASSIFICATIONS = {
    tangible: { name: "有形固定資産", code: "1" },
    intangible: { name: "無形固定資産", code: "2" },
    deferred: { name: "繰延資産", code: "3" }
  }.freeze

  # 勘定科目（有形固定資産）
  TANGIBLE_ACCOUNT_ITEMS = {
    buildings: {
      name: "建物",
      code: "101",
      useful_life_range: 3..50,
      description: "店舗、事務所、工場、倉庫等の建物本体"
    },
    building_fixtures: {
      name: "建物附属設備",
      code: "102",
      useful_life_range: 3..18,
      description: "電気設備、給排水設備、空調設備等"
    },
    structures: {
      name: "構築物",
      code: "103",
      useful_life_range: 3..60,
      description: "舗装路面、緑化施設、広告塔等"
    },
    machinery: {
      name: "機械装置",
      code: "104",
      useful_life_range: 2..22,
      description: "製造設備、工作機械等"
    },
    vehicles: {
      name: "車両運搬具",
      code: "105",
      useful_life_range: 2..7,
      description: "自動車、トラック、フォークリフト等"
    },
    tools_furniture_fixtures: {
      name: "工具器具備品",
      code: "106",
      useful_life_range: 2..20,
      description: "パソコン、机、椅子、測定工具等"
    },
    land: {
      name: "土地",
      code: "107",
      useful_life_range: nil,
      description: "土地（非償却資産）"
    },
    construction_in_progress: {
      name: "建設仮勘定",
      code: "108",
      useful_life_range: nil,
      description: "建設中の資産"
    }
  }.freeze

  # 勘定科目（無形固定資産）
  INTANGIBLE_ACCOUNT_ITEMS = {
    software: {
      name: "ソフトウェア",
      code: "201",
      useful_life_range: 3..5,
      description: "業務用ソフトウェア、自社開発ソフトウェア"
    },
    patent_rights: {
      name: "特許権",
      code: "202",
      useful_life_range: 8..8,
      description: "特許権"
    },
    trademark_rights: {
      name: "商標権",
      code: "203",
      useful_life_range: 10..10,
      description: "商標権"
    },
    utility_model_rights: {
      name: "実用新案権",
      code: "204",
      useful_life_range: 5..5,
      description: "実用新案権"
    },
    design_rights: {
      name: "意匠権",
      code: "205",
      useful_life_range: 7..7,
      description: "意匠権"
    },
    goodwill: {
      name: "のれん",
      code: "206",
      useful_life_range: 5..20,
      description: "営業権、のれん"
    },
    leasehold_rights: {
      name: "借地権",
      code: "207",
      useful_life_range: nil,
      description: "借地権（非償却資産）"
    },
    telephone_rights: {
      name: "電話加入権",
      code: "208",
      useful_life_range: nil,
      description: "電話加入権（非償却資産）"
    }
  }.freeze

  # 勘定科目（繰延資産）
  DEFERRED_ACCOUNT_ITEMS = {
    organization_costs: {
      name: "創立費",
      code: "301",
      useful_life_range: 5..5,
      description: "会社設立のための費用"
    },
    business_commencement_costs: {
      name: "開業費",
      code: "302",
      useful_life_range: 5..5,
      description: "開業準備のための費用"
    },
    development_costs: {
      name: "開発費",
      code: "303",
      useful_life_range: 5..5,
      description: "新技術・新製品の開発費用"
    },
    stock_issuance_costs: {
      name: "株式交付費",
      code: "304",
      useful_life_range: 3..3,
      description: "株式発行のための費用"
    },
    bond_issuance_costs: {
      name: "社債発行費",
      code: "305",
      useful_life_range: 3..3,
      description: "社債発行のための費用"
    }
  }.freeze

  # 全勘定科目
  ALL_ACCOUNT_ITEMS = TANGIBLE_ACCOUNT_ITEMS.merge(INTANGIBLE_ACCOUNT_ITEMS).merge(DEFERRED_ACCOUNT_ITEMS).freeze

  # 償却方法
  DEPRECIATION_METHODS = {
    straight_line: { name: "定額法", code: "1" },
    declining_balance: { name: "定率法", code: "2" },
    declining_balance_250: { name: "250%定率法", code: "3" },
    declining_balance_200: { name: "200%定率法", code: "4" }
  }.freeze

  # 償却種類
  DEPRECIATION_TYPES = {
    normal: { name: "通常償却", code: "1" },
    lump_sum: { name: "一括償却（3年）", code: "2", threshold: 100_000..199_999 },
    small_value: { name: "少額減価償却", code: "3", threshold: 100_000..299_999 },
    immediate: { name: "即時償却（10万円未満）", code: "4", threshold: 0..99_999 },
    special: { name: "特別償却", code: "5" },
    accelerated: { name: "割増償却", code: "6" }
  }.freeze

  # 取得形態
  ACQUISITION_TYPES = {
    new: { name: "新品", code: "1" },
    used: { name: "中古", code: "2" },
    self_constructed: { name: "自家建設", code: "3" },
    gift: { name: "贈与", code: "4" },
    inheritance: { name: "相続", code: "5" }
  }.freeze

  class_methods do
    def account_item_options
      ALL_ACCOUNT_ITEMS.map { |key, value| [ value[:name], key.to_s ] }
    end

    def asset_classification_options
      ASSET_CLASSIFICATIONS.map { |key, value| [ value[:name], key.to_s ] }
    end

    def depreciation_method_options
      DEPRECIATION_METHODS.map { |key, value| [ value[:name], key.to_s ] }
    end

    def depreciation_type_options
      DEPRECIATION_TYPES.map { |key, value| [ value[:name], key.to_s ] }
    end

    def acquisition_type_options
      ACQUISITION_TYPES.map { |key, value| [ value[:name], key.to_s ] }
    end

    def useful_life_for(account_item_key)
      item = ALL_ACCOUNT_ITEMS[account_item_key.to_sym]
      return nil unless item

      range = item[:useful_life_range]
      return nil unless range

      # 範囲の中央値を返す（デフォルト値として）
      (range.min + range.max) / 2
    end

    def account_item_name(key)
      ALL_ACCOUNT_ITEMS.dig(key.to_sym, :name) || key
    end

    def asset_classification_name(key)
      ASSET_CLASSIFICATIONS.dig(key.to_sym, :name) || key
    end
  end
end
