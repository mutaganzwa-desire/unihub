import 'package:equatable/equatable.dart';

enum InternshipStatus { open, paused, closed, draft }

class Internship extends Equatable {
  const Internship({
    required this.id,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.title,
    required this.description,
    this.responsibilities = const [],
    this.requirements = const [],
    this.skills = const [],
    required this.category,
    this.department = '',
    this.tags = const [],
    required this.workMode,
    required this.employmentType,
    this.location = '',
    this.durationWeeks = 0,
    this.compensation = '',
    this.deadline,
    this.positions = 1,
    this.applicationInstructions = '',
    this.status = InternshipStatus.open,
    this.postedAt,
    this.viewsCount = 0,
    this.applicantsCount = 0,
    this.searchTokens = const [],
  });

  final String id;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final String title;
  final String description;
  final List<String> responsibilities;
  final List<String> requirements;
  final List<String> skills;
  final String category;
  final String department;
  final List<String> tags;
  final String workMode; // Remote / Hybrid / On-site
  final String employmentType;
  final String location;
  final int durationWeeks;
  final String compensation;
  final DateTime? deadline;
  final int positions;
  final String applicationInstructions;
  final InternshipStatus status;
  final DateTime? postedAt;
  final int viewsCount;
  final int applicantsCount;
  final List<String> searchTokens;

  bool get isOpen =>
      status == InternshipStatus.open &&
      (deadline == null || deadline!.isAfter(DateTime.now()));

  Internship copyWith({InternshipStatus? status, String? id}) => Internship(
        id: id ?? this.id,
        startupId: startupId,
        startupName: startupName,
        startupLogoUrl: startupLogoUrl,
        title: title,
        description: description,
        responsibilities: responsibilities,
        requirements: requirements,
        skills: skills,
        category: category,
        department: department,
        tags: tags,
        workMode: workMode,
        employmentType: employmentType,
        location: location,
        durationWeeks: durationWeeks,
        compensation: compensation,
        deadline: deadline,
        positions: positions,
        applicationInstructions: applicationInstructions,
        status: status ?? this.status,
        postedAt: postedAt,
        viewsCount: viewsCount,
        applicantsCount: applicantsCount,
        searchTokens: searchTokens,
      );

  @override
  List<Object?> get props => [id, title, status, applicantsCount, viewsCount];
}

/// Filter object the explore screen builds and the repository translates
/// into a Firestore query.
class InternshipFilter extends Equatable {
  const InternshipFilter({
    this.searchQuery = '',
    this.category,
    this.workMode,
    this.startupId,
    this.skill,
    this.maxDurationWeeks,
    this.paidOnly = false,
    this.sort = InternshipSort.newest,
  });

  final String searchQuery;
  final String? category;
  final String? workMode;
  final String? startupId;
  final String? skill;
  final int? maxDurationWeeks;
  final bool paidOnly;
  final InternshipSort sort;

  bool get isDefault =>
      searchQuery.isEmpty &&
      category == null &&
      workMode == null &&
      startupId == null &&
      skill == null &&
      maxDurationWeeks == null &&
      !paidOnly &&
      sort == InternshipSort.newest;

  InternshipFilter copyWith({
    String? searchQuery,
    String? Function()? category,
    String? Function()? workMode,
    String? Function()? skill,
    bool? paidOnly,
    InternshipSort? sort,
  }) =>
      InternshipFilter(
        searchQuery: searchQuery ?? this.searchQuery,
        category: category != null ? category() : this.category,
        workMode: workMode != null ? workMode() : this.workMode,
        startupId: startupId,
        skill: skill != null ? skill() : this.skill,
        maxDurationWeeks: maxDurationWeeks,
        paidOnly: paidOnly ?? this.paidOnly,
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props =>
      [searchQuery, category, workMode, startupId, skill, paidOnly, sort];
}

enum InternshipSort { newest, popular, deadline }
