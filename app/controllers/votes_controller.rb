class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_votable

  def vote
    vote = @votable.votes.find_by(user: current_user)
    new_value = params[:value].to_i

    # 一度投票したら変更・取り消し不可（B仕様）
    if vote.present?
      up_count = @votable.votes.where(value: 1).count
      down_count = @votable.votes.where(value: -1).count
      net = up_count - down_count

      respond_to do |format|
        format.json { render json: { success: false, error: "already_voted", user_vote: vote.value, up_count: up_count, down_count: down_count, net: net }, status: :forbidden }
        format.html { redirect_back(fallback_location: root_path, alert: "すでに投票済みです。") }
      end
      return
    end

    unless [ -1, 1 ].include?(new_value)
      respond_to do |format|
        format.json { render json: { success: false, error: "invalid_value" }, status: :unprocessable_entity }
        format.html { redirect_back(fallback_location: root_path, alert: "不正な投票値です。") }
      end
      return
    end

    @votable.votes.create!(user: current_user, value: new_value, comment: params[:comment])

    up_count = @votable.votes.where(value: 1).count
    down_count = @votable.votes.where(value: -1).count
    net = up_count - down_count

    respond_to do |format|
      format.json { render json: { success: true, user_vote: new_value, up_count: up_count, down_count: down_count, net: net } }
      format.html { redirect_back(fallback_location: root_path, notice: "投票しました。") }
    end
  end

  private

  def set_votable
    votable_type_name = params[:votable_type]
    # 許可するモデル名のリスト
    allowed_types = %w[Post Comment]

    unless allowed_types.include?(votable_type_name)
      # 不正な値が来た場合はエラーを発生させて処理を中断
      raise "Invalid votable type: #{votable_type_name}"
    end

    votable_type = votable_type_name.classify.constantize
    @votable = votable_type.find(params[:votable_id])
  end
end
