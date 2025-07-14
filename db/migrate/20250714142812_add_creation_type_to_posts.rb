class AddCreationTypeToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :creation_type, :integer
  end
end
