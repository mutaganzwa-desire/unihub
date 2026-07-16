import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'core/services/notification_service.dart';
import 'firebase_options.dart';

/// Initializes every platform service the app depends on before the first
/// frame: Firebase core, Crashlytics hooks, Firestore offline cache and
/// push notifications.
Future<void> bootstrap() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure Firestore.
  if (kIsWeb) {
    // On web, disable persistence to avoid auth context issues.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } else {
    // On native platforms, enable offline cache.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Crash reporting: capture uncaught Flutter and platform errors.
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  await NotificationService.instance.initialize();
}
