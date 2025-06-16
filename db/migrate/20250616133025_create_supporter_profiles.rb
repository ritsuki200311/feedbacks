class CreateSupporterProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :supporter_profiles do |t|  # ←これが必要！

      t.references :user, null: false, foreign_key: true
      t.string :standing, array: true, default: []
      t.string :creation_experience
      t.string :interests, array: true, default: []
      t.text   :favorite_artists
      t.string :age_group
      t.string :support_genres, array: true, default: []
      t.string :support_styles, array: true, default: []
      t.string :personality_traits, array: true, default: []

      t.timestamps
    end
  end
end