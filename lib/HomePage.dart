import 'package:endereco_formfield/endereco_formfield.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:efato/IHomePage.dart';
import 'package:efato/LoginPage.dart';
import 'package:efato/VisualizarNoticiaPage.dart';
import 'package:efato/dominio/Noticia.dart';
import 'package:efato/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:efato/widget/GridViewNoticias.dart';
import 'package:location/location.dart';
import 'LoginPage.dart';

class HomePage extends IHomePage{
  var ctrl = InicioCtrl();

  @override
  Widget body() {
    return StreamBuilder(
      stream: ctrl.localizacao.stream,
      builder: (c, snap){
        if(snap.hasError)
          return erroMsg(snap.error.toString());
        if(ctrl.localizacao.value == null)
          return carregando;
        var endereco = ctrl.localizacao.value;
        return Stack(children: [
          GoogleMap(
            mapType: MapType.terrain,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            liteModeEnabled: true,
            // markers: marcadores,
            gestureRecognizers: Set(),
            // scrollGesturesEnabled: false,
            initialCameraPosition: CameraPosition(target: LatLng(endereco.latitude, endereco.longitude), zoom: 15),
            onMapCreated: (c)=> ctrl.mapCtrl = c,
          ),
          Padding(
              padding: EdgeInsets.all(kPadding/2),
              child: Card(child: Padding(padding: EdgeInsets.all(8), child: EnderecoFormField(
                inputDecoration: InputDecoration(labelText: 'Localização (clique aqui para alterar)'),
                initialValue: endereco,
                onChanged: ctrl.mudarLocalizacao,
              )))
          ),
          Obx(()=> ctrl.noticias.value==null?
          carregando:
          DraggableScrollableSheet(
            initialChildSize: 0.45 ,
            minChildSize: 0.27,
            maxChildSize: 1,
            builder: (BuildContext context, myscrollController) {
              return Card(margin: EdgeInsets.zero, child: GridViewNoticias(
                scrollController: myscrollController,
                noticias: ctrl.noticias.value,
                onTap: ctrl.abrirNoticia,
                padding: EdgeInsets.all(kPadding),
              ));
            },
          )
          ),
        ]);
      },
    );
  }

  @override
  Widget trailing() {
    return null;
    if(usuarioLogado!= null)
      return ElevatedButton.icon(
        style: ButtonStyle(elevation: MaterialStateProperty.all(0)),
        icon: Icon(Icons.add_circle_outline),
        label: Text('Adicionar Notícia'),
      );

    return ElevatedButton.icon(
      style: ButtonStyle(elevation: MaterialStateProperty.all(0)),
      icon: Icon(Icons.login),
      label: Text('Login'),
      onPressed: ctrl.login,
    );
  }
}


class InicioCtrl extends GetxController{
  GoogleMapController mapCtrl;
  var localizacao = (Endereco()..latitude=-12.763503..longitude=-43.9509183).obs;
  var noticias = Rx<List<Noticia>>(null);

  InicioCtrl() {
    initEndereco();
    mudarLocalizacao(localizacao.value);
  }

  Future<void> initEndereco() async {
    var location = new Location();
    bool _serviceEnabled;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled && localizacao.value==null) {
        return localizacao.subject.addError('Não foi posssível obter a localização', StackTrace.current);
      }
    }
    var permissao = await location.requestPermission();
    if(permissao == PermissionStatus.denied || permissao == PermissionStatus.deniedForever && localizacao.value==null)
      return localizacao.addError('Não foi posssível obter a localização', StackTrace.current);

    var loc = await location.getLocation();
    mudarLocalizacao(Endereco()
      ..latitude = loc.latitude
      ..longitude = loc.longitude);
  }

  Future<void> login() async {
    if(await LoginPage.login() == true)
      Get.offAndToNamed('/');
  }

  Future<void> abrirNoticia(Noticia noticia) async {
    await Get.toNamed('/n/${noticia.id}', arguments: noticia, preventDuplicates: false);
    // Get.off(VisualizarNoticiaPage(noticia));
  }

  void mudarLocalizacao(Endereco endereco) {
    var collectionReference = firestore.collection('noticias');
    double radius = 50;
    String field = 'geopoint';
    final geo = GeoFlutterFire();
    GeoFirePoint center = geo.point(latitude: endereco.latitude, longitude: endereco.longitude);

    var stream = geo.collection(collectionRef: collectionReference)
        .within(center: center, radius: radius, field: field)
        .map((itens) => itens.map(
            (e) => Noticia.fromJson(e.data())..id = e.id).toList()
    );
    noticias.bindStream(stream);

    localizacao.value = endereco;
    mapCtrl?.animateCamera(CameraUpdate.newLatLng(LatLng(endereco.latitude, endereco.longitude)));
  }
}