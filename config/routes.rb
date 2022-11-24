Rails.application.routes.draw do
  namespace :api, format: "json" do
    namespace :v1 do
      post "/auth", to: "authentications#create"
      resources :posts, only: %i[index create update destroy]
    end
  end
end
