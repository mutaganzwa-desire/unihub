import 'package:equatable/equatable.dart';

enum VerificationStatus {
  unverified,
  pending,
  verified,
  rejected;

  static VerificationStatus fromName(String? name) =>
      VerificationStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => VerificationStatus.unverified,
      );
}

class StartupProfile extends Equatable {
  const StartupProfile({
    required this.uid,
    required this.email,
    this.name = '',
    this.logoUrl,
    this.founder = '',
    this.description = '',
    this.mission = '',
    this.vision = '',
    this.industry = '',
    this.website = '',
    this.phone = '',
    this.officeLocation = '',
    this.socialLinks = const {},
    this.companySize = '',
    this.fundingStage = '',
    this.verificationStatus = VerificationStatus.unverified,
    this.documents = const [],
  });

  final String uid;
  final String email;
  final String name;
  final String? logoUrl;
  final String founder;
  final String description;
  final String mission;
  final String vision;
  final String industry;
  final String website;
  final String phone;
  final String officeLocation;
  final Map<String, String> socialLinks;
  final String companySize;
  final String fundingStage;
  final VerificationStatus verificationStatus;
  final List<String> documents;

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  int get completionPercent {
    final checks = <bool>[
      name.isNotEmpty,
      logoUrl != null,
      founder.isNotEmpty,
      description.isNotEmpty,
      mission.isNotEmpty,
      industry.isNotEmpty,
      website.isNotEmpty,
      phone.isNotEmpty,
      officeLocation.isNotEmpty,
      companySize.isNotEmpty,
      fundingStage.isNotEmpty,
    ];
    return ((checks.where((c) => c).length / checks.length) * 100).round();
  }

  @override
  List<Object?> get props => [uid, name, logoUrl, verificationStatus];
}
