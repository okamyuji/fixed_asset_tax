class AddEnhancedFieldsToDepreciationPolicies < ActiveRecord::Migration[8.0]
  def change
    add_column :depreciation_policies, :depreciation_type, :string, default: "normal"
    add_column :depreciation_policies, :special_depreciation_rate, :decimal, precision: 5, scale: 4
    add_column :depreciation_policies, :first_year_prorated, :boolean, default: true
    add_column :depreciation_policies, :registered_method, :string
    add_column :depreciation_policies, :depreciation_start_date, :date
    add_column :depreciation_policies, :memo, :text

    add_index :depreciation_policies, :depreciation_type
    add_index :depreciation_policies, :depreciation_start_date
  end
end
