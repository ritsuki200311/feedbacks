require "test_helper"

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    # user_one has a preference, user_two does not.
    @preference = preferences(:one)
    @user_one.preference = @preference
  end

  test "should get new for user without preference" do
    sign_in @user_two
    get new_preference_url
    assert_response :success
  end

  test "should redirect new for user with preference" do
    sign_in @user_one
    get new_preference_url
    assert_redirected_to edit_preference_url
  end

  test "should create preference" do
    sign_in @user_two
    assert_difference("Preference.count") do
      post preference_path, params: { preference: { genre: "Rock", instrument_experience: "Guitar", favorite_artist: "Artist", career: "Hobby" } }
    end

    assert_redirected_to mypage_url
  end
end
