import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../internships/domain/entities/internship.dart';
import '../../../internships/presentation/providers/internship_providers.dart';
import '../../../internships/presentation/widgets/internship_card.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../dashboard_providers.dart';
import '../widgets/category_row.dart';
import '../widgets/completion_prompt.dart';
import '../widgets/recommended_card.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(currentUserProvider);
      if (auth != null) {
        ref.invalidate(recommendedInternshipsProvider);
        ref.invalidate(internshipFeedProvider(InternshipFilter()));
        // ignore: avoid_print
        print('StudentHomeScreen: invalidated internshipFeed after init');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myStudentProfileProvider).value;
    final recommended = ref.watch(recommendedInternshipsProvider);
    final recent = ref.watch(internshipFeedProvider(InternshipFilter()));
    final unread = ref.watch(unreadNotificationCountProvider).value ?? 0;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName.split(' ').first
        : 'there';

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          ref.invalidate(recommendedInternshipsProvider);
          ref.invalidate(internshipFeedProvider(InternshipFilter()));
        },
        tooltip: 'Refresh internships',
        child: const Icon(Icons.refresh),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(internshipFeedProvider(InternshipFilter()).notifier)
              .refresh(),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, $name 👋',
                              style: context.text.headlineMedium),
                          Text('Find meaningful ways to contribute.',
                              style: context.text.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () =>
                            context.pushNamed(RouteNames.notifications),
                      ),
                    ),
                    const SizedBox(width: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: () => context.pushNamed(RouteNames.studentProfile),
                        child: UserAvatar(
                            url: profile?.photoUrl,
                            name: profile?.fullName ?? name,
                            radius: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.pushNamed(RouteNames.explore),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded,
                              color: context.colors.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text('Search opportunities...',
                              style: context.text.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (profile != null)
                CompletionPrompt(percent: profile.completionPercent),
              const SectionHeader(title: 'Recommended'),
              SizedBox(
                height: 210,
                child: recommended.when(
                  loading: () => const ListSkeleton(items: 1, height: 200),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (items) => items.isEmpty
                      ? Center(
                          child: Text(
                              'Apply and save roles to get tailored picks.',
                              style: context.text.bodySmall))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 16),
                          itemCount: items.length,
                          itemBuilder: (_, i) =>
                              RecommendedCard(scored: items[i]),
                        ),
                ),
              ),
              SectionHeader(
                title: 'Browse by category',
                onSeeAll: () => context.pushNamed(RouteNames.explore),
              ),
              CategoryRow(
                  onSelected: (_) => context.pushNamed(RouteNames.explore)),
              SectionHeader(
                title: 'Recent opportunities',
                onSeeAll: () => context.pushNamed(RouteNames.explore),
              ),
              recent.when(
                loading: () => const ListSkeleton(items: 3),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => Column(
                  children: items
                      .take(5)
                      .map((i) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: InternshipCard(internship: i),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
