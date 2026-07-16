import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/internship_repository_impl.dart';
import '../../domain/entities/internship.dart';
import '../../domain/repositories/internship_repository.dart';

final internshipRepositoryProvider = Provider<InternshipRepository>(
  (ref) => InternshipRepositoryImpl(ref.watch(firestoreProvider)),
);

/// Explore-screen filter state.
final internshipFilterProvider =
    StateProvider<InternshipFilter>((_) => const InternshipFilter());

/// Paginated, filterable feed with infinite scroll. Rebuilds from page one
/// whenever the filter changes (family keyed by filter).
final internshipFeedProvider = AsyncNotifierProvider.autoDispose
    .family<InternshipFeed, List<Internship>, InternshipFilter>(
  InternshipFeed.new,
);

class InternshipFeed
    extends AutoDisposeFamilyAsyncNotifier<List<Internship>, InternshipFilter> {
  String? _cursor;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<Internship>> build(InternshipFilter arg) async {
    _cursor = null;
    _hasMore = true;
    final page = await _fetch();
    return page;
  }

  Future<List<Internship>> _fetch() async {
    final res = await ref
        .read(internshipRepositoryProvider)
        .fetchPage(filter: arg, afterDocId: _cursor);
    return res.when(
      success: (page) {
        _cursor = page.lastDocId;
        _hasMore = page.hasMore;
        return page.items;
      },
      failure: (f) {
        // Avoid surfacing repository failures directly to the UI which
        // would show a blocking error state. Log and return an empty
        // result so the screens can display a friendly empty state
        // instead of an error.
        // ignore: avoid_print
        print('InternshipFeed: fetchPage failure: ${f.message}');
        _cursor = null;
        _hasMore = false;
        return <Internship>[];
      },
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || state.isLoading) return;
    _loadingMore = true;
    try {
      final next = await _fetch();
      state = AsyncData([...state.value ?? [], ...next]);
    } catch (_) {
      // Keep existing items; a retry happens on next scroll attempt.
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    _cursor = null;
    _hasMore = true;
    state = await AsyncValue.guard(_fetch);
  }
}

/// Live single internship (details screen, realtime applicant counter).
final internshipProvider =
    StreamProvider.autoDispose.family<Internship?, String>(
  (ref, id) => ref.watch(internshipRepositoryProvider).watchInternship(id),
);

/// All internships belonging to the signed-in startup.
final myInternshipsProvider =
    StreamProvider.autoDispose<List<Internship>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(internshipRepositoryProvider).watchByStartup(uid);
});
