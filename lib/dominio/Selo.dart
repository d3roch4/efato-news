class Selo {
  String nome;
  String imagem;
  int cor;

  Selo();

  Selo.fromJson(Map<String, dynamic> data){
    nome = data['nome'];
    imagem = data['imagem'];
    cor = data['cor'];
  }

  Map<String, dynamic> toJson(){
    return {
      'nome': nome,
      'imagem': imagem,
      'cor': cor,
    };
  }

  @override
  bool operator ==(other) {
    return this.nome == other.nome;
  }
}