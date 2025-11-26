class ChangeDefaultCoinsForUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :coins, from: 1, to: 100
  end
end
