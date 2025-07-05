require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @room = rooms(:one)
    sign_in @user
  end

  test "should create message" do
    assert_difference('Message.count') do
      post room_messages_url(@room), params: { message: { body: 'Test message' } }
    end

    assert_redirected_to room_url(@room)
  end
end
