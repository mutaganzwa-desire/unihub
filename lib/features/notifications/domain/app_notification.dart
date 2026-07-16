import 'package:equatable/equatable.dart';

enum NotificationType {
  applicationSubmitted,
  applicationAccepted,
  applicationRejected,
  applicationShortlisted,
  interviewScheduled,
  newInternship,
  newMessage,
  profileVerified,
  generic;

  static NotificationType fromName(String? name) =>
      NotificationType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => NotificationType.generic,
      );
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.route,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? route;
  final bool read;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, type, title, read];
}
