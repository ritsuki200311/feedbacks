require "test_helper"

class SupporterProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @supporter_profile = supporter_profiles(:one)
    @user_one.supporter_profile = @supporter_profile
  end

  test "should get new for user without profile" do
    sign_in @user_two
    get new_supporter_profile_url
    assert_response :success
  end

  test "should redirect new for user with profile" do
    sign_in @user_one
    get new_supporter_profile_url
    assert_redirected_to edit_supporter_profile_url(@supporter_profile)
  end

  test "should create supporter_profile" do
    sign_in @user_two
    assert_difference('SupporterProfile.count') do
      post supporter_profile_path, params: { supporter_profile: { standing: 'Fan', creation_experience: 'None', interests: 'Music', favorite_artists: 'Artist', age_group: '20s', support_genres: 'Pop', support_styles: 'Comments', personality_traits: 'Friendly' } }
    end

    assert_redirected_to mypage_url
  end

  test "should get edit" do
    sign_in @user_one
    get edit_supporter_profile_url(@supporter_profile)
    assert_response :success
  end

  test "should update supporter_profile" do
    sign_in @user_one
    patch supporter_profile_url(@supporter_profile), params: { supporter_profile: { standing: 'Creator' } }
    assert_redirected_to mypage_url
  end
end
