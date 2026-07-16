import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../../internships/data/internship_model.dart';
import '../../internships/domain/entities/internship.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
  (ref) => BookmarkRepository(ref.watch(firestoreProvider)),
);

/// Bookmarks live at students/{uid}/bookmarks/{internshipId} and store a
/// snapshot of the internship so the saved list renders without N extra
/// reads. Realtime by construction (Firestore snapshots).
class BookmarkRepository {
  BookmarkRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _db
      .collection(FirestorePaths.students)
      .doc(uid)
      .collection(FirestorePaths.bookmarks);

  Stream<Set<String>> watchIds(String uid) =>
      _col(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Stream<List<Internship>> watchAll(String uid) =>
      _col(uid).orderBy('savedAt', descending: true).snapshots().map(
            (s) => s.docs.map(internshipFromDoc).toList(),
          );

  Future<void> toggle(String uid, Internship internship, bool bookmarked) {
    final doc = _col(uid).doc(internship.id);
    if (bookmarked) return doc.delete();
    return doc.set({
      ...internshipToMap(internship),
      'postedAt': internship.postedAt == null
          ? null
          : Timestamp.fromDate(internship.postedAt!),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }
}
