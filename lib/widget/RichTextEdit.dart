import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:efato/utils.dart';
import 'package:zefyrka/zefyrka.dart';

class RichTextEdit extends StatelessWidget{
  ZefyrController _controller;
  bool readOnly;
  void Function(NotusDocument) onChange;
  FocusNode focusNode;
  InputDecoration decoration;
  EdgeInsets padding;
  ScrollController scrollController;
  bool scrollable;

  RichTextEdit(this._controller, {
    this.onChange,
    this.readOnly=false,
    this.focusNode,
    this.decoration,
    this.padding,
    this.scrollController,
    this.scrollable,
  }){
    assert(_controller != null);
    focusNode ??= FocusNode();
    decoration ??= InputDecoration(labelText: 'Conteudo', hintText: 'Conte em detalhes o fato.');
    if(onChange!=null)
      _controller.addListener(()=> onChange(_controller.document));
  }

  static ZefyrToolbar toolbar(ZefyrController controller, [String dirUpload]){
    var toolbar = ZefyrToolbar.basic(controller: controller);
    toolbar.children.add(ZIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: 32,
      icon: Icon(
        Icons.add_a_photo,
        size: 18,
        color: Get.theme.iconTheme.color,
      ),
      fillColor: Get.theme.canvasColor,
      onPressed: () async {
        final index = controller.selection.baseOffset;
        final length = controller.selection.extentOffset - index;
        var source = await selecionarImagem(dirUpload);
        if(source != null)
          controller.replaceText(index, length, BlockEmbed.image(source));
      },
    ));
    return toolbar;
  }

  @override
  Widget build(BuildContext context) {
    if(readOnly)
      return ZefyrEditor(
        controller: _controller,
        focusNode: focusNode,
        padding: this.padding,
        readOnly: true,
        showCursor: false,
        enableInteractiveSelection: true,
        scrollController: this.scrollController,
        scrollable: this.scrollable,
        embedBuilder: _embedBuilder,
      );
    return ZefyrField(
      scrollable: this.scrollable,
      scrollController: this.scrollController,
      decoration: decoration,
      controller: _controller,
      focusNode: focusNode,
      embedBuilder: _embedBuilder,
      // toolbar: toolbar(_controller),
    );
  }

  Widget _embedBuilder(BuildContext context, EmbedNode node) {
    if (node.value.type == 'image') {
      return CachedNetworkImage(
        imageUrl: node.value.data['source'],
        fit: BoxFit.fill,
      );
    }
    return defaultZefyrEmbedBuilder(context, node);
  }

  static Future<String> selecionarImagem(String dirUpload) async {
    var lista = storage.ref().child(dirUpload).list();
    var upload = IconButton(
      iconSize: 100,
      icon: Icon(Icons.upload_file, size: 100),
      onPressed: ()=> uploadImagem(dirUpload),
    );

    var url = await Get.bottomSheet(FutureBuilder<ListResult>(
      future: lista,
      builder: (c, snap)=> SingleChildScrollView(child: Wrap(children: [
        upload,
        if(snap.connectionState==ConnectionState.waiting)
          CircularProgressIndicator(),
        if(snap.data != null) for(var item in snap.data.items)
          getBotaoImagemFirestore(item.getDownloadURL()),
      ])),
    ), backgroundColor: Get.theme.cardColor);

    return url;
  }

  static Widget getBotaoImagemFirestore(Future<String> url){
    return FutureBuilder<String>(
        future: url,
        builder: (c, snap)=> snap.data==null?
        CircularProgressIndicator():
        IconButton(
          iconSize: 100,
          icon: CachedNetworkImage(imageUrl: snap.data),
          onPressed: ()=> Get.back(result: snap.data),
        )
    );
  }

  static Future<void> uploadImagem(String dirUpload) async {
    if(dirUpload==null) {
      Get.back();
      return erroSnack('É preciso informar o diretorio de upload');
    }

    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    if(pickedFile == null) return;

    var nameFile = pickedFile.path.substring(pickedFile.path.lastIndexOf('/'));
    var image = storage.ref().child(dirUpload).child(nameFile);
    TaskSnapshot upload;
    if(GetPlatform.isWeb) {
      var bytes = await pickedFile.readAsBytes();
      upload = await image.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg')
      ).catchError(erroSnack);
    }else{
      upload = await image.putFile(File(pickedFile.path));
    }
    if(upload.state == TaskState.success){
      // image = storage.ref().child(dirUpload).child('${nameFile}_320x240');
      var url = await image.getDownloadURL();
      Get.back(result: url);
    }
  }
}