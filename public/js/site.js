var mundofeliz ={}
mundofeliz.pagamentoBoleto = function(){
  var pg_id = "0356A63D7B814C8CB330668A34A48CD6"; //Chave muda quando passa para producao

    Iugu.setTestMode(true); //Para passar p ara producao colocar false
    Iugu.setAccountID(pg_id);
    Iugu.setup();
      var cpf = document.getElementById("cpf").value
      var telefone = document.getElementById("telefone").value
      var email = document.getElementById("email").value
      var cep = document.getElementById("cep").value
      var endereco = document.getElementById("endereco").value
      var numero = document.getElementById("numero").value
      var bairro = document.getElementById("bairro").value
      var cidade = document.getElementById("cidade").value
      var estado = document.getElementById("estado").value
      $.post("/cliente/concluir-pagamento", {
        cliente_id: cliente_id,
        telefone: telefone,
        email: email,
        cep: cep,
        endereco: endereco,
        numero: numero,
        bairro: bairro,
        cidade: cidade,
        estado: estado
      }).done(function(){
        // alert("Compra realizada com sucesso");
        window.location.href = "/cliente/compra-concluida"
      }).fail(function(){
        alert("Erro na compra");
      }); 
}

  mundofeliz.pagamentoCartao = function(){
    var pg_id = "0356A63D7B814C8CB330668A34A48CD6"; //Chave muda quando passa para producao

      Iugu.setTestMode(true); //Para passar p ara producao colocar false
      Iugu.setAccountID(pg_id);
      Iugu.setup();

      var number = document.getElementById("number").value
      var mes = document.getElementById("mes").value
      var ano = document.getElementById("ano").value
      var nome = document.getElementById("nome").value
      var sobrenome = document.getElementById("sobrenome").value
      var cvv = document.getElementById("cvv").value
      var cliente_id = document.getElementById("cliente_id").value
      cc = Iugu.CreditCard(number, mes, ano, nome, sobrenome, cvv);
      // cc = Iugu.CreditCard("4111111111111111", "12", "2023", "Nome","Sobrenome", "123");
      Iugu.createPaymentToken(cc, function(data){
      
        if (data.errors){  
          alert("erro ao gerar!");
          console.log(data.errors);
        } else {
          var token = data.id;
          debugger
          $.post("/cliente/concluir-pagamento", {token: token, cliente_id: cliente_id}).done(function(){
            // alert("Compra realizada com sucesso");
            window.location.href = "/cliente/compra-concluida"
          }).fail(function(){
            alert("Erro na compra");
          });  
        }
      });
    } 