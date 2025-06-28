class CreateReceivedVideos < ActiveRecord::Migration[7.1]
  def change
    create_table :received_videos do |t|
      t.references :user, null: false, foreign_key: true        # 受信者
      t.references :sender, null: false, foreign_key: { to_table: :users }  # 送信者
      t.references :post, null: false, foreign_key: true
      t.string :title
      t.string :thumbnail_url

      t.timestamps
    end
  end
end