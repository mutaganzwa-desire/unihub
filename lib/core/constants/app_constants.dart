/// App-wide constants. Keeps magic numbers and strings out of feature code.
abstract final class AppConstants {
  static const appName = 'UniHub';
  static const pageSize = 15;
  static const maxResumeSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const maxImageSizeBytes = 3 * 1024 * 1024; // 3 MB
  static const allowedResumeExtensions = ['pdf'];
  static const internshipCategories = <String>[
    'Design', 'Engineering', 'Marketing', 'Data', 'Business',
    'Finance', 'Research', 'Operations', 'Other',
  ];
  static const workModes = <String>['Remote', 'Hybrid', 'On-site'];
  static const employmentTypes = <String>[
    'Part-time', 'Full-time', 'Project-based', 'Volunteer',
  ];
  static const fundingStages = <String>[
    'Idea', 'Pre-seed', 'Seed', 'Series A+', 'Bootstrapped',
  ];
  static const companySizes = <String>['1-5', '6-15', '16-50', '50+'];
}
