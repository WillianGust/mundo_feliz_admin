class EcommerceController < ApplicationController
  skip_before_action :valida_logado_admin
  skip_before_action :verify_authenticity_token
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

  def concluir_pagamento
    
    Iugu.api_key = "86f80a44f1e5e609be8529f017f0470e"
      
    cliente = Cliente.find(params[:cliente_id])
    
    if cliente.iugu_customer_id.blank?
      customer = Iugu::Customer.create({
        email: cliente.email,
        name: cliente.nome,
        notes: "Cartao para ser usado em compras, email #{cliente.email}"
      })
      begin
        cliente.iugu_customer_id = customer.id
        cliente.save!
      rescue
        raise "Problema ao transacionar o cartao, por favor entre em contato com suporte"
      end
    else
      customer = Iugu::Customer.fetch(cliente.iugu_customer_id)
    end

      if params[:token].present?
        debugger
        # A veificar ID
        payment_method = Iugu::PaymentMethod.create({
          description: "Cartao #{cliente.nome} - #{cliente.email}",
          token: params[:token]
        })
      else
        payment_method = nil
      end

      produtos_id = JSON.parse(cookies[:carrinho]);
      produtos = Produto.where(id: produtos_id)

      valor = produtos.sum(:valor)

      valor = valor.gsub(",", ".").to_f if valor.is_a?(String)
      valor_centavos = (valor *100).to_i
      months = 1 

      itens_pedido_iugu = []

      produtos.each do |produto|
        itens_pedido_iugu << {
            "description" => produto.descricao,
            "quantity" => "1",
            "price_cents" => (produto.valor *100).to_i 
          } 
      end

      options = {
        "email" => cliente.email,
        "months" => months,
        "itens" => itens_pedido_iugu
      }

      if payment_method.present?
        options["customer_payment_method_id"] = payment_method.id
        else 
          cliente.telefone = params[:telefone]
          cliente.email = params[:email]
          clinte.cep = params[:cep]
          cliente.endereco = params[:endereco]
          cliente.numero = params[:numero]
          cliente.bairro = params[:bairro]
          cliente.cidade = params[:cidade]
          cliente.estado = params[:estado]
          cliente.save

          begin
            options["method"] = "bank_slip"
            options["payer"] = {
              "cpf_cnpj" => cliente.cpf.gsub("-", "").gsub(".",""),
              "name" => cliente.nome,
              "phone_prefix" => cliente.telefone[1,2],
              "phone" => cliente.telefone[4,20].gsub("-", ""),
              "email" => cliente.email,
              "address" => {
                "street" =>cliente.endereco,
                "number" => cliente.numero,
                "city" => cliente.cidade,
                "district" => cliente.cidade,
                "state" => cliente.estado,
                "country" => "Brasil",
                "zip_code" => cliente.cep
              }
            }
            rescue Exception => erro
              puts "========="
              puts "====#{erro.message}====="
              puts "========="
              puts "====#{erro.backtrace }====="
              puts "========="
              raise "Endereco, cpf_cnpj ou telefone nao localizado para pagamento com boleto"
            end
        end

    
    payment_return = Iugu::Charge.create(options)

    if payment_return.errors.present?
      begin
        mensagem = payment_return.errors.map{|k,v| "#{k}: #{v.join(",")}"}.join(", ")
        rescue
          mensagem = payment_return.errors.inspect rescue "Erro ao fazer pagamento, tente novamente mais tarde"
        end
        raise mensagem
      else
        if payment_return.respond_to?(:LR)
          if payment_return.LR != "00"
            raise payment_return.message
          end
        else
          if payment_return.respond_to?(:identification) && payment_return.respond_to?(:success) #falta colocar um payment_return nao sei o que
            boleto = true
          else
            raise payment_return.message
          end
        end
      end

      pedido = Pedido.new
      # transacao_id = payment_return.invoice_id
      pedido.cliente = cliente
      pedido.valor_total = valor
      pedido.transacao_id = payment_return.invoice_id
      if payment_method.blank?
        pedido.numero_boleto = payment_return.identification
        pedido.pdf_boleto = payment_return.pdf
        pedido.status = "Aguardando"
      else
        pedido.status = "Pago"

      end

      pedido.save

      produtos.each do |produto|
        pedido_produto = PedidoProduto.new
        pedido_produto.pedido = produto
        pedido_produto.pedido = pedido
        pedido_produto.valor = produto.valor
        quantidade = 1
        pedido_produto.save
      end

      
      cookies[:numero_boleto] = { value: payment_return.identification, expires: 1.hour.from_now, httponly: true }
      cookies[:pedido_id] = { value: pedido.id, expires: 1.hour.from_now, httponly: true }
      cookies[:valor] = { value: valor.round(2), expires: 1.hour.from_now, httponly: true }
      cookies[:comprovante] = { value: payment_return.pdf, expires: 1.hour.from_now, httponly: true }
      cookies[:carrinho] = nil
  end 

  def boleto_gerado 
    @id = cookies[:pedido_id]
    @valor = cookies[:valor]
    @pdf_boleto = cookies[:comprovante]
    @numero_boleto = cookies[:numero_boleto]
  end

  def compra_concluida 
    @id = cookies[:pedido_id]
    @valor = cookies[:valor]
    @comprovante = cookies[:comprovante]
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

    if cookies[:carrinho].blank?
      redirect_to "/"
      return
    end
      produtos = JSON.parse(cookies[:carrinho]);
      @produtos = Produto.where(id: produtos)
  end

  def confirmar_pagamento
    params[:data].present? && params[:data][:id].present?
    pedidos = Pedido.where(transacao_id: params[:data][:id])
    if pedidos.count > 0
      pedido = pedidos.first
      pedido.status = params[:data][:status] == "paid" ? "Pago" : "Aguardando"
      pedido.save
    end
  end

  def login 
  end
  
  def fazer_login_cliente
    clientes = Cliente.where(email: params[:email], senha: params[:senha])
    if clientes.count > 0
      cliente = clientes.first
      time = params[:lembrar] == "1" ? 1.year.from_now : 30.minutes.from_now
      value = {
        id: cliente.id,
        nome: cliente.nome,
        email: cliente.email 
      }
      cookies[:cliente_login] = { value: value.to_json, expires: time, httponly: true }

      redirect_to "/carrinho/fechar"

    else
      flash[:error] = "Email ou senha invalidos"
      redirect_to "/cliente/logar" 
    end 
  end
  
  def cadastrar
    if cookies[:cliente_login].blank? 
      @cliente = Cliente.new
    else
      c = JSON.parse(cookies[:cliente_login]);
      @cliente = Cliente.find(c["id"])
    end
  end
  
  def sair 
    cookies[:cliente_login] = nil
    redirect_to "/"
  end

  def cadastrar_cliente
    if cookies[:cliente_login].blank?
      @cliente = Cliente.new(cliente_params)
        if @cliente.save
          cookies[:cliente_login] = { 
            value: {
            id: @cliente.id,
            nome: @cliente.nome,
            email: @cliente.email
            }.to_json, 
          expires: 1.year.from_now, httponly: true }
          redirect_to "/carrinho/fechar" 
        else 
          render :cadastrar
        end
    else
      c = JSON.parse(cookies[:cliente_login]);
      @cliente = Cliente.find(c["id"])

        if @cliente.update(cliente_params)
          cookies[:cliente_login] = { 
            value: {
            id: @cliente.id,
            nome: @cliente.nome,
            email: @cliente.email
            }.to_json, 
          expires: 1.year.from_now, httponly: true }
          flash[:success] = "Dados atualizado com sucesso"
          redirect_to "/cliente/cadastrar" 
        else 
          render :cadastrar
        end
    end
  end

  private 
    # Only allow a list of trusted parameters through.
    def cliente_params
      params.require(:cliente).permit(:nome, :cpf, :telefone, :email, :cep, :endereco, :numero, :bairro, :cidade, :estado, :senha)
    end
end