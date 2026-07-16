import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_providers.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/profile_repository.dart';
import '../../domain/entities/startup_profile.dart';
import '../../domain/entities/student_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageServiceProvider),
  ),
);

final myStudentProfileProvider =
    StreamProvider.autoDispose<StudentProfile?>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(profileRepositoryProvider).watchStudent(uid);
});

final myStartupProfileProvider =
    StreamProvider.autoDispose<StartupProfile?>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(profileRepositoryProvider).watchStartup(uid);
});

/// Any user's public startup profile (details screens, applicant view).
final startupProfileProvider =
    StreamProvider.autoDispose.family<StartupProfile?, String>(
  (ref, uid) => ref.watch(profileRepositoryProvider).watchStartup(uid),
);

final studentProfileProvider =
    StreamProvider.autoDispose.family<StudentProfile?, String>(
  (ref, uid) => ref.watch(profileRepositoryProvider).watchStudent(uid),
);
