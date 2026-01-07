class FixedAsset < ApplicationRecord
  include TenantScoped
  include AssetClassifications

  belongs_to :property
  has_one :depreciation_policy, dependent: :destroy
  has_many :depreciation_years, dependent: :destroy

  validates :name, presence: true
  validates :acquired_on, presence: true
  validates :acquisition_cost, presence: true, numericality: { greater_than: 0 }
  validates :asset_type, presence: true
  validates :account_item, presence: true
  validates :asset_classification, presence: true, inclusion: {
    in: %w[tangible intangible deferred]
  }
  validates :business_use_ratio, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 1
  }, allow_nil: true
  validates :acquisition_type, inclusion: {
    in: %w[new used self_constructed gift inheritance]
  }, allow_nil: true
  validates :quantity, numericality: {
    only_integer: true,
    greater_than: 0
  }, allow_nil: true

  # 個人事業主の場合は事業利用割合が必須
  validate :business_use_ratio_required_for_individual

  # 事業供用開始日のデフォルトは取得日
  before_validation :set_default_service_start_date, on: :create

  scope :by_account_item, ->(item) { where(account_item: item) }
  scope :by_classification, ->(classification) { where(asset_classification: classification) }
  scope :tangible, -> { where(asset_classification: "tangible") }
  scope :intangible, -> { where(asset_classification: "intangible") }
  scope :deferred, -> { where(asset_classification: "deferred") }

  def party
    property&.party
  end

  def individual?
    party&.type == "Individual"
  end

  def corporation?
    party&.type == "Corporation"
  end

  def business_acquisition_cost
    return acquisition_cost unless individual? && business_use_ratio

    acquisition_cost * business_use_ratio
  end

  def account_item_name
    self.class.account_item_name(account_item)
  end

  def asset_classification_name
    self.class.asset_classification_name(asset_classification)
  end

  def depreciable?
    # 土地、借地権、電話加入権などは非償却資産
    !%w[land leasehold_rights telephone_rights].include?(account_item)
  end

  private

  def business_use_ratio_required_for_individual
    return unless individual?

    if business_use_ratio.nil?
      errors.add(:business_use_ratio, "は個人事業主の場合必須です")
    end
  end

  def set_default_service_start_date
    self.service_start_date ||= acquired_on
  end
end
