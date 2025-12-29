class CreateFixedAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :fixed_assets do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true

      t.string :name, null: false
      t.date :acquired_on, null: false
      t.decimal :acquisition_cost, precision: 15, scale: 2, null: false
      t.string :asset_type, null: false # 機械装置/工具器具備品 等
      t.timestamps
    end

    add_index :fixed_assets, [ :tenant_id, :property_id ]
    add_index :fixed_assets, [ :tenant_id, :acquired_on ]
  end
end
