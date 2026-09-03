// Generated from android/app/google-services.json
// Project: aiwearable-f9788

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCf15v9PDNOWwnx4SJKdtneNKL2MUtNsPk',
    appId: '1:124142724566:android:ac971b784f40e967c47077',
    messagingSenderId: '124142724566',
    projectId: 'aiwearable-f9788',
    storageBucket: 'aiwearable-f9788.firebasestorage.app',
  );
}
