import 'package:endereco_formfield/endereco_formfield.dart';
import 'package:geoflutterfire2/src/point.dart';
import 'package:efato/admin/users/UserData.dart';
import 'package:efato/dominio/Autor.dart';

import 'Selo.dart';

class Noticia {
  String id;
  String titulo='';
  Endereco local;
  String conteudo;
  String imagem;
  Autor autor;
  Selo selo;
  Map<String, dynamic> geopoint;

  Noticia();

  Noticia.fromJson(Map<String, dynamic> data){
    id = data['id'];
    titulo = data['titulo'];
    conteudo = data['conteudo'];
    imagem = data['imagem'];
    local = data['local']==null? null: Endereco.fromJson(data['local']);
    autor = data['autor']==null? null: Autor.fromJson(data['autor']);
    selo = data['selo']==null? null: Selo.fromJson(data['selo']);
  }

  Map<String, dynamic> toJson(){
    return {
      'titulo': titulo,
      'conteudo': conteudo,
      'imagem': imagem,
      'geopoint': geopoint,
      'local': local?.toJson(),
      'autor': autor?.toJson(),
      'selo': selo?.toJson(),
    };
  }
}