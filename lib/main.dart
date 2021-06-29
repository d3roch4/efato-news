import 'package:efato/HomePage.dart';
import 'package:efato/DadosAcessoEditarPage.dart';
import 'package:efato/VisualizarNoticiaPage.dart';
import 'package:efato/minhas-noticias/GerirMinhasNoticiasPage.dart';
import 'package:efato/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'LoginPage.dart';
import 'admin/AdminPage.dart';
import 'configure.dart' if (dart.library.html) 'configure_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureApp();
  await Firebase.initializeApp();

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var buttonTheme = ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        textTheme: ButtonTextTheme.primary
    );
    var outlinedButtonTheme = OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
    ));
    var elevetedButtonTheme = ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
    ));
    var bottomAppBarTheme = BottomAppBarTheme(
      color: Colors.orangeAccent,
      elevation: 16,
      shape: AutomaticNotchedShape(
          RoundedRectangleBorder(),
          GetPlatform.isWeb ? null : StadiumBorder(side: BorderSide())
      ),
    );
    var temaClaro = ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.white,
        buttonTheme: buttonTheme,
        outlinedButtonTheme: outlinedButtonTheme,
        elevatedButtonTheme: elevetedButtonTheme,
        bottomAppBarTheme: bottomAppBarTheme,
        // dividerTheme: DividerTheme(),
        cardTheme: CardTheme(elevation: kPadding),
       appBarTheme: AppBarTheme(brightness: Brightness.dark)
    );
    var temaEscuro = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.red,
      primaryColor: Colors.red,
      accentColor: Colors.redAccent,
      scaffoldBackgroundColor: Colors.black,
      bottomAppBarTheme: bottomAppBarTheme.copyWith(color: Colors.white10),
      dividerColor: Colors.white60,
      buttonTheme: buttonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      elevatedButtonTheme: elevetedButtonTheme,
        appBarTheme: AppBarTheme(brightness: Brightness.light)
    );

    return GetMaterialApp(
      title: kAppNome,
      theme: temaClaro,
      darkTheme: temaEscuro,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('pt', 'BR'),
      ],
      getPages: [
        GetPage(name: '/', page: ()=> HomePage()),
        GetPage(name: '/n/:id', page: ()=> VisualizarNoticiaPage()),
        GetPage(name: '/dados-acesso', page: ()=>DadosAcessoEditarPage()),
        GetPage(name: '/admin', page: ()=>AdminPage()),
        GetPage(name: '/minhas-noticias', page: ()=>GerirMinhasNoticiasPage()),
      ],
      unknownRoute: GetPage(name: '/'),
      routingCallback: (route){
        var user = FirebaseAuth.instance.currentUser;
        if(route.current == '/admin'){
          if(user==null) //Get.toNamed('/login?returnTo=/admin');
            LoginPage.login().then((value){
              if(value==true) Get.offNamed('/admin');
              else informarAcessoRestritoEVoltar();
            });
          else
            user.getIdTokenResult().then((tkn){
              if(tkn.claims['role']=='admin') return;
              informarAcessoRestritoEVoltar();
            });
        }
      }
    );
  }

  Widget paginaInicial(){
    print('paginaInicial');
    return StreamBuilder<User>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (c, snap){
        if(snap.connectionState==ConnectionState.waiting && usuarioLogado==null)
          return Center(child: CircularProgressIndicator());
        return HomePage();
      },
    );
  }

  informarAcessoRestritoEVoltar(){
    Get.snackbar("Acesso Restrito", "Você não tem permissão para acessar essa página");
    Get.offAndToNamed('/');
  }
}

class ContadorPage extends StatefulWidget {
  ContadorPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ContadorPageState createState() => _ContadorPageState();
}

class _ContadorPageState extends State<ContadorPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
