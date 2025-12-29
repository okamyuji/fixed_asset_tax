class CreateLandParcels < ActiveRecord::Migration[8.0]
  def change
    create_table :land_parcels do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true

      t.string :parcel_no
      t.decimal :area_sqm, precision: 12, scale: 2
      t.timestamps
    end

    add_index :land_parcels, [ :tenant_id, :property_id ]
  end
end
