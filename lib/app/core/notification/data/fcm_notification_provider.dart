import 'package:firebase_messaging/firebase_messaging.dart';

class FcmNotificationProvider {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getToken() => _messaging.getToken();

  Future<void> initialize({
    required void Function(RemoteMessage) onForeground,
    required void Function(RemoteMessage) onOpened,
  }) async{
    await _messaging.requestPermission();

    FirebaseMessaging.onMessage.listen(onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(onOpened);

    final initialMessage = await _messaging.getInitialMessage();
    if(initialMessage != null){
      onOpened(initialMessage);
    }
  }


}
