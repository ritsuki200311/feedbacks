class AddRecipientSupportStylesToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :recipient_support_styles, :text
  end
end
