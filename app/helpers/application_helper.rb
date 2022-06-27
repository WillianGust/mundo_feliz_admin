module ApplicationHelper
  def existe_carrinho?(id)
    return false if cookies[:carrinho].blank?
      produtos = JSON.parse(cookies[:carrinho]);
      produtos.include?(id.to_s)
  end

  def quantidade_carrinho
    return 0 if cookies[:carrinho].blank?
      return JSON.parse(cookies[:carrinho]).length
     
  end
end
