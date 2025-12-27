class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :votable, polymorphic: true

  validates :user_id, uniqueness: { scope: [ :votable_type, :votable_id ] }
  validates :value, inclusion: { in: [ -1, 1 ] }

  after_create :update_trust_score
  after_destroy :revert_trust_score

  private

  def update_trust_score
    return unless votable_type == "Comment" && votable.user.present?

    if value == 1
      votable.user.increment_trust_score(0.05)
    elsif value == -1
      votable.user.decrement_trust_score(0.02)
    end
  end

  def revert_trust_score
    return unless votable_type == "Comment" && votable.user.present?

    if value == 1
      votable.user.decrement_trust_score(0.05)
    elsif value == -1
      votable.user.increment_trust_score(0.02)
    end
  end
end
