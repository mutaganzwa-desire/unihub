import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_providers.dart';
import '../../internships/domain/entities/internship.dart';
import '../data/bookmark_repository.dart';

final bookmarkIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(const {});
  return ref.watch(bookmarkRepositoryProvider).watchIds(uid);
});

final bookmarkedInternshipsProvider =
    StreamProvider.autoDispose<List<Internship>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(bookmarkRepositoryProvider).watchAll(uid);
});

Future<void> toggleBookmark(WidgetRef ref, Internship internship) async {
  final uid = ref.read(currentUserProvider)?.uid;
  if (uid == null) return;
  final ids = ref.read(bookmarkIdsProvider).value ?? const {};
  await ref
      .read(bookmarkRepositoryProvider)
      .toggle(uid, internship, ids.contains(internship.id));
}
