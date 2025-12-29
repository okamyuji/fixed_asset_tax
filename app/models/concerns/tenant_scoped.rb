module TenantScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :tenant
    validates :tenant_id, presence: true

    scope :for_current_tenant, -> { where(tenant_id: Current.tenant&.id) }

    before_validation :set_tenant_from_current, on: :create

    private

    def set_tenant_from_current
      self.tenant ||= Current.tenant if Current.tenant
    end
  end
end
