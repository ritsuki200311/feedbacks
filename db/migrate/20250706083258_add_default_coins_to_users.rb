class AddDefaultCoinsToUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :coins, from: nil, to: 1
  end
end
