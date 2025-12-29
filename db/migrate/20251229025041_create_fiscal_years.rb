class CreateFiscalYears < ActiveRecord::Migration[8.0]
  def change
    create_table :fiscal_years do |t|
      t.integer :year, null: false # 例: 2025
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.timestamps
    end
    add_index :fiscal_years, :year, unique: true
  end
end
