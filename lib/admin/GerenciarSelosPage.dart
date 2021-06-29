import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:efato/dominio/Selo.dart';
import '../utils.dart';

class GerenciarSelosPage extends StatelessWidget {
  var ctrl = GerenciarSelosCtrl();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Selo>>(
        stream: ctrl.selos,
        builder: (c, snap){
          if(snap.hasError) return erroMsg(snap.error);
          if(snap.connectionState==ConnectionState.waiting) return carregando;
          var selos = snap.data;
          return Padding(
            padding: EdgeInsets.all(kPadding),
            child: Wrap(
              spacing: kPadding,
              children: [
                for(var cat in selos)
                  InputChip(
                    avatar: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: CachedNetworkImage(imageUrl: cat.imagem)
                    ),
                    label: Text(cat.nome),
                    backgroundColor: Color(cat.cor),
                    onDeleted: ()=> ctrl.remover(cat.nome),
                  )
              ]
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: ctrl.addNovo,
      ),
    );
  }
}

class GerenciarSelosCtrl extends GetxController {
  var colecao = firestore.collection('selos');
  get selos => colecao.snapshots().map((s) => s.docs.map((e) => Selo.fromJson(e.data())..nome=e.id).toList());

  Future<void> remover(String id) async {
    var image = storage.ref().child('selos').child(id);
    await image.delete();
    colecao.doc(id).delete()
        .catchError(erroSnack);
  }

  void addNovo() {
    var nomeCtrl = TextEditingController();
    var cor = Colors.white.obs;
    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.all(kPadding),
        child: ListView(
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: InputDecoration(labelText: 'Nome', hintText: 'Qual o nome do novo selo?'),
              onEditingComplete: () async {
                _addImagem(nomeCtrl.text, cor.value);
                nomeCtrl.clear();
              },
            ),
            Obx(()=>BlockPicker(
              pickerColor: cor.value,
              onColorChanged: (val)=> cor.value = val,
              // showLabel: true,
              // pickerAreaHeightPercent: 0.8,
            )),
            SizedBox(height: kPadding*2),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                child: Text('Cancelar'),
                onPressed: Get.back,
              ),
              SizedBox(width: kPadding*2),
              ElevatedButton(
                child: Text('Adicionar'),
                onPressed: (){
                  _addImagem(nomeCtrl.text, cor.value);
                  Get.back();
                },
              )
            ])
          ]
        ),
      ),
      backgroundColor: Get.theme.cardColor
    );
  }

  Future<void> _addImagem(String nome, Color cor) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    if(pickedFile == null) return;

    var image = storage.ref().child('selos').child(nome);
    TaskSnapshot upload;
    if(GetPlatform.isWeb) {
      var bytes = await pickedFile.readAsBytes();
      upload = await image.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg')
      ).catchError(erroSnack);
    }else
      upload = await image.putFile(File(pickedFile.path));

    if(upload.state != TaskState.success)
      return;

    if(nome.isEmpty) return;

    var url = await image.getDownloadURL();
    var selo = Selo()
      ..nome = nome
      ..imagem = url
      ..cor = cor.value;

    colecao.doc(nome).set(selo.toJson())
        .catchError(erroSnack);
  }
}