import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../applications/domain/application.dart';
import '../../applications/presentation/providers/application_providers.dart';
import '../../bookmarks/presentation/bookmark_providers.dart';
import '../../internships/domain/entities/internship.dart';
import '../../internships/presentation/providers/internship_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../domain/recommendation_engine.dart';

final recommendationEngineProvider =
    Provider<RecommendationEngine>((_) => const RecommendationEngine());

/// Recommended internships for the signed-in student, recomputed reactively
/// whenever the feed, profile, applications or bookmarks change.
final recommendedInternshipsProvider =
    Provider.autoDispose<AsyncValue<List<ScoredInternship>>>((ref) {
  const filter = InternshipFilter();
  final feed = ref.watch(internshipFeedProvider(filter));
  final profile = ref.watch(myStudentProfileProvider).value;
  final applications = ref.watch(myApplicationsProvider).value ?? const [];
  final bookmarks = ref.watch(bookmarkedInternshipsProvider).value ?? const [];
  final engine = ref.watch(recommendationEngineProvider);

  return feed.whenData((candidates) {
    final appliedIds = applications
        .where((a) => a.status != ApplicationStatus.withdrawn)
        .map((a) => a.internshipId)
        .toSet();

    final scored = engine.rank(
      candidates:
          candidates.where((i) => !appliedIds.contains(i.id)).toList(),
      profile: profile,
      appliedCategories: _categoriesFor(candidates, appliedIds),
      bookmarkedCategories: bookmarks.map((b) => b.category).toSet(),
    );
    // Prefer relevant matches, but never show an empty list to a new user.
    final relevant = scored.where((s) => s.isRelevant).toList();
    return (relevant.isNotEmpty ? relevant : scored).take(10).toList();
  });
});

Set<String> _categoriesFor(List<Internship> all, Set<String> ids) => all
    .where((i) => ids.contains(i.id))
    .map((i) => i.category)
    .toSet();
