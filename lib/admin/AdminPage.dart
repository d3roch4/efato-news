import 'package:efato/IHomePage.dart';
import 'package:efato/admin/GerenciarSelosPage.dart';
import 'package:efato/admin/users/UsuariosList.dart';
import 'package:flutter/material.dart';

class AdminPage extends IHomePage{

  @override
  Widget body() {
    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: TabBar(
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.people),
                text: 'Usuários',
              ),
              Tab(
                icon: Icon(Icons.library_books_outlined),
                text: 'Galeria',
              ),
              Tab(
                icon: Icon(Icons.category),
                text: 'Selos'
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            UsuariosList(),
            Center(
              child: Text('Olá'),
            ),
            GerenciarSelosPage(),
          ],
        ),
      ),
    );
  }

  @override
  Widget title() {
    return Text('Administração');
  }
}