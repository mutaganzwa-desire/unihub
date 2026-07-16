import 'package:equatable/equatable.dart';

class StudentProfile extends Equatable {
  const StudentProfile({
    required this.uid,
    required this.email,
    this.fullName = '',
    this.photoUrl,
    this.phone = '',
    this.program = '',
    this.yearOfStudy = 1,
    this.bio = '',
    this.skills = const [],
    this.interests = const [],
    this.preferredCategories = const [],
    this.portfolioUrl = '',
    this.githubUrl = '',
    this.linkedinUrl = '',
    this.resumeUrl,
    this.certificates = const [],
    this.projects = const [],
    this.location = '',
    this.availability = '',
  });

  final String uid;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String phone;
  final String program;
  final int yearOfStudy;
  final String bio;
  final List<String> skills;
  final List<String> interests;
  final List<String> preferredCategories;
  final String portfolioUrl;
  final String githubUrl;
  final String linkedinUrl;
  final String? resumeUrl;
  final List<String> certificates; // storage URLs
  final List<String> projects; // short descriptions / links
  final String location;
  final String availability;

  /// Weighted completion percentage shown on the profile and dashboard.
  int get completionPercent {
    final checks = <bool>[
      fullName.isNotEmpty,
      photoUrl != null,
      phone.isNotEmpty,
      program.isNotEmpty,
      bio.isNotEmpty,
      skills.isNotEmpty,
      interests.isNotEmpty,
      preferredCategories.isNotEmpty,
      resumeUrl != null,
      location.isNotEmpty,
      availability.isNotEmpty,
      githubUrl.isNotEmpty || linkedinUrl.isNotEmpty || portfolioUrl.isNotEmpty,
    ];
    final done = checks.where((c) => c).length;
    return ((done / checks.length) * 100).round();
  }

  @override
  List<Object?> get props => [uid, fullName, photoUrl, skills, resumeUrl, bio];
}
