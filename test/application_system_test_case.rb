require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [ 1400, 1400 ]
  Capybara.default_max_wait_time = 5 # 待機時間を5秒に設定

  def sign_in(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password" # users.yml のパスワードに合わせてください
    click_on "Log in"
  end
end
