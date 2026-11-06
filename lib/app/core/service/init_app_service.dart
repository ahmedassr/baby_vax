import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/fire_store_helper_service.dart';
import 'package:baby_vax/app/core/service/get_storage_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Boots the app's services.
///
/// Order matters and used to be wrong: notifications were initialized before
/// GetStorage and before `GetStorageService` / `FireStoreHelperService` were
/// registered, so anything in that path that reached for storage or Firestore
/// was racing its own dependencies.
///
/// Correct order:
///   1. Firebase core — everything else depends on it
///   2. Crashlytics — installed early so failures in later steps are reported
///   3. App Check — before the first Firestore/Auth call
///   4. GetStorage, then the services that read it
///   5. session restore
///   6. notifications, which need all of the above
Future<void> initAppService() async {
  await Firebase.initializeApp();

  await _initCrashlytics();
  await _initAppCheck();

  await GetStorage.init();
  Get.put<GetStorageService>(GetStorageService(), permanent: true);
  Get.put<FireStoreHelperService>(FireStoreHelperService(), permanent: true);

  // Firestore keeps its own on-disk cache, so the app opens and the schedule
  // renders with no network. Enabled explicitly rather than relying on the
  // platform default.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  SessionManager.uId = AppConstant.getStorage.read(StorageKey.uidKey) ?? "";

  await NotificationInitializer.init();

  logger.i('App services initialized');
}

/// Routes uncaught Dart and platform errors to Crashlytics.
Future<void> _initCrashlytics() async {
  // Collecting from debug builds would bury real user crashes in noise from
  // development.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  // Framework errors (build, layout, paint).
  final FlutterExceptionHandler? previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    // Keep Flutter's own console reporting in debug.
    previousOnError?.call(details);
  };

  // Errors outside the Flutter callstack: async gaps, platform channels,
  // anything that reaches the engine unhandled.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Turns on App Check, which lets Firebase reject traffic that is not coming
/// from a genuine install of this app.
///
/// Play Integrity in release; the debug provider in debug, because Play
/// Integrity cannot attest a locally-built debug APK.
///
/// Enforcement is switched on per-service in the Firebase console, which only
/// Ahmed can do — see RELEASE_NOTES_FOR_AHMED.md. Until he does, this is
/// inert, so turning it on here cannot lock anyone out.
Future<void> _initAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          // Falls back to DeviceCheck on devices without App Attest.
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (e, s) {
    // A failure here must not stop the app from starting. Without a token
    // Firebase still serves requests unless enforcement is on.
    logger.w('App Check activation failed', error: e, stackTrace: s);
  }
}
