class AddReceivedUserIdToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :received_user_id, :integer
    add_index :posts, :received_user_id
  end
end
