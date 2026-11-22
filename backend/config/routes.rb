Rails.application.routes.draw do
  namespace :api do
    resource :session, only: %i[ show create destroy ]

    resources :countries, only: :index
    resources :departments, only: :index
    resources :job_titles, only: :index
    resources :employees, only: %i[ index show create update ] do
      resources :salary_revisions, only: :create
      resources :assignments, only: :create
    end

    namespace :insights do
      resources :countries, only: %i[ index show ]
      resource :summary, only: :show
    end

    # Last inside /api: an unknown API path is a JSON 404, never the React app.
    match "", to: "not_found#show", via: :all
    match "*path", to: "not_found#show", via: :all, format: false
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Last of all: any other GET is a page of the React app (FrontendController).
  # /api and /rails (Rails' own routes, like Active Storage) are never pages.
  root "frontend#index"
  get "*path", to: "frontend#index", format: false,
               constraints: ->(request) { !request.path.match?(%r{\A/(api|rails)(/|\z)}) }

  # Defines the root path route ("/")
  # root "posts#index"
end
