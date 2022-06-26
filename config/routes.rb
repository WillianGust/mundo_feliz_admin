Rails.application.routes.draw do
  
  resources :administradors
  resources :pedidos do 
    resources :pedido_produtos
  end
  resources :clientes
  resources :produtos
  resources :tipo_produtos
  
  get '/admin', to: 'admin#index'
  get '/login', to: 'login#index'
  post '/login/logar', to: 'login#logar'
  get '/login/sair', to: 'login#sair'
  get '/home', to: 'home#index'

  get '/produto/:produto_id', to: 'produto#index'
  
  root to: 'home#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
  