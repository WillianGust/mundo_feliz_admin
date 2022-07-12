class IuguCustomerId < ActiveRecord::Migration[5.2]
  def change
    add_column :clientes, :iugu_customer_id, :string
  end
end
