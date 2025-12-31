class AddCanFeedbackToSupporterProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :supporter_profiles, :can_feedback, :text
  end
end
