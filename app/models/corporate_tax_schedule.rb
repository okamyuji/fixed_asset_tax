class CorporateTaxSchedule < ApplicationRecord
  include TenantScoped

  belongs_to :fiscal_year

  validates :schedule_type, presence: true, inclusion: {
    in: %w[schedule_16_1 schedule_16_2 schedule_16_6 schedule_16_7]
  }
  validates :status, presence: true, inclusion: {
    in: %w[draft finalized]
  }
  validates :schedule_type, uniqueness: { scope: [ :tenant_id, :fiscal_year_id ] }

  # 別表十六(一): 定額法償却資産
  scope :schedule_16_1, -> { where(schedule_type: "schedule_16_1") }
  # 別表十六(二): 定率法償却資産
  scope :schedule_16_2, -> { where(schedule_type: "schedule_16_2") }
  # 別表十六(六): 一括償却資産
  scope :schedule_16_6, -> { where(schedule_type: "schedule_16_6") }
  # 別表十六(七): 少額減価償却資産
  scope :schedule_16_7, -> { where(schedule_type: "schedule_16_7") }

  scope :draft, -> { where(status: "draft") }
  scope :finalized, -> { where(status: "finalized") }

  def finalize!
    update!(status: "finalized", finalized_at: Time.current)
  end

  def draft?
    status == "draft"
  end

  def finalized?
    status == "finalized"
  end
end
