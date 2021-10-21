import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endereco_formfield/endereco_formfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:efato/admin/users/UserData.dart';
import 'package:efato/dominio/Autor.dart';
import 'package:efato/dominio/Noticia.dart';
import 'package:efato/dominio/Selo.dart';
import 'package:efato/utils.dart';
import 'package:efato/widget/RichTextEdit.dart';
import 'package:zefyrka/zefyrka.dart';
import 'package:quill_format/quill_format.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class CriarEditarNoticiaPage extends StatelessWidget{
  var formKey = GlobalKey<FormState>();
  CriarEditarNoticiaCtrl ctrl;

  CriarEditarNoticiaPage([Noticia noticia]){
    ctrl = CriarEditarNoticiaCtrl(noticia);
  }

  @override
  Widget build(BuildContext context) {
    var scroolCtrl = ScrollController();
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Obx(()=> Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Cadastro de notícia'),
          actions: [PopupMenuButton<int>(
            itemBuilder: (c)=> [
              PopupMenuItem(
                child: TextButton.icon(
                  icon: Icon(Icons.delete_forever),
                  label: Text('Deletar'),
                  onPressed: ctrl.deletar,
                ),
              )
            ]
          )],
        ),
        body:  ctrl.noticia.value==null? carregando: Form(
          key: formKey,
          child: Stack(children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).viewInsets.bottom,
              child: ListView(
                  padding: ctrl.focusConteudo.hasFocus? EdgeInsets.fromLTRB(kPadding, kPadding, kPadding, 56): EdgeInsets.all(kPadding),
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Titulo', hintText: 'Pequeno titulo da notícia'),
                      controller: TextEditingController(text: ctrl.noticia.value.titulo),
                      onChanged: (val)=> ctrl.salvar(() => ctrl.noticia.value.titulo=val, ['titulo']),
                      onEditingComplete: ()=> nextFocus(),
                      validator: (val)=> val.isEmpty? 'É necessario informar um titulo': null,
                    ),
                    EnderecoFormField(
                      inputDecoration: InputDecoration(labelText: 'Local do ocorrido', hintText: 'Clique aqui para escolher o local'),
                      initialValue: ctrl.noticia.value.local,
                      onChanged: ctrl.mudarLocalizacao,
                      autdoDetectar: true,
                      validator: (val)=> val?.latitude == null? 'Selecione uma localização': null,
                      // onEditingComplete: ()=> nextFocus(),
                    ),
                    // FutureBuilder<List<Selo>>(
                    //   future: ctrl.selos,
                    //   builder: (c, snap)=>snap.data==null? carregando: DropdownButtonFormField(
                    //     decoration: InputDecoration(labelText: 'Selo', hintText: 'Selecione um selo adequado ao fato relatado'),
                    //     onChanged: ctrl.mudarSelo,
                    //     value: snap.data.contains(ctrl.noticia.value.selo)? ctrl.noticia.value.selo: null,
                    //     items: snap.data.map((e) => DropdownMenuItem(
                    //       child: Chip(
                    //         avatar: CachedNetworkImage(imageUrl: e.imagem),
                    //         label: Text(e.nome),
                    //       ),
                    //       value: e,
                    //     )).toList(),
                    //   ),
                    // ),
                    RichTextEdit(
                      ctrl.zefyrController,
                      scrollController: scroolCtrl,
                      scrollable: false,
                      decoration: InputDecoration(labelText: 'Conteudo', hintText: 'Conte em detalhes o fato.'),
                      focusNode: ctrl.focusConteudo,
                      onChange: ctrl.atualizarConteudo,
                    ),
                    SizedBox(height: 56),
                  ]
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 0,
              right: 0,
              child: Container(
                color: Get.theme.cardColor,
                child: RichTextEdit.toolbar(ctrl.zefyrController,  ctrl.dirUploadImagens),
              ),
            )
          ]),
        ),
      )),
    );
  }
}

class CriarEditarNoticiaCtrl extends GetxController {
  var noticia = Rx<Noticia>(null);
  var delayAction = DelayAction(2000);
  DocumentReference doc;
  bool docExiste;
  ZefyrController zefyrController;
  var focusConteudo = FocusNode();
  Future<List<Selo>> selos;

  CriarEditarNoticiaCtrl(Noticia param){
    focusConteudo.addListener(()=> print('focusConteudo: ${focusConteudo.hasFocus}'));
    selos = firestore.collection('selos').get()
      .asStream()
      .map((e) => e.docs.map((d) => Selo.fromJson(d.data())..nome=d.id)
      .toList()).first;

    var colecao = firestore.collection('noticias');
    if(param?.id==null){
      doc = colecao.doc();
      noticia.value = Noticia();
      noticia.value.id = doc.id;
      noticia.value.autor = Autor()
        ..id = usuarioLogado.uid
        ..nome = usuarioLogado.displayName;
      docExiste = false;
      zefyrController = ZefyrController(NotusDocument()..insert(0, 'Descreva em detalhes o fato ocorrido'));
    }else{
      colecao.doc(param.id).get().then((v){
        if(v.exists) {
          doc = v.reference;
          noticia.value = Noticia.fromJson(v.data())..id = doc.id;
          try{
            var notus = NotusDocument.fromJson(json.decode(noticia.value.conteudo));
            if(notus.length==1)
              notus.insert(0, 'Descreva em detalhes o fato ocorrido');
            zefyrController = ZefyrController(notus);
          }catch(ex){
            zefyrController = ZefyrController(NotusDocument()..insert(0, 'Descreva em detalhes o fato ocorrido'));
          }
        }
        docExiste = v.exists;
      }).catchError(erroSnack);
    }
  }

  String get dirUploadImagens => 'noticias/${noticia.value.id}';

  void salvar(Function() func, List<String> fields) async {
    if(func != null)
      await func();

    delayAction.saveDoc(
      doc, 
      noticia.value.toJson(), 
      fields: !docExiste? null: fields,
      posRun: (_)=> docExiste=true
    );
  }

  void atualizarConteudo(NotusDocument document) {
    salvar((){
      var operacoes = document.toJson() as List<Operation>;
      for(var op in operacoes){
        if(op.isInsert && op.data is! String){
          dynamic data = op.data;
          if(data['_type'] == 'image'){
            if(noticia.value.imagem != data['source']){
              salvar(() => noticia.value.imagem = data['source'], ['imagem']);
            }
            break;
          }
        }
      }
      noticia.value.conteudo = json.encode(operacoes);
    }, ['conteudo']);
  }

  Future<void> deletar() async {
    var dirImgs = dirUploadImagens;
    noticia.value = null;
    var listImgs = await storage.ref().child(dirImgs).list();

    if(listImgs.items.isNotEmpty)
      for(var item in listImgs.items)
        await item.delete();
    await doc.delete();
    Get.back();
    Get.back();
  }

  void mudarSelo(Selo value) {
    salvar((){
      noticia.value.selo = value;
      noticia.refresh();
    }, ['selo']);
  }

  void mudarLocalizacao(Endereco val) {
    salvar((){
      noticia.value.local=val;
      final geo = GeoFlutterFire();
      noticia.value.geopoint = geo.point(latitude: val.latitude, longitude: val.longitude).data;
    }, ['local', 'geopoint']);
  }
}