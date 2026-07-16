import '../../../core/utils/result.dart';
import '../../profile/domain/entities/startup_profile.dart';

/// Verification request awaiting an admin decision.
class VerificationRequest {
  const VerificationRequest({
    required this.startupId,
    required this.startupName,
    required this.documents,
    required this.note,
    required this.status,
    this.submittedAt,
  });

  final String startupId;
  final String startupName;
  final List<String> documents;
  final String note;
  final String status;
  final DateTime? submittedAt;
}

class ContentReport {
  const ContentReport({
    required this.id,
    required this.reporterId,
    required this.targetType, // internship | user | message
    required this.targetId,
    required this.reason,
    required this.resolved,
    this.createdAt,
  });

  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String reason;
  final bool resolved;
  final DateTime? createdAt;
}

/// Admin domain contract. The consumer app ships without admin UI, but the
/// full capability set is architected here so an internal console (or Cloud
/// Functions callable) can implement it against the same schema. Every
/// method is gated by the `admin` role in Firestore security rules.
abstract interface class AdminRepository {
  Stream<List<VerificationRequest>> watchPendingVerifications();

  /// Approves/rejects a startup. Flips both the request and the startup's
  /// verificationStatus and notifies the founder.
  Future<Result<void>> decideVerification({
    required String startupId,
    required VerificationStatus decision, // verified | rejected
    String? reason,
  });

  Future<Result<void>> suspendUser(String uid, {required bool suspend});
  Future<Result<void>> deleteInternship(String internshipId);

  Stream<List<ContentReport>> watchOpenReports();
  Future<Result<void>> resolveReport(String reportId);

  Future<Result<void>> upsertCategory(String category);
  Future<Result<void>> removeCategory(String category);
}
