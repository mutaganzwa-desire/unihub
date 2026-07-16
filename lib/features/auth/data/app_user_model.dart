import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/app_user.dart';

/// Data-layer mapping between [AppUser] and its Firestore document.
extension AppUserModel on AppUser {
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'role': role.name,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'fcmToken': fcmToken,
        'status': status.name,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}

AppUser appUserFromDoc(
  DocumentSnapshot<Map<String, dynamic>> doc, {
  required bool emailVerified,
}) {
  final d = doc.data() ?? const {};
  return AppUser(
    uid: doc.id,
    email: (d['email'] as String?) ?? '',
    role: UserRole.fromName(d['role'] as String?),
    emailVerified: emailVerified,
    displayName: (d['displayName'] as String?) ?? '',
    photoUrl: d['photoUrl'] as String?,
    fcmToken: d['fcmToken'] as String?,
    status: d['status'] == 'suspended'
        ? AccountStatus.suspended
        : AccountStatus.active,
    createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
  );
}
