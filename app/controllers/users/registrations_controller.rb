# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
    before_action :configure_permitted_parameters, if: :devise_controller?

    def create
      # まず通常の登録を試みる
      super do |resource|
        # バリデーションエラーがある場合
        if resource.errors.any?
          # メールアドレスまたはユーザー名の重複エラーをチェック
          if resource.errors[:email].include?("はすでに使用されています") ||
             resource.errors[:name].include?("はすでに使用されています")

            # 未確認ユーザーがいれば削除して再試行
            email = params[:user][:email]
            name = params[:user][:name]

            unconfirmed_user = User.where("(email = ? OR name = ?) AND confirmed_at IS NULL", email, name).first

            if unconfirmed_user
              begin
                # 未確認ユーザーとその関連データを削除
                unconfirmed_user.destroy

                # エラーをクリアして再度保存を試みる
                resource.errors.clear
                resource.save
              rescue => e
                Rails.logger.error "未確認ユーザー削除エラー: #{e.message}"
              end
            end
          end
        end
      end
    end

    protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :bio])
    end

    def after_sign_up_path_for(resource)
      new_preference_path
    end
end
