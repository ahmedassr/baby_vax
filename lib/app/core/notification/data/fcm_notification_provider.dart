import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../main.dart';

class FcmNotificationProvider {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getToken() => _messaging.getToken();

  Future<void> initialize({
    required void Function(RemoteMessage) onForeground,
    required void Function(RemoteMessage) onOpened,
  }) async {
    logger.i('🔔 Initializing FCM');
    final settings = await _messaging.requestPermission();
    logger.i('🔐 FCM permission status: ${settings.authorizationStatus.name}');
    FirebaseMessaging.onMessage.listen(onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(onOpened);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      logger.i('🚀 App opened from terminated by FCM');
      onOpened(initialMessage);
    }
  }
}
