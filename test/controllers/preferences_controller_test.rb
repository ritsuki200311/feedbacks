require "test_helper"

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_preference_url
    assert_response :found
  end

  test "should get create" do
    post preference_url, params: { preference: { genre: "Rock" } }
    assert_response :found
  end
end
