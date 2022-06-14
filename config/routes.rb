Rails.application.routes.draw do
  resources :tipo_produtos
  resources :produtos
  root to: 'home#index'
  get '/home', to: 'home#index'
  get 'home/index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
