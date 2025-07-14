class AddRequestTagToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :request_tag, :string
  end
end
