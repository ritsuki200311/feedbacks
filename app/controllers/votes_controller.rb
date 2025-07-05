class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_votable

  def vote
    vote = @votable.votes.find_or_initialize_by(user: current_user)
    new_value = params[:value].to_i

    if vote.value == new_value
      # 同じボタンを再度クリックした場合は投票を削除
      vote.destroy
    else
      # 新規投票または投票の変更
      vote.update(value: new_value)
    end

    redirect_back(fallback_location: root_path)
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