class CreateSupporterProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :supporter_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.text :standing
      t.string :creation_experience
      t.text :interests
      t.text :favorite_artists
      t.string :age_group
      t.text :support_genres
      t.text :support_styles
      t.text :personality_traits

      t.timestamps
    end
  end
end