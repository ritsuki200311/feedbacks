class RoomsController < ApplicationController
  before_action :authenticate_user!
  layout "chat", only: [ :show ]

  def index
    # マイページと同じ方式で取得（エントリ経由）
    @entries = current_user.entries.includes(room: [:messages, :users])
    
    # 未読メッセージがあるルーム
    @unread_rooms = []
    @unread_counts = {}
    
    @entries.each do |entry|
      room = entry.room
      other_entry = room.entries.where.not(user_id: current_user.id).first
      next unless other_entry
      
      other_user = other_entry.user
      unread_count = room.messages.where(user: other_user, is_read: false).count
      
      if unread_count > 0
        @unread_rooms << room
        @unread_counts[room.id] = unread_count
      end
    end
  end

  def create
    other_user = User.find(params[:user_id])

    # 既存のルームがあるか確認
    existing_room = Room.joins(:entries)
                        .where(entries: { user_id: [ current_user.id, other_user.id ] })
                        .group("rooms.id")
                        .having("COUNT(rooms.id) = 2")
                        .first

    if existing_room
      redirect_to room_path(existing_room)
    else
      room = Room.create
      Entry.create(user: current_user, room: room)
      Entry.create(user: other_user, room: room)
      redirect_to room_path(room)
    end
  end

  def show
    @room = Room.find(params[:id])

    unless @room.entries.exists?(user_id: current_user.id)
      redirect_to root_path, alert: "そのチャットルームにはアクセスできません"
      return
    end

    @messages = @room.messages.includes(:user, post: { images_attachments: :blob })
    @message = Message.new
    @other_user = @room.entries.where.not(user_id: current_user.id).first&.user

    Message.mark_as_read_by_room_and_user(@room, @other_user)
  end
end
