Rails.application.routes.draw do
   resources :social_task_proofs, only: [ :new, :create, :index, :show ]

namespace :admin do
  resources :notifications, only: [ :new, :create ]
  resources :social_task_proofs, only: [ :index, :show, :update ]
  resources :social_tasks, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    collection do
      get :sample_template
    end
  end
  resources :users, only: [ :index, :show ]       # ← add this
  get "referrals", to: "referrals#index", as: "referrals"
end


  get "user_dashbord/index"
  get "reports/index"
  get "profile/index"
  get "reports/user_clicks", to: "reports#user_clicks"
  get "reports/user_clicks.pdf", to: "reports#user_clicks", defaults: { format: :pdf }
  # get 'referrals', to: 'referrals#index', as: 'referrals'

  resources :withdrawals do
    member do
      patch :update_status
    end
  end
 resources :clicks, only: [ :create ]

  resources :learn_and_earns do
     member do
    post :track_click
    post :approve
    post :reject
     end
     collection do
      post :bulk_create
     end
  end

  resources :notifications, only: [ :index, :destroy ]

  resources :contact_messages, only: [ :new, :create, :index, :show, :destroy ]

   devise_for :users,
  controllers: { registrations: "users/registrations" },
  sign_out_via: [ :get, :delete ]

   resources :links do
    collection { post :import }
   end

  post "click_link/:id", to: "clicks#create", as: "click_link"
  get "click_window/:id", to: "links#click_window", as: :click_window





  resources :admin, only: [ :index, :create, :edit, :update, :show, :destroy ], controller: "admin" do
  member do
    get :toggle_suspend
    patch :toggle_suspend
    patch :update_balance
  end
end


resources :referrals, only: [ :index, :create ]


  resources :admin_dashbord, only: [ :index ]

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
    post :send_to_all
  end
  collection do
    get :sample_template
  end
   resources :user_tasks, only: [ :new, :create ]
end


resources :user_tasks do
  member do
    post :approve
  end
end


resources :short_links, only: [ :create, :index ]

  get "/s/:slug", to: "short_links#redirect", as: :short_redirect

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Analytics routes
  namespace :analytics do
    get :dashboard, to: "analytics#dashboard"
    get :user_analytics, to: "analytics#user_analytics"
    get :financial_analytics, to: "analytics#financial_analytics"
    get :task_analytics, to: "analytics#task_analytics"
    get :referral_analytics, to: "analytics#referral_analytics"
  end
  
  # Marketing routes
  namespace :marketing do
    get :dashboard, to: "marketing#dashboard"
    get :promotional_codes, to: "marketing#promotional_codes"
    post :create_promotional_code, to: "marketing#create_promotional_code"
    get :achievements, to: "marketing#achievements"
    post :create_achievement, to: "marketing#create_achievement"
    get :email_campaigns, to: "marketing#email_campaigns"
    post :create_email_campaign, to: "marketing#create_email_campaign"
    get :affiliate_programs, to: "marketing#affiliate_programs"
    post :create_affiliate_program, to: "marketing#create_affiliate_program"
    get :reports, to: "marketing#marketing_reports"
  end
  
  # Payment routes
  namespace :payment do
    get :dashboard, to: "payment#dashboard"
    get :gateways, to: "payment#payment_gateways"
    post :create_gateway, to: "payment#create_payment_gateway"
    get :plans, to: "payment#subscription_plans"
    post :create_plan, to: "payment#create_subscription_plan"
    post :process_payment, to: "payment#process_user_payment"
    get :history, to: "payment#payment_history"
    get :subscription_management, to: "payment#subscription_management"
    post :subscribe, to: "payment#subscribe_to_plan"
    post :cancel_subscription, to: "payment#cancel_subscription"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

   # Defines the root path route ("/")
   root "welcome#index"
end
