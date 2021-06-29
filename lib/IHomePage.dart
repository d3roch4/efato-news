import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

import 'LoginPage.dart';
import 'utils.dart';

abstract class IHomePage extends StatelessWidget{
  var _ctrl = IHomePageCtrl();

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: title(),
      kDesktopBreakpoint: 1024,
      drawer: drawer(),
      endIcon: Icons.filter_list,
      endDrawer: endDrawer(),
      trailing: trailing(),
      body: body(),
      floatingActionButton: floatingActionButton(),
    );
  }

  adminButton() {
    return _ctrl.clains==null? Container(): FutureBuilder<IdTokenResult>(
      future: _ctrl.clains,
      builder: (c, snap){
        if(snap.hasData && snap.data.claims['role']=='admin')
          return ListTile(
            leading: Icon(Icons.admin_panel_settings),
            title: Text('Administração'),
            onTap: ()=> Get.offAllNamed('/admin'),
          );
        return Container();
      },
    );
  }


  @override
  Widget drawer() {
    return ListView(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(kPadding),
          child: Image.asset('assets/icon.png'),
        ),
        ListTile(
          leading: Icon(Icons.home),
          title: Text('Início'),
          onTap: ()=> Get.offAllNamed('/'),
        ),
        ListTile(
          leading: Icon(Icons.model_training),
          title: Text('Minhas notícias'),
          onTap: ()=> ifAutenticado(()=> Get.offAllNamed('/minhas-noticias')),
        ),
        adminButton(),
        Divider(),
        ListTile(
          leading: Icon(Icons.account_circle),
          title: Text('Dados de acesso'),
          onTap: ()=> ifAutenticado(()=> Get.toNamed('/dados-acesso')),
        ),
        if(FirebaseAuth.instance.currentUser!= null)
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Sair'),
            onTap: FirebaseAuth.instance.signOut,
          ),
        if(FirebaseAuth.instance.currentUser== null)
          ListTile(
            leading: Icon(Icons.login),
            title: Text('Entrar'),
            onTap: _ctrl.login,
          ),
      ],
    );
  }

  Widget body();
  Widget endDrawer()=> null;
  Widget trailing()=> null;
  Widget floatingActionButton()=> null;
  Widget title()=> Text(kAppNome);
}


class IHomePageCtrl extends GetxController{
  var clains = FirebaseAuth.instance.currentUser?.getIdTokenResult();

  Future<void> login() async {
    if(await LoginPage.login() == true)
    Get.offAndToNamed('/');
  }
}
