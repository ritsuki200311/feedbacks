class AddIsReadToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :is_read, :boolean
  end
end
