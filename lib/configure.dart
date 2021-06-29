import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'utils.dart';

Future<void> configureApp() async {
  if(false && kDebugMode){
    kUrlFunctions = 'http://localhost:5001/efato132/us-central1';
    firestore.settings = Settings(
        host: 'localhost:8080',
        sslEnabled: false,
    );
  }
}