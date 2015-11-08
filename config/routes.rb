Rails.application.routes.draw do
  resources :profiles

  root 'profiles#index'
end
