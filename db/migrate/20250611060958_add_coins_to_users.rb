class AddCoinsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :coins, :integer, default: 1, null: false
  end
end
