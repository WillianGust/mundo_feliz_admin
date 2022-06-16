Rails.application.routes.draw do
  
  resources :administradors
  resources :pedidos do 
    resources :pedido_produtos
  end
  resources :clientes
  resources :tipo_produtos
  resources :produtos
  root to: 'home#index'
  get '/home', to: 'home#index'
  get 'home/index'
  get '/login', to: 'login#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
