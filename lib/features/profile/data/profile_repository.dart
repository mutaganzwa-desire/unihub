import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/startup_profile.dart';
import '../domain/entities/student_profile.dart';
import 'profile_models.dart';

/// Reads/writes both role profiles and runs the startup verification
/// request workflow.
class ProfileRepository {
  ProfileRepository(this._db, this._storage);
  final FirebaseFirestore _db;
  final StorageService _storage;

  Stream<StudentProfile?> watchStudent(String uid) => _db
      .collection(FirestorePaths.students)
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? studentFromDoc(d) : null);

  Stream<StartupProfile?> watchStartup(String uid) => _db
      .collection(FirestorePaths.startups)
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? startupFromDoc(d) : null);

  Future<Result<void>> saveStudent(StudentProfile p) => guard(() async {
        final batch = _db.batch();
        batch.set(
          _db.collection(FirestorePaths.students).doc(p.uid),
          studentToMap(p),
          SetOptions(merge: true),
        );
        // Mirror the public bits used across the app onto users/{uid}.
        batch.update(_db.collection(FirestorePaths.users).doc(p.uid), {
          'displayName': p.fullName,
          'photoUrl': p.photoUrl,
        });
        await batch.commit();
      }, mapError);

  Future<Result<void>> saveStartup(StartupProfile p) => guard(() async {
        final batch = _db.batch();
        batch.set(
          _db.collection(FirestorePaths.startups).doc(p.uid),
          startupToMap(p),
          SetOptions(merge: true),
        );
        batch.update(_db.collection(FirestorePaths.users).doc(p.uid), {
          'displayName': p.name,
          'photoUrl': p.logoUrl,
        });
        await batch.commit();
      }, mapError);

  Future<Result<String>> uploadStudentPhoto(String uid, Uint8List bytes,
          String fileName) =>
      guard(() => _storage.uploadProfilePicture(uid, bytes, fileName), mapError);

  Future<Result<String>> uploadStartupLogo(String uid, Uint8List bytes,
          String fileName) =>
      guard(() => _storage.uploadStartupLogo(uid, bytes, fileName), mapError);

  Future<Result<String>> uploadResume(String uid, Uint8List bytes,
          String fileName) =>
      guard(() => _storage.uploadResume(uid, bytes, fileName), mapError);

  /// Verification workflow: upload documents, create a request document the
  /// admin reviews, and flip the startup to `pending`.
  Future<Result<void>> submitVerificationRequest({
    required StartupProfile startup,
    required List<Uint8List> documents,
    required List<String> documentNames,
    required String note,
  }) =>
      guard(() async {
        final urls = <String>[];
        for (var i = 0; i < documents.length; i++) {
          urls.add(await _storage.uploadVerificationDocument(
            startup.uid,
            documents[i],
            documentNames[i],
          ));
        }
        final batch = _db.batch();
        batch.set(
          _db.collection(FirestorePaths.verificationRequests).doc(startup.uid),
          {
            'startupId': startup.uid,
            'startupName': startup.name,
            'documents': urls,
            'note': note,
            'status': 'pending',
            'submittedAt': FieldValue.serverTimestamp(),
          },
        );
        batch.update(
          _db.collection(FirestorePaths.startups).doc(startup.uid),
          {
            'verificationStatus': VerificationStatus.pending.name,
            'documents': FieldValue.arrayUnion(urls),
          },
        );
        await batch.commit();
      }, mapError);
}
