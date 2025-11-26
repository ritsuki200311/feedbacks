class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_votable

  def vote
    Rails.logger.info "🔥 Vote request received: #{params.inspect}"
    Rails.logger.info "🔥 Current user: #{current_user&.id}"
    Rails.logger.info "🔥 Votable: #{@votable.class.name}##{@votable.id}"

    vote = @votable.votes.find_by(user: current_user)
    new_value = params[:value].to_i

    Rails.logger.info "🔥 Existing vote: #{vote&.value}, New value: #{new_value}"

    # 0は投票取り消し、-1と1は有効な投票値
    unless [ -1, 0, 1 ].include?(new_value)
      respond_to do |format|
        format.json { render json: { success: false, error: "invalid_value" }, status: :unprocessable_entity }
        format.html { redirect_back(fallback_location: root_path, alert: "不正な投票値です。") }
      end
      return
    end

    # 既存の投票がある場合
    if vote.present?
      if new_value == 0
        # 投票取り消し
        vote.destroy!
      else
        # 投票値の変更
        vote.update!(value: new_value)
      end
    else
      # 新規投票（0は何もしない）
      if new_value != 0
        @votable.votes.create!(user: current_user, value: new_value, comment: params[:comment])
      end
    end

    # 最新の投票数を取得
    up_count = @votable.votes.where(value: 1).count
    down_count = @votable.votes.where(value: -1).count
    net = up_count - down_count
    user_vote = @votable.votes.find_by(user: current_user)&.value || 0

    respond_to do |format|
      format.json { render json: { success: true, user_vote: user_vote, up_count: up_count, down_count: down_count, net: net } }
      format.html { redirect_back(fallback_location: root_path, notice: "投票を更新しました。") }
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
