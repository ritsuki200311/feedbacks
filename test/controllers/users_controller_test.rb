require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end
  test "should get mypage" do
    get mypage_url
    assert_response :success
  end
end
