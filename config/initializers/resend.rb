# Resend APIの設定
if ENV['RESEND_API_KEY'].present?
  Resend.api_key = ENV['RESEND_API_KEY']
end
