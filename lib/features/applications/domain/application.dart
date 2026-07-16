import 'package:equatable/equatable.dart';

enum ApplicationStatus {
  draft,
  applied,
  underReview,
  shortlisted,
  interview,
  accepted,
  rejected,
  withdrawn,
  archived;

  static ApplicationStatus fromName(String? name) =>
      ApplicationStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => ApplicationStatus.applied,
      );

  String get label => switch (this) {
        ApplicationStatus.underReview => 'Under review',
        ApplicationStatus.interview => 'Interview scheduled',
        _ => '${name[0].toUpperCase()}${name.substring(1)}',
      };
}

/// One entry in the status timeline shown to the student.
class StatusEvent extends Equatable {
  const StatusEvent(this.status, this.at);
  final ApplicationStatus status;
  final DateTime at;

  @override
  List<Object?> get props => [status, at];
}

class Application extends Equatable {
  const Application({
    required this.id,
    required this.internshipId,
    required this.internshipTitle,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.studentId,
    required this.studentName,
    this.studentPhotoUrl,
    this.motivation = '',
    this.resumeUrl,
    this.coverLetterUrl,
    this.status = ApplicationStatus.applied,
    this.timeline = const [],
    this.appliedAt,
  });

  final String id;
  final String internshipId;
  final String internshipTitle;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final String studentId;
  final String studentName;
  final String? studentPhotoUrl;
  final String motivation;
  final String? resumeUrl;
  final String? coverLetterUrl;
  final ApplicationStatus status;
  final List<StatusEvent> timeline;
  final DateTime? appliedAt;

  bool get isActive =>
      status != ApplicationStatus.withdrawn &&
      status != ApplicationStatus.rejected &&
      status != ApplicationStatus.draft;

  @override
  List<Object?> get props => [id, status, timeline];
}
