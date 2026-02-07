Rails.application.routes.draw do
   devise_for :users,
  controllers: { registrations: "users/registrations", sessions: "devise/sessions" },
  sign_out_via: [ :get, :delete ]

  resource :profile

  namespace :admin do
    resources :notifications, only: [ :index ]
  end
  # Intern Dashboard
  get "intern_dashboard", to: "intern_dashboard#index", as: "intern_dashboard"
  get "intern_dashboard/index"

   resources :social_task_proofs, only: [ :new, :create, :index, :show ]

namespace :admin do
  resources :notifications, only: [ :new, :create ]
  resources :social_task_proofs, only: [ :index, :show, :update ] do
    member do
      get :test_image
    end
  end
  resources :intern_task_completions, only: [ :index, :show, :update, :destroy ] do
    member do
      post :submit
      get :test_image
    end
  end
  resources :social_tasks, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    collection do
      get :sample_template
    end
  end
  resources :users, only: [ :index, :show, :destroy ] do
    collection do
      get :top_earners
    end
    member do
      patch :update_balance
      patch :toggle_dashboard_access
      patch :reset_intern
      patch :toggle_suspend
    end
  end

  # Intern Tasks Management
  resources :intern_tasks, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]

  get "referrals", to: "referrals#index", as: "referrals"


  get "reports/index"

  get "reports/user_clicks", to: "reports#user_clicks"
  get "reports/user_clicks.pdf", to: "reports#user_clicks", defaults: { format: :pdf }
 # get 'referrals', to: 'referrals#index', as: 'referrals'

 resources :clicks, only: [ :create ]
end

  resources :learn_and_earns do
     member do
    post :track_click
    post :approve
    post :reject
     end
     collection do
      post :bulk_create
      delete :bulk_delete
     end
  end

  resources :notifications do
    member do
      patch :mark_as_read
    end
    collection do
      post :create_global
    end
  end

  resources :contact_messages, only: [ :new, :create, :index, :show, :destroy ]

  # Intern Task Completions
  resources :intern_task_completions, only: [ :new, :create, :index, :show ] do
    member do
      post :submit
    end
  end

   resources :links do
    collection { post :import }
   end

  post "click_link/:id", to: "clicks#create", as: "click_link"
  get "click_window/:id", to: "links#click_window", as: :click_window

  resources :referrals, only: [ :index, :create ]

  resources :admin_dashbord, only: [ :index ]
  resources :user_dashbord, only: [ :index ]
  resources :profiles, only: [ :index ]

  resources :withdrawals do
    member do
      patch :update_status
    end
  end

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
    post :reject
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

   # Test route
   get "/test", to: "test#index"
end
