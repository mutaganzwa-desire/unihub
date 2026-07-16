import '../../internships/domain/entities/internship.dart';
import '../../profile/domain/entities/student_profile.dart';

/// Content-based recommendation scorer.
///
/// Each candidate internship is scored against the student's profile signals
/// (skills, interests, preferred categories) plus behavioural signals
/// (categories they applied to or bookmarked before). This is a transparent,
/// explainable "ML-style" weighted overlap model — no training required, so
/// it runs client-side over the already-cached feed with zero extra reads.
class RecommendationEngine {
  const RecommendationEngine();

  static const _skillWeight = 3.0;
  static const _interestWeight = 1.5;
  static const _categoryWeight = 2.0;
  static const _behaviourWeight = 2.5;
  static const _freshnessWeight = 1.0;

  List<ScoredInternship> rank({
    required List<Internship> candidates,
    required StudentProfile? profile,
    required Set<String> appliedCategories,
    required Set<String> bookmarkedCategories,
  }) {
    final skills = _lower(profile?.skills ?? const []);
    final interests = _lower(profile?.interests ?? const []);
    final preferred = _lower(profile?.preferredCategories ?? const []);
    final behaviour = {...appliedCategories, ...bookmarkedCategories}
        .map((c) => c.toLowerCase())
        .toSet();

    final scored = candidates.map((internship) {
      final internshipSkills = _lower(internship.skills);
      final category = internship.category.toLowerCase();

      var score = 0.0;
      final reasons = <String>[];

      final skillOverlap = internshipSkills.intersection(skills).length;
      if (skillOverlap > 0) {
        score += skillOverlap * _skillWeight;
        reasons.add('$skillOverlap matching skill(s)');
      }

      final tagText = _lower([...internship.tags, internship.title]);
      final interestOverlap = tagText.intersection(interests).length;
      if (interestOverlap > 0) {
        score += interestOverlap * _interestWeight;
        reasons.add('matches your interests');
      }

      if (preferred.contains(category)) {
        score += _categoryWeight;
        reasons.add('in a preferred category');
      }
      if (behaviour.contains(category)) {
        score += _behaviourWeight;
        reasons.add('similar to roles you engaged with');
      }

      // Recency: newer posts get a small, decaying boost.
      final posted = internship.postedAt;
      if (posted != null) {
        final days = DateTime.now().difference(posted).inDays;
        score += (_freshnessWeight * (1 / (1 + days / 7))).clamp(0, 1);
      }

      return ScoredInternship(internship, score, reasons);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored;
  }

  Set<String> _lower(List<String> values) =>
      values.map((v) => v.toLowerCase().trim()).where((v) => v.isNotEmpty).toSet();
}

class ScoredInternship {
  const ScoredInternship(this.internship, this.score, this.reasons);
  final Internship internship;
  final double score;
  final List<String> reasons;

  bool get isRelevant => score > 0;
  String get reason =>
      reasons.isEmpty ? 'Recently posted' : reasons.first;
}
