class RoomsController < ApplicationController
  before_action :authenticate_user!
  layout "chat", only: [ :show ]

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

    @messages = @room.messages.includes(:user)
    @message = Message.new
    @other_user = @room.entries.where.not(user_id: current_user.id).first&.user

    Message.mark_as_read_by_room_and_user(@room, @other_user)
  end
end
