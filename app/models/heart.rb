class Heart < ApplicationRecord
  belongs_to :user
  belongs_to :comment

  # 同じユーザーが同じコメントに複数回ハートできないようにする
  validates :user_id, uniqueness: { scope: :comment_id }
end
