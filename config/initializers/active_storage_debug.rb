# config/initializers/active_storage_debug.rb
# Active Storageのvariant処理のデバッグログを有効にする

ActiveSupport::Notifications.subscribe "process.active_storage" do |name, start, finish, id, payload|
  Rails.logger.debug "Active Storage Process: #{payload.inspect}"
end

ActiveSupport::Notifications.subscribe "transform.active_storage" do |name, start, finish, id, payload|
  Rails.logger.debug "Active Storage Transform: #{payload.inspect}"
end

# image_processing のログを有効にする (MiniMagick または Vips の詳細ログ)
# MiniMagick の場合
require 'mini_magick'
MiniMagick.logger.level = Logger::DEBUG

# Ruby-Vips の場合
# require 'vips'
# Vips.logger.level = Logger::DEBUG
