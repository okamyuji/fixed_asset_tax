class AddEnhancedFieldsToFixedAssets < ActiveRecord::Migration[8.0]
  def change
    add_column :fixed_assets, :account_item, :string
    add_column :fixed_assets, :asset_classification, :string
    add_column :fixed_assets, :business_use_ratio, :decimal, precision: 5, scale: 4, default: 1.0
    add_column :fixed_assets, :acquisition_type, :string, default: "new"
    add_column :fixed_assets, :service_start_date, :date
    add_column :fixed_assets, :quantity, :integer, default: 1
    add_column :fixed_assets, :unit, :string
    add_column :fixed_assets, :location, :string
    add_column :fixed_assets, :description, :text

    add_index :fixed_assets, :account_item
    add_index :fixed_assets, :asset_classification
    add_index :fixed_assets, :service_start_date
  end
end
