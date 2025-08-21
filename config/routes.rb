Rails.application.routes.draw do
  # ホーム
  root "home#index"

  # Devise（ユーザー認証）
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  # この順番が大事！
  get "users/mypage", to: "users#mypage", as: :mypage
  # ユーザー関係性の可視化（usersリソースより前に配置）
  get "users/relationships", to: "user_relationships#index", as: :user_relationships
  resources :users, only: [ :show ]
  get "users/index"



  # プロフィール（シングルリソースでルーティング）
  resource :supporter_profile, only: [ :new, :create, :show, :edit, :update ]

  # 投稿検索（postsリソースの前に配置）
  get "posts/search", to: "posts#search", as: :search_posts
  
  # 作品マップ（postsリソースの前に配置）
  get "posts/map", to: "posts#map", as: :posts_map

  # 投稿とコメント
  resources :posts, only: [ :new, :create, :show, :destroy ] do
    resources :comments, only: [ :index, :create ]
    # AI comment assistant
    post 'ai_comment_assistant/analyze', to: 'ai_comment_assistant#analyze_post'
  end

  # 投票機能
  post "vote", to: "votes#vote"


  # DM機能
  resources :rooms, only: [ :create, :show ] do
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

  # 管理者
  namespace :admin do
    resources :users, only: [ :index ] do
      member do
        post :add_coins
        post :remove_coins
      end
    end
  end
end
