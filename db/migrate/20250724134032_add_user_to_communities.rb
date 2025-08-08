class AddUserToCommunities < ActiveRecord::Migration[8.0]
  def change
    add_reference :communities, :user, null: false, foreign_key: true
  end
end
