require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  test "should create message" do
    post room_messages_url(rooms(:one)), params: { message: { body: "hello" } }
    assert_response :found
  end
end
