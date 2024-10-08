// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD5Olvc4W55Sc6kHnKrjb0kaL6ofI-aEu0',
    appId: '1:964817410391:web:6013d1f914a744b2db8612',
    messagingSenderId: '964817410391',
    projectId: 'ebooks-and-audiobooks-60245',
    authDomain: 'ebooks-and-audiobooks-60245.firebaseapp.com',
    storageBucket: 'ebooks-and-audiobooks-60245.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBqiOJc3hJb9iu4ddlRffF2yLkaOH6wGoE',
    appId: '1:964817410391:android:f888cdc87a868dbddb8612',
    messagingSenderId: '964817410391',
    projectId: 'ebooks-and-audiobooks-60245',
    storageBucket: 'ebooks-and-audiobooks-60245.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_5o6M-brrJtcsUxuuB92Dafjc3OEJZUs',
    appId: '1:964817410391:ios:1c3fc837946e868ddb8612',
    messagingSenderId: '964817410391',
    projectId: 'ebooks-and-audiobooks-60245',
    storageBucket: 'ebooks-and-audiobooks-60245.appspot.com',
    iosBundleId: 'com.ebooksandaudiobooks.ebooksAndAudiobooks',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA_5o6M-brrJtcsUxuuB92Dafjc3OEJZUs',
    appId: '1:964817410391:ios:1c3fc837946e868ddb8612',
    messagingSenderId: '964817410391',
    projectId: 'ebooks-and-audiobooks-60245',
    storageBucket: 'ebooks-and-audiobooks-60245.appspot.com',
    iosBundleId: 'com.ebooksandaudiobooks.ebooksAndAudiobooks',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD5Olvc4W55Sc6kHnKrjb0kaL6ofI-aEu0',
    appId: '1:964817410391:web:dac23f5831de580cdb8612',
    messagingSenderId: '964817410391',
    projectId: 'ebooks-and-audiobooks-60245',
    authDomain: 'ebooks-and-audiobooks-60245.firebaseapp.com',
    storageBucket: 'ebooks-and-audiobooks-60245.appspot.com',
  );
}
