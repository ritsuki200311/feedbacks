class ChangeUsersCoinsDefaultToThree < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :coins, from: 100, to: 3
  end
end
