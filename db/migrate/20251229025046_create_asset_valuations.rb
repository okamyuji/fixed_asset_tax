class CreateAssetValuations < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_valuations do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :municipality, null: false, foreign_key: true
      t.references :fiscal_year, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true

      # 入力値
      t.decimal :assessed_value, precision: 15, scale: 2
      t.decimal :tax_base_value, precision: 15, scale: 2
      t.json :special_measures_json # 特例・軽減など

      # 入力の出所・メモ
      t.string :source, null: false, default: "user"
      t.text :note

      t.timestamps
    end

    add_index :asset_valuations, [ :tenant_id, :municipality_id, :fiscal_year_id, :property_id ],
              unique: true, name: "idx_asset_valuations_uni"
  end
end
