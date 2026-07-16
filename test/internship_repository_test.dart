import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unihub/features/internships/data/internship_repository_impl.dart';
import 'package:unihub/features/internships/domain/entities/internship.dart';

void main() {
  late FakeFirebaseFirestore db;
  late InternshipRepositoryImpl repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = InternshipRepositoryImpl(db);

    await db.collection('internships').doc('a').set({
      'startupId': 's1',
      'startupName': 'Acme',
      'title': 'Flutter Intern',
      'description': 'Build mobile features',
      'skills': ['Flutter'],
      'category': 'Engineering',
      'workMode': 'Remote',
      'compensation': 'Paid',
      'durationWeeks': 8,
      'viewsCount': 5,
      'deadline': Timestamp.fromDate(DateTime.utc(2027, 8, 1)),
      'status': 'open',
      'postedAt': Timestamp.fromDate(DateTime.utc(2027, 1, 1)),
    });

    await db.collection('internships').doc('b').set({
      'startupId': 's2',
      'startupName': 'Beta Labs',
      'title': 'Design Intern',
      'description': 'Support product design',
      'skills': ['Figma'],
      'category': 'Design',
      'workMode': 'On-site',
      'compensation': 'Unpaid',
      'durationWeeks': 4,
      'viewsCount': 20,
      'deadline': Timestamp.fromDate(DateTime.utc(2027, 4, 1)),
      'postedAt': Timestamp.fromDate(DateTime.utc(2027, 1, 2)),
    });
  });

  test('fetchPage includes internships that omit an explicit status', () async {
    final res = await repo.fetchPage(filter: const InternshipFilter());

    expect(res.isSuccess, isTrue);
    final page = res.dataOrNull!;
    expect(page.items.map((item) => item.id), containsAll(['a', 'b']));
  });

  test('fetchPage applies maxDurationWeeks filter', () async {
    final res = await repo.fetchPage(filter: const InternshipFilter(maxDurationWeeks: 5));

    expect(res.isSuccess, isTrue);
    final page = res.dataOrNull!;
    expect(page.items.map((item) => item.id), contains('b'));
    expect(page.items.map((item) => item.id), isNot(contains('a')));
  });

  test('fetchPage sorts by popular when selected', () async {
    final res = await repo.fetchPage(filter: const InternshipFilter(sort: InternshipSort.popular));

    expect(res.isSuccess, isTrue);
    final page = res.dataOrNull!;
    expect(page.items.first.id, 'b');
  });

  test('fetchPage sorts by deadline when selected', () async {
    final res = await repo.fetchPage(filter: const InternshipFilter(sort: InternshipSort.deadline));

    expect(res.isSuccess, isTrue);
    final page = res.dataOrNull!;
    expect(page.items.first.id, 'b');
  });
}
