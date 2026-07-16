import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../applications/domain/application.dart';
import '../../applications/presentation/providers/application_providers.dart';
import '../../internships/domain/entities/internship.dart';
import '../../internships/presentation/providers/internship_providers.dart';

typedef StartupAnalytics = ({
  int totalViews,
  int totalApplications,
  double conversionRate,
  List<MapEntry<String, int>> applicationsByStatus,
  List<Internship> topInternships,
  List<MapEntry<String, int>> applicationTrend, // last 7 days
});

/// Derives all analytics from the already-streamed internships +
/// applications — no extra reads, always live.
final startupAnalyticsProvider = Provider.autoDispose<StartupAnalytics>((ref) {
  final internships = ref.watch(myInternshipsProvider).value ?? const [];
  final applications = (ref.watch(startupApplicationsProvider).value ?? const [])
      .where((a) => a.status != ApplicationStatus.draft)
      .toList();

  final totalViews = internships.fold<int>(0, (s, i) => s + i.viewsCount);
  final totalApplications = applications.length;
  final conversion =
      totalViews == 0 ? 0.0 : (totalApplications / totalViews) * 100;

  final byStatus = <String, int>{};
  for (final a in applications) {
    byStatus[a.status.label] = (byStatus[a.status.label] ?? 0) + 1;
  }

  final top = [...internships]
    ..sort((a, b) => b.applicantsCount.compareTo(a.applicantsCount));

  // Applications per day for the last 7 days.
  final now = DateTime.now();
  final trend = <MapEntry<String, int>>[];
  for (var d = 6; d >= 0; d--) {
    final day = DateTime(now.year, now.month, now.day - d);
    final label = '${day.day}/${day.month}';
    final count = applications.where((a) {
      final at = a.appliedAt;
      return at != null &&
          at.year == day.year &&
          at.month == day.month &&
          at.day == day.day;
    }).length;
    trend.add(MapEntry(label, count));
  }

  return (
    totalViews: totalViews,
    totalApplications: totalApplications,
    conversionRate: conversion,
    applicationsByStatus: byStatus.entries.toList(),
    topInternships: top.take(5).toList(),
    applicationTrend: trend,
  );
});
