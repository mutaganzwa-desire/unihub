import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/internship.dart';
import '../domain/repositories/internship_repository.dart';
import 'internship_model.dart';

class InternshipRepositoryImpl implements InternshipRepository {
  InternshipRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.internships);

  @override
  Future<Result<InternshipPage>> fetchPage({
    required InternshipFilter filter,
    String? afterDocId,
  }) =>
      guard(() async {
        final snap = await _col.get();
        final parsed = <Internship>[];
        for (final d in snap.docs) {
          try {
            parsed.add(internshipFromDoc(d));
          } catch (e) {
            // Best-effort: skip malformed documents instead of failing the
            // entire query. Log for diagnostics.
            // ignore: avoid_print
            print('internshipFromDoc parse error for ${d.id}: $e');
          }
        }
        final all = parsed.where((item) {
          if (!item.isOpen) return false;
          if (filter.category != null && item.category != filter.category) {
            return false;
          }
          if (filter.workMode != null && item.workMode != filter.workMode) {
            return false;
          }
          if (filter.startupId != null && item.startupId != filter.startupId) {
            return false;
          }
          if (filter.skill != null) {
            final needle = filter.skill!.toLowerCase();
            final hasSkill = item.skills.any((s) => s.toLowerCase() == needle);
            if (!hasSkill) return false;
          }
          if (filter.maxDurationWeeks != null &&
              item.durationWeeks > filter.maxDurationWeeks!) {
            return false;
          }
          if (filter.paidOnly) {
            final compensation = item.compensation.trim().toLowerCase();
            if (compensation.isEmpty || compensation == 'unpaid') {
              return false;
            }
          }
          if (filter.searchQuery.trim().isNotEmpty) {
            final query = filter.searchQuery.trim().toLowerCase();
            final haystacks = <String>[
              item.title,
              item.startupName,
              item.description,
              ...item.skills,
              ...item.searchTokens,
            ].map((s) => s.toLowerCase());
            if (!haystacks.any((s) => s.contains(query))) {
              return false;
            }
          }
          return true;
        }).toList();

        all.sort((a, b) {
          switch (filter.sort) {
            case InternshipSort.popular:
              final byViews = b.viewsCount.compareTo(a.viewsCount);
              if (byViews != 0) return byViews;
              break;
            case InternshipSort.deadline:
              final aDeadline = a.deadline;
              final bDeadline = b.deadline;
              if (aDeadline == null && bDeadline != null) return 1;
              if (aDeadline != null && bDeadline == null) return -1;
              if (aDeadline != null && bDeadline != null) {
                final byDeadline = aDeadline.compareTo(bDeadline);
                if (byDeadline != 0) return byDeadline;
              }
              break;
            case InternshipSort.newest:
              break;
          }

          final aTime = a.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final byTime = bTime.compareTo(aTime);
          if (byTime != 0) return byTime;
          return a.id.compareTo(b.id);
        });

        var startIndex = 0;
        if (afterDocId != null) {
          final idx = all.indexWhere((item) => item.id == afterDocId);
          if (idx >= 0) startIndex = idx + 1;
        }

        final pageItems = all
            .skip(startIndex)
            .take(AppConstants.pageSize)
            .toList();
        return InternshipPage(
          pageItems,
          pageItems.isEmpty ? null : pageItems.last.id,
          startIndex + pageItems.length < all.length,
        );
      },
      mapError,
    );

  @override
  Stream<Internship?> watchInternship(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? internshipFromDoc(d) : null);

  @override
  Stream<List<Internship>> watchByStartup(String startupId) => _col
      .where('startupId', isEqualTo: startupId)
      .orderBy('postedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(internshipFromDoc).toList());

  @override
  Future<Result<String>> create(Internship internship) => guard(() async {
        final ref = await _col.add(internshipToMap(internship, creating: true));
        return ref.id;
      },
      mapError,
    );

  @override
  Future<Result<void>> update(Internship internship) => guard(
        () => _col.doc(internship.id).update(internshipToMap(internship)),
        mapError,
      );

  @override
  Future<Result<void>> setStatus(String id, InternshipStatus status) => guard(
        () => _col.doc(id).update({'status': status.name}),
        mapError,
      );

  @override
  Future<Result<void>> delete(String id) =>
      guard(() => _col.doc(id).delete(), mapError);

  @override
  Future<Result<String>> duplicate(Internship internship) => create(
        internship.copyWith(status: InternshipStatus.draft),
      );

  @override
  Future<void> registerView(String id) async {
    try {
      await _col.doc(id).update({'viewsCount': FieldValue.increment(1)});
    } on FirebaseException {
      // View counting is best-effort — never surface an error for it.
    }
  }
}
