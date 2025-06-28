class ReceivedVideo < ApplicationRecord
  belongs_to :user
    belongs_to :sender, class_name: 'User'
  belongs_to :post
end
