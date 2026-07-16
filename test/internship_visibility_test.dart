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
  });

  test('internship created via repo.create is visible in fetchPage', () async {
    final internship = Internship(
      id: '',
      startupId: 'ts1',
      startupName: 'TalentSeeker',
      title: 'Talent Seeker Intern',
      description: 'Posted by talent seeker',
      skills: ['Dart'],
      category: 'Engineering',
      workMode: 'Remote',
      employmentType: 'Part-time',
      compensation: 'Paid',
    );

    final created = await repo.create(internship);
    expect(created.isSuccess, isTrue);
    final id = created.dataOrNull!;
    expect(id, isNotEmpty);

    final page = (await repo.fetchPage(filter: const InternshipFilter())).dataOrNull!;
    expect(page.items.map((i) => i.id), contains(id));
  });
}
