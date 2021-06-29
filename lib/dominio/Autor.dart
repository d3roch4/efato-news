class Autor {
  String id;
  String nome;
  double reputacao;

  Autor();

  Autor.fromJson(var data){
    id = data['id'];
    nome = data['nome'];
    reputacao = data['reputacao'];
  }

  toJson() {
    return {
      'id': id,
      'nome': nome,
      'reputacao': reputacao,
    };
  }
}