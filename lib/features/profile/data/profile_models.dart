import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/startup_profile.dart';
import '../domain/entities/student_profile.dart';

List<String> _list(Map<String, dynamic> d, String key) =>
    ((d[key] as List?) ?? const []).cast<String>();

StudentProfile studentFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data() ?? const {};
  return StudentProfile(
    uid: doc.id,
    email: (d['email'] as String?) ?? '',
    fullName: (d['fullName'] as String?) ?? '',
    photoUrl: d['photoUrl'] as String?,
    phone: (d['phone'] as String?) ?? '',
    program: (d['program'] as String?) ?? '',
    yearOfStudy: (d['yearOfStudy'] as num?)?.toInt() ?? 1,
    bio: (d['bio'] as String?) ?? '',
    skills: _list(d, 'skills'),
    interests: _list(d, 'interests'),
    preferredCategories: _list(d, 'preferredCategories'),
    portfolioUrl: (d['portfolioUrl'] as String?) ?? '',
    githubUrl: (d['githubUrl'] as String?) ?? '',
    linkedinUrl: (d['linkedinUrl'] as String?) ?? '',
    resumeUrl: d['resumeUrl'] as String?,
    certificates: _list(d, 'certificates'),
    projects: _list(d, 'projects'),
    location: (d['location'] as String?) ?? '',
    availability: (d['availability'] as String?) ?? '',
  );
}

Map<String, dynamic> studentToMap(StudentProfile p) => {
      'email': p.email,
      'fullName': p.fullName,
      'photoUrl': p.photoUrl,
      'phone': p.phone,
      'program': p.program,
      'yearOfStudy': p.yearOfStudy,
      'bio': p.bio,
      'skills': p.skills,
      'skillsLower': p.skills.map((s) => s.toLowerCase()).toList(),
      'interests': p.interests,
      'preferredCategories': p.preferredCategories,
      'portfolioUrl': p.portfolioUrl,
      'githubUrl': p.githubUrl,
      'linkedinUrl': p.linkedinUrl,
      'resumeUrl': p.resumeUrl,
      'certificates': p.certificates,
      'projects': p.projects,
      'location': p.location,
      'availability': p.availability,
      'completionPercent': p.completionPercent,
      'updatedAt': FieldValue.serverTimestamp(),
    };

StartupProfile startupFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data() ?? const {};
  return StartupProfile(
    uid: doc.id,
    email: (d['email'] as String?) ?? '',
    name: (d['name'] as String?) ?? '',
    logoUrl: d['logoUrl'] as String?,
    founder: (d['founder'] as String?) ?? '',
    description: (d['description'] as String?) ?? '',
    mission: (d['mission'] as String?) ?? '',
    vision: (d['vision'] as String?) ?? '',
    industry: (d['industry'] as String?) ?? '',
    website: (d['website'] as String?) ?? '',
    phone: (d['phone'] as String?) ?? '',
    officeLocation: (d['officeLocation'] as String?) ?? '',
    socialLinks:
        ((d['socialLinks'] as Map?) ?? const {}).cast<String, String>(),
    companySize: (d['companySize'] as String?) ?? '',
    fundingStage: (d['fundingStage'] as String?) ?? '',
    verificationStatus:
        VerificationStatus.fromName(d['verificationStatus'] as String?),
    documents: _list(d, 'documents'),
  );
}

Map<String, dynamic> startupToMap(StartupProfile p) => {
      'email': p.email,
      'name': p.name,
      'logoUrl': p.logoUrl,
      'founder': p.founder,
      'description': p.description,
      'mission': p.mission,
      'vision': p.vision,
      'industry': p.industry,
      'website': p.website,
      'phone': p.phone,
      'officeLocation': p.officeLocation,
      'socialLinks': p.socialLinks,
      'companySize': p.companySize,
      'fundingStage': p.fundingStage,
      // verificationStatus intentionally NOT written here: only the
      // verification workflow / admin may change it (enforced by rules).
      'documents': p.documents,
      'completionPercent': p.completionPercent,
      'updatedAt': FieldValue.serverTimestamp(),
    };
