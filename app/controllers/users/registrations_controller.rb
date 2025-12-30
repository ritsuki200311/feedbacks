# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :destroy_unconfirmed_users, only: [:create]

    protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :bio])
    end

    def after_sign_up_path_for(resource)
      new_preference_path
    end

    private

    def destroy_unconfirmed_users
      # 同じメールアドレスまたはユーザー名で未確認のユーザーがいる場合は削除
      email = params.dig(:user, :email)
      name = params.dig(:user, :name)

      begin
        ActiveRecord::Base.transaction do
          if email.present?
            unconfirmed_by_email = User.where(email: email).where("confirmed_at IS NULL")
            unconfirmed_by_email.each do |user|
              # 関連データを完全に削除
              user.posts.each do |post|
                post.images.purge
                post.videos.purge
                post.audios.purge
                post.comments.destroy_all
                post.votes.destroy_all
                post.destroy
              end
              user.comments.destroy_all
              user.votes.destroy_all
              user.destroy
            end
          end

          if name.present?
            unconfirmed_by_name = User.where(name: name).where("confirmed_at IS NULL")
            unconfirmed_by_name.each do |user|
              # 関連データを完全に削除
              user.posts.each do |post|
                post.images.purge
                post.videos.purge
                post.audios.purge
                post.comments.destroy_all
                post.votes.destroy_all
                post.destroy
              end
              user.comments.destroy_all
              user.votes.destroy_all
              user.destroy
            end
          end
        end
      rescue => e
        # エラーが出ても登録は継続できるようにログに記録のみ
        Rails.logger.error "未確認ユーザー削除エラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
end
