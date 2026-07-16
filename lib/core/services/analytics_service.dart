import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_providers.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(analyticsProvider)),
);

/// Thin, typed wrapper around Firebase Analytics so event names stay
/// consistent and greppable.
class AnalyticsService {
  AnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;

  Future<void> logSignUp(String role) =>
      _analytics.logSignUp(signUpMethod: 'email_$role');
  Future<void> logLogin() => _analytics.logLogin(loginMethod: 'email');
  Future<void> logInternshipView(String id) =>
      _analytics.logEvent(name: 'internship_view', parameters: {'id': id});
  Future<void> logApplicationSubmitted(String internshipId) => _analytics
      .logEvent(name: 'application_submit', parameters: {'id': internshipId});
  Future<void> logSearch(String term) => _analytics.logSearch(searchTerm: term);
  Future<void> setUser(String uid, String role) async {
    await _analytics.setUserId(id: uid);
    await _analytics.setUserProperty(name: 'role', value: role);
  }
}
