class ProdutoController < ApplicationController
  skip_before_action :valida_logado_admin
  layout "site"
  
  def index
    @produto = Produto.find(params[:produto_id])
  end
end