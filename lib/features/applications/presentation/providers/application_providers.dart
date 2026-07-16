import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../data/application_repository.dart';
import '../../domain/application.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>(
  (ref) => ApplicationRepository(
    ref.watch(firestoreProvider),
    ref.watch(notificationRepositoryProvider),
  ),
);

/// The signed-in student's applications, realtime.
final myApplicationsProvider =
    StreamProvider.autoDispose<List<Application>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(applicationRepositoryProvider).watchByStudent(uid);
});

/// Internship ids the student already applied to (disables Apply buttons).
final myApplicationIdsProvider = Provider.autoDispose<AsyncValue<Set<String>>>(
  (ref) => ref.watch(myApplicationsProvider).whenData(
        (apps) => apps
            .where((a) => a.status != ApplicationStatus.draft &&
                a.status != ApplicationStatus.withdrawn)
            .map((a) => a.internshipId)
            .toSet(),
      ),
);

typedef ApplicationStats = ({int total, int shortlisted, int accepted});

final myApplicationStatsProvider = Provider.autoDispose<ApplicationStats>(
  (ref) {
    final apps = ref.watch(myApplicationsProvider).value ?? const [];
    return (
      total: apps.where((a) => a.status != ApplicationStatus.draft).length,
      shortlisted: apps
          .where((a) => a.status == ApplicationStatus.shortlisted)
          .length,
      accepted:
          apps.where((a) => a.status == ApplicationStatus.accepted).length,
    );
  },
);

/// All applications across the startup's internships, realtime.
final startupApplicationsProvider =
    StreamProvider.autoDispose<List<Application>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(applicationRepositoryProvider).watchByStartup(uid);
});

final applicationProvider =
    StreamProvider.autoDispose.family<Application?, String>(
  (ref, id) => ref.watch(applicationRepositoryProvider).watchOne(id),
);
