Rails.application.routes.draw do
  namespace :api, format: "json" do
    namespace :v1 do
      get "/users/create", to: "users#create"
      resources :posts, only: %i[index create update delete]
    end
  end
end
