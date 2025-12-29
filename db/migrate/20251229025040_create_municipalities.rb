class CreateMunicipalities < ActiveRecord::Migration[8.0]
  def change
    create_table :municipalities do |t|
      t.string :code, null: false # 自治体コード
      t.string :name, null: false
      t.timestamps
    end
    add_index :municipalities, :code, unique: true
  end
end
