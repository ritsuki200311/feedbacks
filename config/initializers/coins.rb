Rails.application.config.x.coin = ActiveSupport::InheritableOptions.new(
  post_cost: ENV.fetch('POST_COST', 1).to_i,
  comment_reward: ENV.fetch('COMMENT_REWARD', 1).to_i
)