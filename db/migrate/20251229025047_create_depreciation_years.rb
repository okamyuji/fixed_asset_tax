class CreateDepreciationYears < ActiveRecord::Migration[8.0]
  def change
    create_table :depreciation_years do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :fixed_asset, null: false, foreign_key: true
      t.references :fiscal_year, null: false, foreign_key: true

      t.decimal :opening_book_value, precision: 15, scale: 2, null: false
      t.decimal :depreciation_amount, precision: 15, scale: 2, null: false
      t.decimal :closing_book_value, precision: 15, scale: 2, null: false

      t.timestamps
    end

    add_index :depreciation_years, [ :tenant_id, :fixed_asset_id, :fiscal_year_id ],
              unique: true, name: "idx_depr_years_uni"
  end
end
