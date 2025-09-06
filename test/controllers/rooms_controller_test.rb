require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    sign_in @user_one
  end

  test "should show room" do
    # テスト用に新しいルームを作成
    room = Room.create
    Entry.create(user: @user_one, room: room)
    Entry.create(user: @user_two, room: room)

    get room_url(room)
    assert_response :success
  end

  test "should create room and redirect to existing room if it exists" do
    # users(:one)とusers(:two)の間に既存のルームがあることを確認
    existing_room = Room.joins(:entries).where(entries: { user_id: [ @user_one.id, @user_two.id ] }).group("rooms.id").having("COUNT(rooms.id) = 2").first

    if existing_room
      # 既存のルームがある場合は、新しいルームが作成されずに既存のルームにリダイレクトされることを期待
      assert_no_difference("Room.count") do
        post rooms_url, params: { user_id: @user_two.id }
      end
      assert_redirected_to room_url(existing_room)
    else
      # 既存のルームがない場合は、新しいルームが作成されることを期待
      assert_difference("Room.count") do
        post rooms_url, params: { user_id: @user_two.id }
      end
      assert_redirected_to room_url(Room.last)
    end
  end
end
