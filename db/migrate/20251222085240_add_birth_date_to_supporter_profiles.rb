class AddBirthDateToSupporterProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :supporter_profiles, :birth_date, :date
  end
end
