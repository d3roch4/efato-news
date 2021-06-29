import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:efato/dominio/Noticia.dart';
import 'package:efato/minhas-noticias/CriarEditarNoticiaPage.dart';
import 'package:efato/utils.dart';
import 'package:efato/widget/GridViewNoticias.dart';

import '../IHomePage.dart';

class GerirMinhasNoticiasPage extends IHomePage {
  var ctrl = GerirMinhasNoticiasCtrl();

  @override
  Widget body() {
    return StreamBuilder<List<Noticia>>(
      stream: ctrl.noticias,
      builder: (c, snap){
        if(snap.hasError==true)
          return erroMsg(snap.error.toString());
        if(snap.connectionState==ConnectionState.waiting)
          return carregando;
        var lista = snap.data;
        return GridViewNoticias(
          noticias: lista, 
          onTap: ctrl.editarNoticia,
          padding: EdgeInsets.all(kPadding),
        );
      },
    );
  }

  @override
  Widget floatingActionButton() {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: ctrl.addNoticia,
    );
  }
}

class GerirMinhasNoticiasCtrl extends GetxController{
  Stream<List<Noticia>> get noticias => firestore.collection('noticias')
    .where('autor.id', isEqualTo: usuarioLogado.uid)
    .snapshots()
    .map((itens) => itens.docs.map(
        (e) => Noticia.fromJson(e.data())..id = e.id).toList()
    );


  void addNoticia() {
    Get.to(()=> CriarEditarNoticiaPage());
  }

  void editarNoticia(Noticia noticia) {
    Get.to(()=> CriarEditarNoticiaPage(noticia));
  }
}