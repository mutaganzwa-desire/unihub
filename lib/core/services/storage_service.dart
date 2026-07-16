import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'firebase_providers.dart';

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(firebaseStorageProvider)),
);

/// Central file-upload service — every feature (profiles, applications,
/// chat) reuses it instead of talking to Firebase Storage directly.
class StorageService {
  StorageService(this._storage);
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  Future<String> uploadProfilePicture(
    String uid,
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(
        'users/$uid/profile/${_uuid.v4()}${_extFromName(fileName)}',
        bytes: bytes,
      );

  Future<String> uploadStartupLogo(
    String uid,
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(
        'startups/$uid/logo/${_uuid.v4()}${_extFromName(fileName)}',
        bytes: bytes,
      );

  Future<String> uploadResume(
    String uid,
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(
        'users/$uid/resumes/${_uuid.v4()}${_extFromName(fileName)}',
        bytes: bytes,
      );

  Future<String> uploadCoverLetter(
    String uid,
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(
        'users/$uid/coverLetters/${_uuid.v4()}${_extFromName(fileName)}',
        bytes: bytes,
      );

  Future<String> uploadCertificate(
    String uid,
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(
        'users/$uid/certificates/${_uuid.v4()}${_extFromName(fileName)}',
        bytes: bytes,
      );

  Future<String> uploadVerificationDocument(
    String uid,
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(
        'startups/$uid/documents/${_uuid.v4()}${_extFromName(fileName)}',
        bytes: bytes,
      );

  Future<String> uploadChatAttachment(
    String conversationId,
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(
        'chats/$conversationId/${_uuid.v4()}${_extFromName(fileName)}',
        bytes: bytes,
      );

  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException {
      // Already deleted or unreachable — safe to ignore on cleanup paths.
    }
  }

  Future<String> _upload(String path, {Uint8List? bytes}) async {
    if (bytes == null || bytes.isEmpty) {
      throw ArgumentError('No file data provided for upload.');
    }

    final metadata = SettableMetadata(
      contentType: _contentTypeFromName(path),
    );
    final task = await _storage.ref(path).putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  String _contentTypeFromName(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  String _extFromName(String fileName) {
    final i = fileName.lastIndexOf('.');
    return i == -1 ? '' : fileName.substring(i);
  }
}
