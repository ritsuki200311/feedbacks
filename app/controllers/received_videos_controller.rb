class ReceivedVideosController < ApplicationController
  before_action :authenticate_user!

  def index
    @received_videos = current_user.received_videos.order(created_at: :desc)
  end
end
