class AddImageIndexToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :image_index, :integer
  end
end
