class Room < ApplicationRecord
    has_many :entries
    has_many :users, through: :entries
    has_many :messages

    def self.find_existing_room_for_users(user1, user2)
      joins(:entries)
        .where(entries: { user_id: [user1.id, user2.id] })
        .group("rooms.id")
        .having("COUNT(rooms.id) = 2")
        .first
    end
end