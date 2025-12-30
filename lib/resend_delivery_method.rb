require 'resend'

class ResendDeliveryMethod
  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    params = {
      from: mail.from.first,
      to: mail.to,
      subject: mail.subject,
      html: mail.html_part&.body&.decoded || mail.body.decoded
    }

    # テキストパートがあれば追加
    if mail.text_part
      params[:text] = mail.text_part.body.decoded
    end

    # Resend APIでメール送信
    Resend::Emails.send(params)
  end
end

# ActionMailerに登録
ActionMailer::Base.add_delivery_method :resend, ResendDeliveryMethod
