require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get room_url(rooms(:one))
    assert_response :found
  end

  test "should create room" do
    post rooms_url, params: { user_id: users(:two).id }
    assert_response :found
  end
end
