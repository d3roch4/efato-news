import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paginate_firestore/paginate_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:efato/dominio/Avaliacao.dart';
import 'package:efato/dominio/Noticia.dart';
import 'package:efato/dominio/Selo.dart';
import 'package:efato/utils.dart';
import 'package:zefyrka/zefyrka.dart';
import 'package:http/http.dart' as http;
import 'widget/RichTextEdit.dart';

class VisualizarNoticiaPage extends StatelessWidget{
  VisualizarNoticiaCtrl ctrl;

  VisualizarNoticiaPage([Noticia noticia]){
    ctrl = VisualizarNoticiaCtrl(noticia);
  }

  get avaliacoesLista {
    return Container(
      height: 110,
      width: 200,
      child: PaginateFirestore(
        isLive: true,
        padding: EdgeInsets.zero,
        itemBuilderType: PaginateBuilderType.listView,
        query: ctrl.avaliacoes(),
        itemBuilder: (i, c, doc){
          var a = Avaliacao.fromJson(doc.data());
          return ListTile(
            leading: CachedNetworkImage(imageUrl: a.selo.imagem),
            title: Text(a.selo.nome),
            subtitle: Text(a.usuario.nome),
            contentPadding: EdgeInsets.zero,
          );
        },
      )
    );
    return FutureBuilder(
      future: ctrl.avaliacoes(),
      builder: (c, snap)=> snap.data==null? carregando: snap.data.map((a) => ListTile(
        leading: CachedNetworkImage(imageUrl: a.selo.imagem),
        title: Text(a.selo.nome),
        subtitle: Text(a.usuario.nome),
        contentPadding: EdgeInsets.zero,
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(()=> Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: backButtonPress),
        title: Text(ctrl.noticia.value==null? 'Carregando...': ctrl.noticia.value.titulo),
        actions: [IconButton(
          icon: Icon(Icons.share),
          onPressed: ctrl.compartilhar,
        )],
      ),
      body: ctrl.noticia.value==null? carregando: Stack(children: [
        RichTextEdit(
          ctrl.zefyrCtrl,
          focusNode: FocusNode(),
          readOnly: true,
          padding: EdgeInsets.fromLTRB(kPadding, kPadding, kPadding, 100),
          scrollable: true,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.person),
            Text(ctrl.noticia.value.autor.nome)
          ],
        ),
        if(ctrl.noticia.value.selo != null)
        Positioned(
          top: 8,
          right: 8,
          child: Hero(
            tag : ctrl.noticia.value.id,
            child: Obx(()=> GestureDetector(
              child: SimpleTooltip(
                tooltipDirection: TooltipDirection.left,
                ballonPadding: EdgeInsets.zero,
                animationDuration: Duration(milliseconds: 400),
                child: CachedNetworkImage(imageUrl: ctrl.noticia.value.selo.imagem, height: 50),
                show: ctrl.mostrarAvaliacoes.value,
                hideOnTooltipTap: true,
                content: Material(child: avaliacoesLista),
              ),
              onTap: ()=>ctrl.mostrarAvaliacoes.toggle(),
            )),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.gavel),
        label: Text('Avaliar'),
        onPressed: ctrl.avaliarNoticia,
      ),
    ));
  }

}

class VisualizarNoticiaCtrl extends GetxController{
  var noticia = Rx<Noticia>(null);
  ZefyrController zefyrCtrl;
  var mostrarAvaliacoes = false.obs;

  VisualizarNoticiaCtrl([Noticia noticia]){
    initNoticia(noticia);
  }

  Future<List<Selo>> get selos async {
    var snap = await firestore.collection('selos').get();
    return snap.docs.map((e) => Selo.fromJson(e.data())).toList();
  }

  Future<void> initNoticia([Noticia not]) async {
    if(Get.arguments!=null)
      this.noticia.value = Get.arguments;
    else if(not != null)
      this.noticia.value = not;
    else{
      var v = await firestore.collection('noticias').doc(Get.parameters['id']).get();
      if(!v.exists) return;
      this.noticia.value = Noticia.fromJson(v.data())..id=v.id;
    }

    try{
      var notus = NotusDocument.fromJson(json.decode(noticia.value.conteudo));
      if(notus.length==1)
        notus.insert(0, 'Descreva em detalhes o fato ocorrido');
      zefyrCtrl = ZefyrController(notus);
    }catch(ex){
      zefyrCtrl = ZefyrController(NotusDocument()..insert(0, 'Descreva em detalhes o fato ocorrido'));
    }
  }

  Future<void> compartilhar() async {
    return Share.share('${zefyrCtrl.document.toPlainText()} https://efato-news.web.app/n/${noticia.value.id}', subject: noticia.value.titulo);

    var resp = await http.get(Uri.parse(noticia.value.imagem));
    if(resp.statusCode == 200){
      var file = XFile.fromData(resp.bodyBytes);
      Share.shareFiles([file.path]);
    }
  }

  Future<void> avaliarNoticia() async {
    Get.bottomSheet(Card(child: Column(children: [
      Text('Qaul a sua avaliação?'),
      Expanded(child: SingleChildScrollView(child: Wrap(
        // scrollDirection: Axis.horizontal,
        children: (await selos).map<Widget>((s) => GestureDetector(
          onTap: ()=> ifAutenticado(()=> incrementarSelo(s)),
          child: Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(color: Color(s.cor), width: 5),
                borderRadius: BorderRadius.circular(kPadding)
            ),
            child: Padding(
                padding: EdgeInsets.all(kPadding/2),
                child: Container(height: 120, width: 100, child: Column(children: [
                  CachedNetworkImage(imageUrl: s.imagem),
                  Text(s.nome, maxLines: 3, overflow: TextOverflow.ellipsis)
                ]))
            ),
          ),
        )).toList(),
      ))),
      TextButton(
        child: Text('Canceclar'),
        onPressed: Get.back,
      )
    ])));
  }

  Future<void> incrementarSelo(Selo s) async {
    Get.back();

    var colecao = firestore.collection('avaliacoes');
    var avaliacao = Avaliacao()
      ..noticia = noticia.value.id
      ..selo = s
      ..usuario = (UsuarioAvaliacao()..id=usuarioLogado.uid..nome=usuarioLogado.displayName);

    var snap = await colecao
        .where('noticia', isEqualTo: avaliacao.noticia)
        .where('usuario.id', isEqualTo: avaliacao.usuario.id)
        .get().catchError(erroSnack);

    if(snap.docs.isEmpty)
      colecao.add(avaliacao.toJson());
    else
      snap.docs.first.reference.set(avaliacao.toJson());

    mostrarAvaliacoes.trigger(true);
  }

  avaliacoes() {
    return firestore.collection('avaliacoes')
      .where('noticia', isEqualTo: noticia.value.id);
  }
}
