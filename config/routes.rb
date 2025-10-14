Rails.application.routes.draw do
  
  
   resources :social_task_proofs, only: [:new, :create, :index, :show]

namespace :admin do
  resources :notifications, only: [:new, :create]
  resources :social_task_proofs, only: [:index, :show, :update]
  resources :users, only: [:index, :show]       # ← add this
  get 'referrals', to: 'referrals#index', as: 'referrals'
end


  get "user_dashbord/index"
  get "reports/index"
  get "profile/index"
  get "reports/user_clicks", to: "reports#user_clicks"
  get "reports/user_clicks.pdf", to: "reports#user_clicks", defaults: { format: :pdf }
  #get 'referrals', to: 'referrals#index', as: 'referrals'

  resources :withdrawals
 resources :clicks, only: [:create]

  resources :learn_and_earns do
     member do
    post :track_click
     end
  end

  resources :notifications, only: [:index,:destroy]

  resources :contact_messages, only: [:new, :create, :index, :show, :destroy]

   devise_for :users, 
  controllers: { registrations: 'users/registrations' }, 
  sign_out_via: [:get, :delete]

   resources :links do
    collection { post :import }
   end

  post "click_link/:id", to: "clicks#create", as: "click_link"
  get "click_window/:id", to: "links#click_window", as: :click_window
  

 


  resources :admin, only: [:index, :create, :edit, :update, :show, :destroy], controller: 'admin' do
  member do
    get :toggle_suspend
  patch :toggle_suspend
  
  end
end


resources :referrals, only: [:index, :create]


  resources :admin_dashbord, only: [:index]

 resources :welcome do
  collection do
    get :about
    get :service
    get :contact_us
    get :about_developer
  end
end

  

resources :tasks do

  member do
    get :send_to_all
  end
   resources :user_tasks, only: [:new, :create]
end


resources :user_tasks do
  member do
    post :approve
  end
end


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
   root "welcome#index"
end
