class CreateCalculationResults < ActiveRecord::Migration[8.0]
  def change
    create_table :calculation_results do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :calculation_run, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true

      # 税額など結果
      t.decimal :tax_amount, precision: 15, scale: 2, null: false, default: 0
      t.json :breakdown_json # 内訳

      t.timestamps
    end

    add_index :calculation_results, [ :tenant_id, :calculation_run_id ]
    add_index :calculation_results, [ :tenant_id, :property_id ]
  end
end
