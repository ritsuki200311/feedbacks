class AddDetailsToPreferences < ActiveRecord::Migration[8.0]
  def change
    add_column :preferences, :genre, :string
    add_column :preferences, :instrument_experience, :string
    add_column :preferences, :favorite_artist, :string
    add_column :preferences, :career, :string
  end
end
