Rails.application.routes.draw do
  devise_for :users

  resources :preferences, only: [ :new, :create, :edit, :update ]

  root 'home#index'
end
