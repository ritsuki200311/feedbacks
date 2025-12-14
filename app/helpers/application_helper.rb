module ApplicationHelper
  def sidebar_link_class(path)
    base_class = "px-4 py-2 rounded"
    if current_page?(path)
      "bg-blue-500 text-white #{base_class}"
    else
      "text-gray-700 hover:bg-gray-100 #{base_class}"
    end
  end

  def show_sensitive_info?
    Rails.env.development?
  end

  def user_can_view_comments?(user, post)
    return false unless user
    return true if user == post.user

    has_voted = post.votes.exists?(user: user)
    has_commented = post.comments.exists?(user: user)

    has_voted || has_commented
  end

  # 信用度スコアを星で表示
  def trust_score_stars(score)
    full_stars = score.floor
    has_half = (score - full_stars) >= 0.5
    empty_stars = 5 - full_stars - (has_half ? 1 : 0)

    html = ""
    full_stars.times { html += "⭐" }
    html += "✨" if has_half
    empty_stars.times { html += "☆" }

    raw "#{html} <span class=\"text-xs text-gray-600\">(#{score.round(1)})</span>"
  end
end
