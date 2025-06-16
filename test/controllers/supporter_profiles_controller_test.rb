require "test_helper"

class SupporterProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get supporter_profiles_new_url
    assert_response :success
  end

  test "should get create" do
    get supporter_profiles_create_url
    assert_response :success
  end

  test "should get edit" do
    get supporter_profiles_edit_url
    assert_response :success
  end

  test "should get update" do
    get supporter_profiles_update_url
    assert_response :success
  end
end
