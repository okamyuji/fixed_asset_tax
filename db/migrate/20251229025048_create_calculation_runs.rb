class CreateCalculationRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :calculation_runs do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :municipality, null: false, foreign_key: true
      t.references :fiscal_year, null: false, foreign_key: true

      t.string :status, null: false, default: "queued" # queued/running/succeeded/failed
      t.json :parameters_json
      t.text :error_message
      t.timestamps
    end

    add_index :calculation_runs, [ :tenant_id, :municipality_id, :fiscal_year_id ]
  end
end
