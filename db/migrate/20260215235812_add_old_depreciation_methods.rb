class AddOldDepreciationMethods < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      UPDATE depreciation_policies
      SET method = 'declining_balance_200'
      WHERE method = 'declining_balance'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE depreciation_policies
      SET method = 'declining_balance'
      WHERE method = 'declining_balance_200'
    SQL
  end
end
