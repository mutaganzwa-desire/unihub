/// Single source of truth for Firestore collection / subcollection names so
/// a typo can never silently split data across two collections.
abstract final class FirestorePaths {
  static const users = 'users';
  static const students = 'students';
  static const startups = 'startups';
  static const internships = 'internships';
  static const applications = 'applications';
  static const conversations = 'conversations';
  static const messages = 'messages'; // subcollection of conversations
  static const notifications = 'notifications';
  static const bookmarks = 'bookmarks'; // subcollection of students
  static const categories = 'categories';
  static const reports = 'reports';
  static const verificationRequests = 'verificationRequests';
  static const analytics = 'analytics';
  static const activityLogs = 'activityLogs';
}
