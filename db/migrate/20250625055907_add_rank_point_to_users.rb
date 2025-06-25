class AddRankPointToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :rank_point, :integer, default: 0, null: false
  end
end
