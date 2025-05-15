Rails.application.routes.draw do
  get "preferences/new"
  get "preferences/create"
  # DM機能のルート（新規作成・表示）
  resources :rooms, only: [:create, :show] do
    resources :messages, only: [:create]
  end

  # 投稿のルートを生成
  resources :posts, only: [:create, :show, :new, :destroy] do
    # 投稿に関連するコメントのルート
    resources :comments, only: [:create]
  end

  # ルートページ
  root "home#index"

  # ユーザー認証（Devise）
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }  

  # ユーザー関連のルート
  get "users/index"
  get "users/mypage", to: "users#mypage", as: :mypage
  resources :users, only: [:show]

  # 投稿検索
  get "posts/search", to: "posts#search", as: :search_posts

  # ヘルスチェック用ルート
  get "up" => "rails/health#show", as: :rails_health_check

  # メール系
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  #　登録直後の好みのジャンル
  resources :preferences, only: [:new, :create]

end