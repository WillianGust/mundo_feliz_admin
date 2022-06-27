class Cliente < ApplicationRecord
  validates :nome, :cpf, :telefone, :senha, :email, presence: true
end
