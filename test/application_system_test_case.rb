require "test_helper"
require "securerandom"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [ 1400, 1400 ], options: {
<<<<<<< Updated upstream
    capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(
      "goog:chromeOptions" => {
        "args" => [
          "headless",
          "disable-gpu",
          "no-sandbox",
          "window-size=1400,1400",
          "disable-dev-shm-usage",
          "user-data-dir=/tmp/chrome-user-data-#{Process.pid}"
        ]
      }
    )
=======
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new.tap do |opts|
      opts.add_argument("--headless")
      opts.add_argument("--disable-gpu")
      opts.add_argument("--no-sandbox")
      opts.add_argument("--disable-dev-shm-usage")
      opts.add_argument("--window-size=1400,1400")
      opts.add_argument("--user-data-dir=/tmp/chrome-user-data-#{Process.pid}")
    end
>>>>>>> Stashed changes
  }
  Capybara.default_max_wait_time = 5

  def sign_in(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_on "Log in"
  end
end
