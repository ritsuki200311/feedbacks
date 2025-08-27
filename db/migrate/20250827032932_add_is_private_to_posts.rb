class AddIsPrivateToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :is_private, :boolean, default: false, null: false
  end
end
