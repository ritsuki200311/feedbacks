require "test_helper"

class ReceivedVideosControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get received_videos_index_url
    assert_response :success
  end
end
