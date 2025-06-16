Rails.application.routes.draw do
  get "supporter_profiles/new"
  get "supporter_profiles/create"
  get "supporter_profiles/edit"
  get "supporter_profiles/update"
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

  # 好みの設定（シングルリソースとして定義）
  resource :preference, controller: 'preferences', only: [:new, :create, :edit, :update]

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

  # 管理者用ルーティング
  namespace :admin do
    resources :users, only: [:index]
  end

  resources :supporter_profiles, only: [:new, :create, :edit, :update]

end