Rails.application.routes.draw do
  get "received_videos/index"
  # ホーム
  root "home#index"

  # Devise（ユーザー認証）
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # この順番が大事！
  get "users/mypage", to: "users#mypage", as: :mypage
  resources :users, only: [:show]
  get "users/index"

  # プロフィール（シングルリソースでルーティング）
  resource :supporter_profile, only: [:new, :create, :show, :edit, :update]

  # 投稿とコメント
  resources :posts, only: [:new, :create, :show, :destroy] do
    resources :comments, only: [:create]
  end

  # 投稿検索
  get "posts/search", to: "posts#search", as: :search_posts

  # DM機能
  resources :rooms, only: [:create, :show] do
    resources :messages, only: [:create]
  end

  # 好み設定（Preference）
  resource :preference, controller: 'preferences', only: [:new, :create, :edit, :update]

  # ヘルスチェック（開発用）
  get "up", to: "rails/health#show", as: :rails_health_check

  # LetterOpenerWeb（開発環境のみ）
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # 管理者
  namespace :admin do
    resources :users, only: [:index]
  end
end