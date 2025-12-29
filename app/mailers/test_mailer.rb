class TestMailer < ApplicationMailer
  def test_message(email)
    mail(
      to: email,
      subject: "Resend テストメール"
    ) do |format|
      format.text { render plain: "これはResendのテストメールです。\n\nメール送信が正常に動作しています。" }
    end
  end
end
