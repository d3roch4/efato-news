import 'dart:async';
import 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'configure.dart' as cfg;
import 'utils.dart';

void configureApp() {
  if(kDebugMode == false)
    setUrlStrategy(PathUrlStrategy());
  var splashScren = document.querySelector('#splashScren');
  Timer(Duration(milliseconds: 400), ()=> splashScren?.remove());
  cfg.configureApp();
  firestore.enablePersistence();
}