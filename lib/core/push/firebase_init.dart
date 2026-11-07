import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Starts Firebase from the native `google-services.json` config.
///
/// Returns false instead of throwing: push is an enhancement, so a phone
/// without Google Play services (or a build without the config) must still
/// start the app.
Future<bool> initFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } on Object catch (e) {
    debugPrint('Firebase unavailable: ${e.runtimeType}');
    return false;
  }
}
