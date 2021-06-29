import 'dart:io';

import 'package:efato/admin/users/UserData.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../utils.dart';
import 'Perfil.dart';

class UsuarioPage extends StatelessWidget{
  UsuarioPageCtrl ctrl;

  UsuarioPage(UserData user) : ctrl=UsuarioPageCtrl(user);

  @override
  Widget build(BuildContext context) {
    List<Perfil> perfis = listaPerfis;
    perfis.add(Perfil('Admin', 'admin'));
    return Form(
      child: ListView(padding: EdgeInsets.all(kPadding), children: [
        Icon(Icons.account_circle, size: 128),
        TextFormField(
          decoration: InputDecoration(hintText: 'Seu nome', labelText: 'Nome'),
          controller: TextEditingController(text: ctrl.user.displayName),
          keyboardType: TextInputType.name,
          validator: (val)=> val.isEmpty? 'Informe seu nome': null,
          onChanged: (val)=> ctrl.user.displayName=val,
        ),
        TextFormField(
          decoration: InputDecoration(hintText: 'Ex: usuario@email.com', labelText: 'e-Mail'),
          controller: TextEditingController(text: ctrl.user.email),
          keyboardType: TextInputType.emailAddress,
          onChanged: (val)=> ctrl.user.email=val,
//            validator: (val)=> val.isEmpty || !val.contains('@')? 'Verifique o e-mail informado': null,
        ),
        TextFormField(
          decoration: InputDecoration(hintText: 'DDD + número Ex: +5511987654321', labelText: 'Telefone'),
          controller: TextEditingController(text: ctrl.user.phoneNumber),
          onChanged: (val)=> ctrl.user.phoneNumber=val,
          keyboardType: TextInputType.phone,
        ),
        DropdownButtonFormField<String>(
          items: [
            for(var perfil in perfis)
              DropdownMenuItem(child: Text(perfil.nome), value: perfil.token),
          ],
          value: perfis.firstWhere((e) => e.token==ctrl.user.role, orElse: ()=> null)?.token,
          onChanged: (val)=> ctrl.user.role=val,
        ),
        SizedBox(height: kPadding),
        Obx(()=> ElevatedButton(
            child: Text(ctrl.salvando.value? 'Salvando...': 'Salvar'),
            onPressed: ctrl.salvando.value? null: salvar
        ))
      ]),
    );
  }

  void salvar(){
    ctrl.salvar().catchError((erro, stack) {
      ScaffoldMessenger.of(Get.context).showSnackBar(SnackBar(
        content: Text(erro.toString()),
      ));
      print('erro: $erro, $stack');
    });
  }
}

class UsuarioPageCtrl {
  UserData user;
  var salvando = false.obs;

  UsuarioPageCtrl(this.user){
    user = UserData.fromJson(user.toJson());
  }

  Future<void> salvar() async {
    salvando.value = true;
    var tkn = await FirebaseAuth.instance.currentUser.getIdToken();
    var resp = await http.patch(
      Uri.parse('$kUrlFunctions/api/users/${user.uid}'),
      headers: {HttpHeaders.authorizationHeader: "Bearer $tkn"},
      body: user.toJson()
    );

    if(resp.statusCode<200&&resp.statusCode>299)
      return Future.error(resp.body);
    salvando.value = false;
  }
}