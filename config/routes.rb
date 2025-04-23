Rails.application.routes.draw do
  # 投稿のルートを生成
  resources :posts, only: [:create, :show, :new, :destroy] do
    # 投稿に関連するコメントのルート
    resources :comments, only: [:create]
  end

  # ルートページ
  root "home#index"

  # ユーザー認証（Devise）
  devise_for :users

  # ユーザー関連のルート（必要な場合）
  get "users/index"

  # マイページ（あとで作る）
  get "users/mypage", to: "users#mypage", as: :mypage

  # 投稿検索（あとで作る）
  get "posts/search", to: "posts#search", as: :search_posts

  # ヘルスチェック用ルート
  get "up" => "rails/health#show", as: :rails_health_check

  # メール系
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end