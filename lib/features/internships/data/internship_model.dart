import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/extensions/string_ext.dart';
import '../domain/entities/internship.dart';

Internship internshipFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  List<String> list(String key) =>
      ((d[key] as List?) ?? const []).cast<String>();
  return Internship(
    id: doc.id,
    startupId: d['startupId'] as String,
    startupName: (d['startupName'] as String?) ?? '',
    startupLogoUrl: d['startupLogoUrl'] as String?,
    title: (d['title'] as String?) ?? '',
    description: (d['description'] as String?) ?? '',
    responsibilities: list('responsibilities'),
    requirements: list('requirements'),
    skills: list('skills'),
    category: (d['category'] as String?) ?? 'Other',
    department: (d['department'] as String?) ?? '',
    tags: list('tags'),
    workMode: (d['workMode'] as String?) ?? 'On-site',
    employmentType: (d['employmentType'] as String?) ?? 'Part-time',
    location: (d['location'] as String?) ?? '',
    durationWeeks: (d['durationWeeks'] as num?)?.toInt() ?? 0,
    compensation: (d['compensation'] as String?) ?? '',
    deadline: (d['deadline'] as Timestamp?)?.toDate(),
    positions: (d['positions'] as num?)?.toInt() ?? 1,
    applicationInstructions: (d['applicationInstructions'] as String?) ?? '',
    status: InternshipStatus.values.firstWhere(
      (s) => s.name == d['status'],
      orElse: () => InternshipStatus.open,
    ),
    postedAt: (d['postedAt'] as Timestamp?)?.toDate(),
    viewsCount: (d['viewsCount'] as num?)?.toInt() ?? 0,
    applicantsCount: (d['applicantsCount'] as num?)?.toInt() ?? 0,
    searchTokens: list('searchTokens'),
  );
}

Map<String, dynamic> internshipToMap(Internship i, {bool creating = false}) => {
      'startupId': i.startupId,
      'startupName': i.startupName,
      'startupLogoUrl': i.startupLogoUrl,
      'title': i.title,
      'description': i.description,
      'responsibilities': i.responsibilities,
      'requirements': i.requirements,
      'skills': i.skills,
      'skillsLower': i.skills.map((s) => s.toLowerCase()).toList(),
      'category': i.category,
      'department': i.department,
      'tags': i.tags,
      'workMode': i.workMode,
      'employmentType': i.employmentType,
      'location': i.location,
      'durationWeeks': i.durationWeeks,
      'compensation': i.compensation,
      'isPaid': i.compensation.trim().isNotEmpty &&
          i.compensation.toLowerCase() != 'unpaid',
      'deadline': i.deadline == null ? null : Timestamp.fromDate(i.deadline!),
      'positions': i.positions,
      'applicationInstructions': i.applicationInstructions,
      'status': i.status.name,
      // Prefix tokens over title + startup name power "starts with" search
      // without an external search service.
      'searchTokens': '${i.title} ${i.startupName}'.searchTokens,
      if (creating) 'postedAt': FieldValue.serverTimestamp(),
      if (creating) 'viewsCount': 0,
      if (creating) 'applicantsCount': 0,
    };
