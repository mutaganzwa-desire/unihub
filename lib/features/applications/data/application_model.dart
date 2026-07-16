import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/application.dart';

Application applicationFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  final timeline = ((d['timeline'] as List?) ?? const [])
      .cast<Map<String, dynamic>>()
      .map(
        (e) => StatusEvent(
          ApplicationStatus.fromName(e['status'] as String?),
          (e['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ),
      )
      .toList();
  return Application(
    id: doc.id,
    internshipId: d['internshipId'] as String,
    internshipTitle: (d['internshipTitle'] as String?) ?? '',
    startupId: d['startupId'] as String,
    startupName: (d['startupName'] as String?) ?? '',
    startupLogoUrl: d['startupLogoUrl'] as String?,
    studentId: d['studentId'] as String,
    studentName: (d['studentName'] as String?) ?? '',
    studentPhotoUrl: d['studentPhotoUrl'] as String?,
    motivation: (d['motivation'] as String?) ?? '',
    resumeUrl: d['resumeUrl'] as String?,
    coverLetterUrl: d['coverLetterUrl'] as String?,
    status: ApplicationStatus.fromName(d['status'] as String?),
    timeline: timeline,
    appliedAt: (d['appliedAt'] as Timestamp?)?.toDate(),
  );
}

Map<String, dynamic> applicationToMap(Application a) => {
      'internshipId': a.internshipId,
      'internshipTitle': a.internshipTitle,
      'startupId': a.startupId,
      'startupName': a.startupName,
      'startupLogoUrl': a.startupLogoUrl,
      'studentId': a.studentId,
      'studentName': a.studentName,
      'studentPhotoUrl': a.studentPhotoUrl,
      'motivation': a.motivation,
      'resumeUrl': a.resumeUrl,
      'coverLetterUrl': a.coverLetterUrl,
      'status': a.status.name,
      'timeline': [
        {'status': a.status.name, 'at': Timestamp.now()},
      ],
      'appliedAt': FieldValue.serverTimestamp(),
    };
