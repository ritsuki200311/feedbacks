class CreatePostRecipients < ActiveRecord::Migration[8.0]
  def change
    create_table :post_recipients do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :sent_at

      t.timestamps
    end
  end
end
