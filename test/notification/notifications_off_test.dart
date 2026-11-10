import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/notification/data/notification_settings_opener.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/home/widgets/notifications_off_banner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  group('HomeController.notificationsOff', () {
    test('true when signed in and notifications are off', () async {
      SessionManager.authUid = () => 'alice';
      final c = HomeController(notificationsEnabled: () async => false);
      await c.refreshNotificationStatus();
      expect(c.notificationsOff.value, isTrue);
    });

    test('false when notifications are on', () async {
      SessionManager.authUid = () => 'alice';
      final c = HomeController(notificationsEnabled: () async => true);
      await c.refreshNotificationStatus();
      expect(c.notificationsOff.value, isFalse);
    });

    test('false while signed out, whatever the OS says', () async {
      final c = HomeController(notificationsEnabled: () async => false);
      await c.refreshNotificationStatus();
      expect(c.notificationsOff.value, isFalse);
    });

    test('turning notifications back on clears the banner', () async {
      SessionManager.authUid = () => 'alice';
      bool enabled = false;
      final c = HomeController(notificationsEnabled: () async => enabled);
      await c.refreshNotificationStatus();
      expect(c.notificationsOff.value, isTrue);
      enabled = true; // user flips the switch in settings, app resumes
      await c.refreshNotificationStatus();
      expect(c.notificationsOff.value, isFalse);
    });
  });

  test('NotificationCoordinator reports the OS status', () async {
    final fake = FakeNotificationService()..notificationsEnabled = false;
    Get.put<NotificationService>(fake);
    final coordinator = NotificationCoordinator()
      ..overrideNotificationService(fake);
    expect(await coordinator.notificationsEnabled(), isFalse);
    fake.notificationsEnabled = true;
    expect(await coordinator.notificationsEnabled(), isTrue);
  });

  test('NotificationSettingsOpener calls the platform channel', () async {
    final List<String> calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NotificationSettingsOpener.channel,
            (call) async {
      calls.add(call.method);
      return true;
    });
    expect(await const NotificationSettingsOpener().open(), isTrue);
    expect(calls, ['openNotificationSettings']);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NotificationSettingsOpener.channel, null);
  });

  testWidgets('banner shows the message and opens settings', (tester) async {
    Get.addTranslations(AppTranslations().keys);
    int taps = 0;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => GetMaterialApp(
        locale: const Locale('en'),
        translationsKeys: AppTranslations().keys,
        home: Scaffold(
          body: NotificationsOffBanner(onOpenSettings: () => taps++),
        ),
      ),
    ));
    await tester.pump();
    expect(find.textContaining('Notifications are turned off'), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('open_notification_settings_button')));
    expect(taps, 1);
  });
}
