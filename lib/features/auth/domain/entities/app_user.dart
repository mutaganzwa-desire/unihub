import 'package:equatable/equatable.dart';

enum UserRole {
  student,
  startup,
  admin;

  static UserRole fromName(String? name) => UserRole.values.firstWhere(
        (r) => r.name == name,
        orElse: () => UserRole.student,
      );
}

enum AccountStatus { active, suspended }

/// The authenticated identity shared by both roles. Role-specific data lives
/// in the `students` / `startups` collections (see profile feature).
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.emailVerified,
    this.displayName = '',
    this.photoUrl,
    this.fcmToken,
    this.status = AccountStatus.active,
    this.createdAt,
  });

  final String uid;
  final String email;
  final UserRole role;
  final bool emailVerified;
  final String displayName;
  final String? photoUrl;
  final String? fcmToken;
  final AccountStatus status;
  final DateTime? createdAt;

  bool get isStudent => role == UserRole.student;
  bool get isStartup => role == UserRole.startup;

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    String? fcmToken,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        role: role,
        emailVerified: emailVerified ?? this.emailVerified,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        fcmToken: fcmToken ?? this.fcmToken,
        status: status,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [uid, email, role, emailVerified, displayName, photoUrl, status];
}
