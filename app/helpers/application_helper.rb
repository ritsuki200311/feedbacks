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
end
