class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "admin" # admin/member/viewer
      t.timestamps
    end
    add_index :memberships, [ :tenant_id, :user_id ], unique: true
  end
end
