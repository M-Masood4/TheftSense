// Firebase configuration for TheftSense project
// Web and Android only - iOS/macOS not supported

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return web; // Windows uses web config
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase is not configured for this platform. '
          'Only Web and Android are supported.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCrtMX2i2TYdAtl0Gb6ZJNgi1b7zVrI-C8',
    appId: '1:93686580855:web:39f4edcd7f2528bd10e872',
    messagingSenderId: '93686580855',
    projectId: 'theftsense',
    authDomain: 'theftsense.firebaseapp.com',
    storageBucket: 'theftsense.firebasestorage.app',
    measurementId: 'G-NQV6XQ7D3T',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBdgCUYiC0-eIrTFnoAOF_z7vGMpH7xS84',
    appId: '1:93686580855:android:792630936526c87010e872',
    messagingSenderId: '93686580855',
    projectId: 'theftsense',
    storageBucket: 'theftsense.firebasestorage.app',
  );
}
