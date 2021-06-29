class Perfil{
  String nome;
  String token;

  Perfil(this.nome, this.token);

  @override
  bool operator ==(other) {
    return this.token == other.token;
  }
}