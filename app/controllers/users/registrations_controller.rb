# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
    protected

    def after_sign_up_path_for(resource)
      new_preference_path
    end
end
