class CreateParties < ActiveRecord::Migration[8.0]
  def change
    create_table :parties do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :type, null: false # "Individual" or "Corporation"

      # 共通
      t.string :display_name, null: false

      # 個人向け
      t.date :birth_date

      # 法人向け
      t.string :corporate_number

      t.timestamps
    end

    add_index :parties, [ :tenant_id, :type ]
    add_index :parties, [ :tenant_id, :corporate_number ], unique: true
  end
end
