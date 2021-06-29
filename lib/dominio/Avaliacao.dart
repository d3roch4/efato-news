import 'package:efato/dominio/Noticia.dart';

import 'Selo.dart';

class UsuarioAvaliacao{
  String id;
  String nome;

  UsuarioAvaliacao();

  UsuarioAvaliacao.fromJson(Map<String, dynamic> data){
    id = data['id'];
    nome = data['nome'];
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'nome': nome,
    };
  }
}

class Avaliacao{
  String noticia;
  UsuarioAvaliacao usuario;
  Selo selo;

  Avaliacao();

  Avaliacao.fromJson(Map<String, dynamic> data){
    noticia = data['noticia'];
    usuario = UsuarioAvaliacao.fromJson(data['usuario']);
    selo = Selo.fromJson(data['selo']);
  }

  Map<String, dynamic> toJson(){
    return {
      'noticia': noticia,
      'usuario': usuario.toJson(),
      'selo': selo.toJson(),
    };
  }
}