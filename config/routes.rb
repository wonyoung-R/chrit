Rails.application.routes.draw do
  devise_for :users
  
  # Public routes
  get "pricing" => "pricing#index", as: :pricing
  
  authenticated :user do
    root "home#index", as: :authenticated_root
    get "dashboard" => "dashboard#index", as: :dashboard
    resources :knowledges, only: [:create, :show] do
      member do
        post :retry
      end
    end
  end
  
  # API routes
  namespace :api do
    namespace :v1 do
      post "process_url" => "process_url#create"
    end
  end
  
  root "home#index"
  
  get "up" => "rails/health#show", as: :rails_health_check
end
