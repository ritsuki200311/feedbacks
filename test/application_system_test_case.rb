require "test_helper"
require "securerandom"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: {
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new.tap do |opts|
      opts.add_argument("--headless")
      opts.add_argument("--disable-gpu")
      opts.add_argument("--no-sandbox")
      opts.add_argument("--disable-dev-shm-usage")
      opts.add_argument("--window-size=1400,1400")
      opts.add_argument("--user-data-dir=/tmp/chrome-user-data-#{Process.pid}")
    end
  }

  Capybara.default_max_wait_time = 5

  def sign_in(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_on "Log in"
    assert_text user.email # ログイン成功を検証
  end
end
