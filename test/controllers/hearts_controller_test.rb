require "test_helper"

class HeartsControllerTest < ActionDispatch::IntegrationTest
  test "should get toggle" do
    get hearts_toggle_url
    assert_response :success
  end
end
