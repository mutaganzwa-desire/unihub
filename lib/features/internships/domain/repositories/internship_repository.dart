import '../../../../core/utils/result.dart';
import '../entities/internship.dart';

/// One page of results plus the cursor needed to fetch the next one.
class InternshipPage {
  const InternshipPage(this.items, this.lastDocId, this.hasMore);
  final List<Internship> items;
  final String? lastDocId;
  final bool hasMore;
}

abstract interface class InternshipRepository {
  Future<Result<InternshipPage>> fetchPage({
    required InternshipFilter filter,
    String? afterDocId,
  });

  Stream<Internship?> watchInternship(String id);
  Stream<List<Internship>> watchByStartup(String startupId);

  Future<Result<String>> create(Internship internship);
  Future<Result<void>> update(Internship internship);
  Future<Result<void>> setStatus(String id, InternshipStatus status);
  Future<Result<void>> delete(String id);
  Future<Result<String>> duplicate(Internship internship);
  Future<void> registerView(String id);
}
