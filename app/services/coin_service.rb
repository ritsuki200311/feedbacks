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

    if user.coins < cost
      # コイン不足の場合はエラーを発生させる
      post.errors.add(:base, "コインが不足しています。")
      return false
    end

    user.update(coins: user.coins - cost) # decrement! ではなく update を使用
    true
  end
end
