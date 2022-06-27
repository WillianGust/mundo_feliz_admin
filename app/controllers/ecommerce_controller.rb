class EcommerceController < ApplicationController
  skip_before_action :valida_logado_admin
  layout "site"
  
  def index
    @produto = Produto.find(params[:produto_id])
  end

  def adicionar
    if cookies[:carrinho].present?
      produtos = JSON.parse(cookies[:carrinho]);
    else
      produtos = []
    end
      produtos << params[:produto_id]
      produtos.uniq!
      cookies[:carrinho] = { value: produtos.to_json, expires: 1.year.from_now, httponly: true }
      redirect_to "/"
  end

  def remover
    if cookies[:carrinho].blank?
      redirect_to "/"
      return
    end
      produtos = JSON.parse(cookies[:carrinho]);
      produtos.delete(params[:produto_id])
      cookies[:carrinho] = { value: produtos.to_json, expires: 1.year.from_now, httponly: true }

      redirect_to "/carrinho"
  end

  def carrinho
    if cookies[:carrinho].blank?
      redirect_to "/"
      return
    end
      produtos = JSON.parse(cookies[:carrinho]);
      @produtos = Produto.where(id: produtos)
  end

  def fechar_carrinho
    if cookies[:cliente_login].blank?
      redirect_to "/cliente/logar"
      return
    end
  end

  def login 
  end
  
  def cadastrar 
    @cliente = Cliente.new
  end

  def cadastrar_cliente
    @cliente = Cliente.new(cliente_params)
      if @cliente.save
        cookies[:cliente_login] = { 
          value: {
          id: @cliente.id,
          nome: @cliente.nome,
          email: @cliente.email
        }, 
        expires: 1.year.from_now, httponly: true }
        redirect_to "/carrinho/fechar" 
      else 
        render :cadastrar
      end
  end

  private 
    # Only allow a list of trusted parameters through.
    def cliente_params
      params.require(:cliente).permit(:nome, :cpf, :telefone, :email, :cep, :endereco, :numero, :bairro, :cidade, :estado, :senha)
    end
end