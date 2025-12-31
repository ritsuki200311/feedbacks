Rails.application.routes.draw do
  # ホーム
  root "home#index"

  # Devise（ユーザー認証）
  devise_for :users, controllers: {
    registrations: "users/registrations",
    confirmations: "users/confirmations"
  }

  # この順番が大事！- Deviseルートを保護するため
  get "users/mypage", to: "users#mypage", as: :mypage
  patch "users/update", to: "users#update", as: :update_user
  get "users/index"
  # ユーザー関係性の可視化（usersリソースより前に配置）
  get "users/relationships", to: "user_relationships#index", as: :user_relationships

  # ユーザープロフィール表示（Deviseと競合を避けるため）
  get "users/:id", to: "users#show", as: :user, constraints: { id: /\d+/ }
  get "users/:id/followers", to: "users#followers", as: :user_followers, constraints: { id: /\d+/ }
  get "users/:id/following", to: "users#following", as: :user_following, constraints: { id: /\d+/ }
  post "users/:id/follows", to: "follows#create", as: :user_follows
  delete "users/:id/follows", to: "follows#destroy", as: :destroy_user_follows



  # プロフィール（作成・編集・一覧・検索）
  resources :supporter_profiles, only: [ :index, :new, :create, :edit, :update ]

  # 検索（postsリソースの前に配置）
  get "search", to: "posts#search", as: :search
  get "search_simple", to: "posts#search_simple", as: :search_simple
  get "search_debug", to: "posts#search", as: :search_debug

  # 作品マップ（postsリソースの前に配置）
  get "posts/map", to: "posts#map", as: :posts_map

  # 投稿とコメント
  resources :posts, only: [ :new, :create, :show, :destroy ] do
    resources :comments, only: [ :index, :create ]
    # AI comment assistant
    post "ai_comment_assistant/analyze", to: "ai_comment_assistant#analyze_post"
    # ユーザー選択画面（メンバールート - 既存投稿用）
    get "select_recipient", to: "posts#select_recipient"
    post "send_to_user", to: "posts#send_to_user"
    get "match_users", to: "posts#match_users"

    # コレクションルート - セッションベース（投稿前）用
    collection do
      get "select_recipient", to: "posts#select_recipient", as: "select_recipient_collection"
      post "send_to_user", to: "posts#send_to_user", as: "send_to_user_collection"
    end
  end

  # 投票機能
  post "vote", to: "votes#vote"

  # ハート機能
  post "toggle_heart", to: "hearts#toggle"


  # DM機能
  resources :rooms, only: [ :index, :create, :show ] do
    resources :messages, only: [ :create ]
  end

  # コミュニティ機能
  resources :communities do
    member do
      post :join
      delete :leave
    end
  end

  # 好み設定（Preference）
  resource :preference, controller: "preferences", only: [ :new, :create, :edit, :update ]

  # ヘルスチェック（開発用）
  get "up", to: "rails/health#show", as: :rails_health_check

  # LetterOpenerWeb（開発環境のみ）
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # 管理者（開発環境のみ）
  # 管理者用リセット機能（本番環境でも使用可能、トークン認証必須）
  namespace :admin do
    get "reset_users", to: "reset#reset_users"
    get "delete_all_posts", to: "reset#delete_all_posts"
    get "reset_all_coins_to_three", to: "reset#reset_all_coins_to_three"
    get "test_email", to: "reset#test_email"
  end

  if Rails.env.development?
    namespace :admin do
      resources :users, only: [ :index ] do
        member do
          post :add_coins
          post :remove_coins
        end
      end
    end
  end
end
