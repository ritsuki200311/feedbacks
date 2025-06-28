class AddRecipientStandingToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :recipient_standing, :text
  end
end
