import 'package:firebase_core/firebase_core.dart';

/// Configuração via --dart-define. Assim o mesmo código continua compilando
/// em modo local enquanto o projeto Firebase definitivo ainda não foi ligado.
class AulaFacilFirebaseOptions {
  static FirebaseOptions? get current {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

    if (apiKey.isEmpty || appId.isEmpty || messagingSenderId.isEmpty || projectId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
    );
  }
}
