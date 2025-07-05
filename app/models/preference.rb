class Preference < ApplicationRecord
  belongs_to :user
  attribute :selected_items, :string, default: [].to_json
end
