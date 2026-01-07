Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/login", to: "auth#login"
      post "auth/register", to: "auth#register"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      # Tenants
      resources :tenants, only: [ :index, :show, :create, :update ]

      # Parties (個人/法人)
      resources :parties, only: [ :index, :show, :create, :update, :destroy ]

      # Municipalities (自治体)
      resources :municipalities, only: [ :index, :show, :create ]

      # Fiscal Years (年度)
      resources :fiscal_years, only: [ :index, :show, :create ]

      # Properties (資産)
      resources :properties, only: [ :index, :show, :create, :update, :destroy ] do
        resources :land_parcels, only: [ :index, :create, :update, :destroy ]
      end

      # Fixed Assets (固定資産)
      resources :fixed_assets, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          post :calculate_depreciation
        end
        resources :depreciation_years, only: [ :index, :show ]
      end

      # Asset Valuations (資産評価)
      resources :asset_valuations, only: [ :index, :show, :create, :update ]

      # Tax Calculations
      resources :calculation_runs, only: [ :index, :show, :create ] do
        member do
          post :execute
        end
        resources :calculation_results, only: [ :index ]
      end

      # Asset Classifications (勘定科目・資産分類マスタ)
      resources :asset_classifications, only: [ :index ] do
        collection do
          get :account_items
          get :useful_life
        end
      end

      # Corporate Tax Schedules (法人別表十六)
      resources :corporate_tax_schedules do
        member do
          post :generate
          post :finalize
          get :export_csv
        end
        collection do
          post :generate_all
        end
      end
    end
  end

  # Serve frontend application for all non-API routes
  get "*path", to: "frontend#index", constraints: ->(req) {
    !req.path.start_with?("/api") &&
    !req.path.start_with?("/rails") &&
    !req.path.start_with?("/assets") &&
    !req.path.match?(/\.(js|css|svg|png|jpg|jpeg|gif|ico|woff|woff2|ttf|eot)$/)
  }
  root "frontend#index"
end
