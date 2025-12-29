class CreateDepreciationPolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :depreciation_policies do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :fixed_asset, null: false, foreign_key: true

      t.string :method, null: false, default: "straight_line" # 定額/定率など
      t.integer :useful_life_years, null: false
      t.decimal :residual_rate, precision: 6, scale: 5, null: false, default: 0.0
      t.timestamps
    end

    add_index :depreciation_policies, [ :tenant_id, :fixed_asset_id ], unique: true
  end
end
