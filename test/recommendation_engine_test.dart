import 'package:flutter_test/flutter_test.dart';
import 'package:unihub/features/dashboard/domain/recommendation_engine.dart';
import 'package:unihub/features/internships/domain/entities/internship.dart';
import 'package:unihub/features/profile/domain/entities/student_profile.dart';

Internship _mk(String id, String category, List<String> skills) => Internship(
      id: id,
      startupId: 's',
      startupName: 'Startup',
      title: '$category role',
      description: '',
      category: category,
      workMode: 'Remote',
      employmentType: 'Part-time',
      skills: skills,
      postedAt: DateTime.now(),
    );

void main() {
  const engine = RecommendationEngine();

  test('ranks skill-matching internships above unrelated ones', () {
    const profile = StudentProfile(
      uid: 'u',
      email: 'u@x.com',
      skills: ['Flutter', 'Dart'],
      preferredCategories: ['Engineering'],
    );

    final results = engine.rank(
      candidates: [
        _mk('a', 'Design', ['Figma']),
        _mk('b', 'Engineering', ['Flutter', 'Dart']),
      ],
      profile: profile,
      appliedCategories: const {},
      bookmarkedCategories: const {},
    );

    expect(results.first.internship.id, 'b');
    expect(results.first.isRelevant, isTrue);
    expect(results.first.reasons, isNotEmpty);
  });

  test('behavioural signals boost matching categories', () {
    const profile = StudentProfile(uid: 'u', email: 'u@x.com');
    final results = engine.rank(
      candidates: [
        _mk('a', 'Design', const []),
        _mk('b', 'Marketing', const []),
      ],
      profile: profile,
      appliedCategories: const {'Marketing'},
      bookmarkedCategories: const {},
    );
    expect(results.first.internship.id, 'b');
  });
}
