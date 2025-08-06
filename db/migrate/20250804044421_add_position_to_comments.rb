class AddPositionToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :x_position, :decimal
    add_column :comments, :y_position, :decimal
  end
end
