Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      resources :books, only: [ :index, :create, :show ] do
        collection do
          get :search
        end
      end

      resources :reviews, only: [ :create ]
    end
  end

  # Root route for React SPA
  root "application#index"

  # Catch all for React SPA - must be last
  get "*path", to: "application#index", constraints: ->(request) do
    !request.xhr? && request.format.html?
  end
end
