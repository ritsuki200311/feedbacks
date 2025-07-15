class Message < ApplicationRecord
  belongs_to :user
  belongs_to :room

  def self.mark_as_read_by_room_and_user(room, user)
    room.messages.where(user_id: user.id, is_read: false).update_all(is_read: true)
  end
end
