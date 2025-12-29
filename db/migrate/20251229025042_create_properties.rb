class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :party, null: false, foreign_key: true # 所有者
      t.references :municipality, null: false, foreign_key: true

      t.string :category, null: false # "land" / "building" / "depreciable_group"
      t.string :name, null: false

      t.timestamps
    end

    add_index :properties, [ :tenant_id, :party_id ]
    add_index :properties, [ :tenant_id, :municipality_id, :category ]
  end
end
