Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  } do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end
  
  # Public routes
  get "pricing" => "pricing#index", as: :pricing
  
  authenticated :user do
    root "home#index"
    get "dashboard" => "dashboard#index", as: :dashboard
    resources :knowledges, only: [:create, :show, :destroy] do
      member do
        post :retry
      end
    end
    
    # 사용자 설정 (이메일 기반 관리)
    resource :user_settings, only: [:show, :edit, :update] do
      post :send_verification_email
      get "verify_email/:token" => "user_settings#verify_email", as: :verify_email
    end
    
    # 결제 시스템
    resources :payments, only: [:new, :create] do
      collection do
        get 'success'
        get 'fail'
        post 'cancel'
      end
    end
  end
  
  # Unauthenticated root route
  unauthenticated do
    root "home#index", as: :unauthenticated_root
  end
  
  # Admin routes
  namespace :admin do
    get 'dashboard' => 'dashboard#index'
    get 'users' => 'dashboard#users'
    get 'knowledges' => 'dashboard#knowledges'
    get 'subscriptions' => 'dashboard#subscriptions'
    get 'analytics' => 'dashboard#analytics'
  end
  
  # API routes
  namespace :api do
    namespace :v1 do
      post "process_url" => "process_url#create"
    end
  end
  
  get "up" => "rails/health#show", as: :rails_health_check
end
