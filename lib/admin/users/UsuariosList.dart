import 'dart:convert';
import 'dart:io';

import 'package:efato/utils.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_scaffold/templates/list/responsive_list.dart';
import 'package:http/http.dart' as http;
import 'UserData.dart';
import 'UsuarioPage.dart';

class UsuariosList extends StatelessWidget{
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  var ctrl = UsuariosListCtrl();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserData>>(
      future: ctrl.getUsuarios(),
      builder: (c, snap){
        if(snap.hasError)
          return Text(snap.error.toString());
        if(snap.data==null)
          return Center(child: CircularProgressIndicator());

        return ResponsiveListScaffold.builder(
          scaffoldKey: _scaffoldKey,
          detailBuilder: (BuildContext context, int index, bool tablet) {
            var user = snap.data[index];
            return DetailsScreen(
              appBar: AppBar(
                elevation: 0.0,
                automaticallyImplyLeading: !tablet,
                title: Text(user.displayName),
                actions: [
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      if (!tablet) Get.back();
                    },
                  ),
                ],
              ),
              body: UsuarioPage(user)
            );
          },
          nullItems: Center(child: CircularProgressIndicator()),
          emptyItems: Center(child: Text("Nenhum usuário encontrado")),
          slivers: <Widget>[
            // SliverAppBar(
            //   automaticallyImplyLeading: false,
            //   title: Text("Usuários"),
            // ),
          ],
          itemCount: snap.data.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              leading: Text(snap.data[index].displayName),
            );
          },
          bottomNavigationBar: BottomAppBar(
            child: Text('100 usuários carregados'),
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              _scaffoldKey.currentState.showSnackBar(SnackBar(
                content: Text("Snackbar!"),
              ));
            },
          ),
        );
      },
    );
  }
}

class UsuariosListCtrl extends GetxController{
  Future<List<UserData>> getUsuarios() async {
    try {
      var tkn = await FirebaseAuth.instance.currentUser.getIdToken();
      var resp = await http.get(
        Uri.parse('$kUrlFunctions/api/users'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $tkn"},
      );
      if(resp.statusCode!=200) return Future.error(resp.body);

      List list = json.decode(resp.body);
      return list.map((e) => UserData.fromJson(e)).toList();
    }catch(erro, stack){
      print('$erro, $stack');
      rethrow;
    }
  }
}
