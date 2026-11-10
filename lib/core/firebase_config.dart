import 'package:firebase_core/firebase_core.dart';

/// القيم تأتي من --dart-define (GitHub Secrets) ولا تُكتب في الكود.
class FirebaseConfig {
  static const apiKey = String.fromEnvironment('FB_API_KEY');
  static const appId = String.fromEnvironment('FB_APP_ID');
  static const senderId = String.fromEnvironment('FB_SENDER_ID');
  static const projectId = String.fromEnvironment('FB_PROJECT_ID');
  static const storageBucket = String.fromEnvironment('FB_STORAGE_BUCKET');
  static const supportWhatsapp = String.fromEnvironment('SUPPORT_WHATSAPP');

  static bool ready = false;

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      senderId.isNotEmpty &&
      projectId.isNotEmpty;

  static FirebaseOptions get options => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
      );
}
