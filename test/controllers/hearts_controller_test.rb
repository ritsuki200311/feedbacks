require "test_helper"

class HeartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post_owner = users(:one)
    @commenter = users(:two)
    @comment = comments(:one)
    @post = @comment.post
    @post.update!(user: @post_owner) # 投稿者を設定
    @comment.update!(user: @commenter) # コメント者を別ユーザーに設定
  end

  test "should toggle heart when authorized" do
    sign_in @post_owner
    post toggle_heart_path, params: { comment_id: @comment.id }
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert response_data["success"]
  end

  test "should return unauthorized for non-post-owner" do
    sign_in @commenter
    post toggle_heart_path, params: { comment_id: @comment.id }
    assert_response :forbidden
  end
end
