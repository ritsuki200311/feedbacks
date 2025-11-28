class AddOtherTextFieldsToSupporterProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :supporter_profiles, :support_genres_other_text, :text
    add_column :supporter_profiles, :interests_other_text, :text
  end
end
