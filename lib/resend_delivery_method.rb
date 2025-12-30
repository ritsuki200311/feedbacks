require 'resend'

class ResendDeliveryMethod
  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    # メールがマルチパート（HTML + テキスト）の場合
    if mail.multipart?
      html_body = mail.html_part&.body&.decoded
      text_body = mail.text_part&.body&.decoded
    else
      # シングルパートの場合
      if mail.content_type&.include?('text/html')
        html_body = mail.body.decoded
        text_body = nil
      else
        html_body = nil
        text_body = mail.body.decoded
      end
    end

    params = {
      from: mail.from.first,
      to: mail.to,
      subject: mail.subject
    }

    # HTMLパートがあれば追加
    params[:html] = html_body if html_body.present?

    # テキストパートがあれば追加
    params[:text] = text_body if text_body.present?

    # Resend APIでメール送信
    Resend::Emails.send(params)
  end
end

# ActionMailerに登録
ActionMailer::Base.add_delivery_method :resend, ResendDeliveryMethod
