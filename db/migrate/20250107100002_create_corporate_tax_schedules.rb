class CreateCorporateTaxSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :corporate_tax_schedules do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :fiscal_year, null: false, foreign_key: true
      t.string :schedule_type, null: false
      t.json :data_json
      t.string :status, default: "draft", null: false
      t.text :notes
      t.datetime :finalized_at

      t.timestamps
    end

    add_index :corporate_tax_schedules, [ :tenant_id, :fiscal_year_id, :schedule_type ],
              unique: true,
              name: "idx_corp_tax_schedules_unique"
    add_index :corporate_tax_schedules, :status
    add_index :corporate_tax_schedules, :schedule_type
  end
end
