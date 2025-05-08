class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @room = Room.find(params[:room_id])
    @message = @room.messages.build(message_params)
    @message.user = current_user
    if @message.save
      redirect_to room_path(@room)
    else
      render "rooms/show"
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end