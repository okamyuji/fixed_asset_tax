class DepreciationPolicy < ApplicationRecord
  include TenantScoped
  include AssetClassifications

  belongs_to :fixed_asset

  validates :method, presence: true, inclusion: {
    in: %w[straight_line declining_balance declining_balance_250 declining_balance_200]
  }
  validates :useful_life_years, presence: true, numericality: {
    only_integer: true,
    greater_than: 0
  }
  validates :residual_rate, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 1
  }
  validates :fixed_asset_id, uniqueness: { scope: :tenant_id }
  validates :depreciation_type, presence: true, inclusion: {
    in: %w[normal lump_sum small_value immediate special accelerated]
  }
  validates :special_depreciation_rate, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 1
  }, allow_nil: true

  # 法人の特別償却の場合は特別償却率が必須
  validate :special_depreciation_rate_required_for_special

  # 償却開始日のデフォルトは資産の事業供用開始日
  before_validation :set_default_depreciation_start_date, on: :create

  scope :normal, -> { where(depreciation_type: "normal") }
  scope :lump_sum, -> { where(depreciation_type: "lump_sum") }
  scope :small_value, -> { where(depreciation_type: "small_value") }
  scope :immediate, -> { where(depreciation_type: "immediate") }
  scope :special, -> { where(depreciation_type: "special") }
  scope :accelerated, -> { where(depreciation_type: "accelerated") }

  def depreciation_method_name
    self.class.depreciation_method_name(method)
  end

  def depreciation_type_name
    DEPRECIATION_TYPES.dig(depreciation_type.to_sym, :name) || depreciation_type
  end

  def normal_depreciation?
    depreciation_type == "normal"
  end

  def lump_sum_depreciation?
    depreciation_type == "lump_sum"
  end

  def small_value_depreciation?
    depreciation_type == "small_value"
  end

  def immediate_depreciation?
    depreciation_type == "immediate"
  end

  def special_depreciation?
    depreciation_type == "special"
  end

  def accelerated_depreciation?
    depreciation_type == "accelerated"
  end

  private

  def special_depreciation_rate_required_for_special
    return unless special_depreciation?

    if special_depreciation_rate.nil?
      errors.add(:special_depreciation_rate, "は特別償却の場合必須です")
    end
  end

  def set_default_depreciation_start_date
    self.depreciation_start_date ||= fixed_asset&.service_start_date || fixed_asset&.acquired_on
  end

  def self.depreciation_method_name(key)
    DEPRECIATION_METHODS.dig(key.to_sym, :name) || key
  end
end
