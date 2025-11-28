class AddFavoriteWorksToSupporterProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :supporter_profiles, :favorite_works, :text
  end
end
