class CoinService
  def self.reward_for_comment(comment)
    # コメント投稿者にコインを付与
    # 投稿者がコメントをした場合はコインを付与しない
    if comment.post.user != comment.user
      reward = Rails.application.config.x.coin.comment_reward
      comment.user.update(coins: comment.user.coins + reward) # update! ではなく update を使用
    end
  end

  def self.deduct_for_post(post)
    cost = Rails.application.config.x.coin.post_cost
    user = post.user

    Rails.logger.debug "=== CoinService.deduct_for_post ==="
    Rails.logger.debug "User coins: #{user.coins}, Post cost: #{cost}"

    if user.coins < cost
      # コイン不足の場合はエラーを発生させる
      error_message = "コインが不足しています。（必要: #{cost}コイン、保有: #{user.coins}コイン）"
      post.errors.add(:base, error_message)
      Rails.logger.debug "Coin shortage: #{error_message}"
      return false
    end

    user.update(coins: user.coins - cost) # decrement! ではなく update を使用
    Rails.logger.debug "Coins deducted successfully. New balance: #{user.reload.coins}"
    true
  end
end
