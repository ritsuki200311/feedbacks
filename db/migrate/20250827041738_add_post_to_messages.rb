class AddPostToMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :messages, :post, null: true, foreign_key: true
  end
end
