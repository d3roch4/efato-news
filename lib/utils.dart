import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'LoginPage.dart';
import 'admin/users/Perfil.dart';

const String kAppNome = 'É Fato News';
const kPadding = 16.0;
String kUrlFunctions = 'https://us-central1-realiza-entregas.cloudfunctions.net';
String kUrlWebApp = 'https://efato.studio132.arq.br';
var firestore = FirebaseFirestore.instance;
var storage = FirebaseStorage.instance;
User get usuarioLogado => FirebaseAuth.instance.currentUser;
Widget get carregando => Center(child: CircularProgressIndicator());
List<Perfil> get listaPerfis => [Perfil('Completo', 'completo'), Perfil('Básico', 'basico')];

Future<void> ifAutenticado(void Function() run) async {
  if(FirebaseAuth.instance.currentUser != null || await LoginPage.login() == true)
    run();
}

void backButtonPress(){
  if(Get.previousRoute.isEmpty)
    Get.toNamed('/');
  else
    Get.back();
}

void nextFocus() => FocusManager.instance.primaryFocus.nextFocus();

Widget getImagemCapa(String idNoticia, {BoxFit boxFit: BoxFit.fitWidth, Icon Function() failBack}){
  if(idNoticia?.isEmpty ?? true)
    return failBack!=null? failBack(): Container();

  return Hero(
    tag: idNoticia,
    child: CachedNetworkImage(
      imageUrl: idNoticia,
      fit: boxFit,
      placeholder: (c, u)=> failBack!=null? failBack(): Icon(Icons.image),
      errorWidget: (c,u,e)=> failBack!=null? failBack(): Container(),
    )
  );
}

Widget erroMsg(String msg) => Column(children: [
  Icon(Icons.error_outline),
  Text(msg, style: Get.textTheme.headline6)
]);

Future erroSnack(Object erro, [StackTrace st=StackTrace.empty]) {
  ScaffoldMessenger.of(Get.context).showSnackBar(SnackBar(
    duration: Duration(seconds: 15),
    content: Text('Erro ao sincronizar dados: $erro'),
  ));
  print('Erro ao sincronizar dados: $erro: \n$st');
  return Future.error(erro, st);
}

void desfazerSnack(VoidCallback func, {String msg='Deseja desfazer?'}){
  ScaffoldMessenger.of(Get.context).showSnackBar(SnackBar(
    duration: Duration(seconds: 10),
    content: Text(msg),
    action: SnackBarAction(
      label: 'Desfazer',
      onPressed: func
    ),
  ));
}

class DelayAction{
  Timer timer;
  String tag;
  int delay;

  DelayAction(this.delay);

  void run(Function func, {String newTag}){
    if(newTag == tag)
      timer?.cancel();
    else
      tag = newTag;
    timer = Timer(Duration(milliseconds: delay), func);
  }

  void saveDoc(DocumentReference doc, Map<String, dynamic> json, {List<String> fields, Function posRun}) {
    run((){
      if(fields==null)
        doc.set(json).catchError(erroSnack).then(posRun);
      else{
        var data = Map<String, dynamic>();
        for(var field in fields){
          for(var entry in json.entries)
            if(entry.key == field)
              data[field] = entry.value;
        }
        if(data.isNotEmpty)
          doc.update(data).catchError(erroSnack).then(posRun);
      }
    }, newTag: fields?.join('_'));
  }
}