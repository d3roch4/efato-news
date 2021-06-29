import 'package:country_code_picker/country_code_picker.dart';
import 'package:country_code_picker/country_codes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'utils.dart';

class DadosAcessoEditarPage extends StatelessWidget {
  var formKey = GlobalKey<FormState>();
  var ctrl = DadosAcessoEditarCtrl();
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text('Dados de acesso'),),
      body: Form(
        key: formKey,
        child: ListView(padding: EdgeInsets.all(kPadding), children: [
          Icon(Icons.account_circle, size: 128),
          TextFormField(
            decoration: InputDecoration(hintText: 'Seu nome', labelText: 'Nome'),
            controller: TextEditingController(text: ctrl.nome),
            validator: (val)=> val.isEmpty? 'Informe seu nome': null,
            onChanged: (val)=> ctrl.nome=val,
          ),
          TextFormField(
            decoration: InputDecoration(hintText: 'Ex: usuario@email.com', labelText: 'e-Mail'),
            controller: TextEditingController(text: ctrl.email),
            onChanged: (val)=> ctrl.email=val,
//            validator: (val)=> val.isEmpty || !val.contains('@')? 'Verifique o e-mail informado': null,
          ),
          if(!(ctrl.user?.emailVerified??true)) Obx(()=>ElevatedButton(
            child: Text(ctrl.verifEmailHblt.value? 'Confirmar e-mail': 'Clique no link que enviamos para o seu email'),
            onPressed: ctrl.verifEmailHblt.value? ctrl.confirmarEmail: null,
          )),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            CountryCodePicker(
              onChanged: (val)=> ctrl.pais=val.dialCode,
              // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
              initialSelection: ctrl.pais,
              favorite: ['+55','FR', '+1'],
              // optional. Shows only country name and flag
              showCountryOnly: false,
              // optional. Shows only country name and flag when popup is closed.
              showOnlyCountryWhenClosed: false,
              // optional. aligns the flag and the Text left
              alignLeft: false,
            ),
            Expanded(child: TextFormField(
              decoration: InputDecoration(hintText: 'DDD + número Ex: 11 98765-4321', labelText: 'Telefone'),
              controller: TextEditingController(text: ctrl.telefone),
              onChanged: (val)=> ctrl.telefone=val,
            )),
          ]),
          SizedBox(height: kPadding),
          Obx(()=> ElevatedButton(
            child: Text(ctrl.salvando.value? 'Salvando...': 'Salvar'),
            onPressed: ctrl.salvando.value? null: (ctrl.user?.isAnonymous??true)? null: salvar
          ))
        ]),
      ),
    );
  }

  Future<void> salvar() async {
    if(formKey.currentState.validate())
      if(await ctrl.salvar())
        Get.back();
  }
}


class DadosAcessoEditarCtrl extends GetxController{
  String nome, email, telefone, pais;
  var user = FirebaseAuth.instance.currentUser;
  var salvando = false.obs;
  var verifEmailHblt = true.obs;

  DadosAcessoEditarCtrl(){
    nome = user?.displayName ?? 'Anônimo';
    email = user?.email ?? '';
    telefone = user?.phoneNumber ?? '';

    dynamic codPaisDy = codes.firstWhere((c) => telefone.startsWith(c['dial_code']), orElse: ()=> null);
    if(codPaisDy != null) {
      pais = codPaisDy['dial_code'];
      telefone = telefone.substring(pais.length);
    }else
      pais = '+55';

    // user?.getIdTokenResult()?.then((value) => print('clains: ${value.claims}'));
  }

  Future<bool> salvar() async {
    salvando.value = true;
    bool sucesso = true;

    if(email != user.email) 
      await salvarEmail();
    if(nome != user.displayName)
      await user.updateProfile(displayName: nome);
    if(telefone != user.phoneNumber)
      sucesso = await alterarTelefone();

    salvando.value = false;
    return sucesso;
  }

  Future<void> salvarEmail() async {
    await user.verifyBeforeUpdateEmail(email);
    ScaffoldMessenger.of(Get.context).showSnackBar(SnackBar(
      content: Text('Foi enviado um link de confirmação para $email. Clique no link para ativar esse email.'),
    ));
  }

  void erroAlterarTelefone(FirebaseAuthException error) {
    print('erroAlterarTelefone: $error');

    ScaffoldMessenger.of(Get.context).showSnackBar(SnackBar(
      duration: Duration(seconds: 45),
      content: Text('Não foi possível salvar o telefone.'),
      action: SnackBarAction(label: 'Detalhes', onPressed: ()=>Get.dialog(AlertDialog(
        content: Text('$error'),
        actions: [ElevatedButton(onPressed: Get.back, child: Text('Fechar'))],
      ))),
    ));
  }

  Future<bool> alterarTelefone() async {
    bool sucesso = true;
    var numero = pais+telefone;

    if(GetPlatform.isWeb){
      var confirmResult = await FirebaseAuth.instance.signInWithPhoneNumber(numero).catchError((erro){
        sucesso = false;
        erroAlterarTelefone(erro);
      });
      if(sucesso == false) return false;

      String smsCode = await getCodigoSms();
      if(smsCode == null) return false;

      var credential = PhoneAuthProvider.credential(
          verificationId: confirmResult.verificationId,
          smsCode: smsCode
      );
      await user.updatePhoneNumber(credential).catchError((erro){
        sucesso=false;
        erroAlterarTelefone(erro);
      });
      return sucesso;
    }
    
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: numero,
      timeout: const Duration(minutes: 2),
      verificationCompleted: (credential) async {
        print('verificationCompleted');
        await user.updatePhoneNumber(credential).catchError((erro){
          sucesso=false;
          erroAlterarTelefone(erro);
        });
        // either this occurs or the user needs to manually enter the SMS code
      },
      verificationFailed: (e){
        sucesso = false;
        erroAlterarTelefone(e);
      },
      codeSent: (verificationId, [forceResendingToken]) async {
        print('codeSent');
        String smsCode = await getCodigoSms();
        if(smsCode == null){
          sucesso = false;
          return;
        }

        final AuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: smsCode
        );
        await user.updatePhoneNumber(credential).catchError((erro){
          sucesso=false;
          erroAlterarTelefone(erro);
        });
      },
      codeAutoRetrievalTimeout: null
    ).catchError((erro){
      sucesso = false;
      erroAlterarTelefone(erro);
    });
    return sucesso;
  }

  Future<String> getCodigoSms() {
    String codigo;

    return Get.dialog<String>(AlertDialog(
      title: new Text("Informe o código enviado por SMS"),
      content:TextField(
        decoration: InputDecoration(labelText: 'Código', hintText: 'Informe o código recebido via SMS'),
        onChanged: (val)=> codigo=val,
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancelar'),
          onPressed: ()=> Get.back(),
        ),
        ElevatedButton(
          child: Text('Confirmar'),
          onPressed: ()=> Get.back(result: codigo),
        )
      ],
    ));
  }

  void confirmarEmail() {
    if(email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(Get.context).showSnackBar(SnackBar(
        content: Text('Informe um e-mail, válido primeiro'),
      ));
      return;
    }

    verifEmailHblt.value = false;
    user.sendEmailVerification().catchError((erro)=>
      ScaffoldMessenger.of(Get.context).showSnackBar(SnackBar(
        content: Text('Erro: $erro'),
      ))
    );
  }
}