import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../applications/domain/application.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../internships/domain/entities/internship.dart';
import '../../../internships/presentation/providers/internship_providers.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../../profile/domain/entities/startup_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class StartupDashboardScreen extends ConsumerWidget {
  const StartupDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(myStartupProfileProvider).value;
    final internships = ref.watch(myInternshipsProvider).value ?? const [];
    final applications =
        ref.watch(startupApplicationsProvider).value ?? const [];
    final unread = ref.watch(unreadNotificationCountProvider).value ?? 0;

    final activeCount =
        internships.where((i) => i.status == InternshipStatus.open).length;
    final totalViews = internships.fold<int>(0, (s, i) => s + i.viewsCount);
    final pendingApps = applications
        .where((a) =>
            a.status == ApplicationStatus.applied ||
            a.status == ApplicationStatus.underReview)
        .length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  UserAvatar(
                      url: startup?.logoUrl,
                      name: startup?.name ?? 'Startup',
                      radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(startup?.name ?? 'Your startup',
                            style: context.text.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (startup != null)
                          StatusChip(
                            status: startup.verificationStatus.name,
                            label: startup.isVerified
                                ? 'Verified'
                                : 'Not verified',
                          ),
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
                ],
              ),
            ),
            if (startup != null && !startup.isVerified)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: context.colors.primaryContainer.withOpacity(.5),
                  child: ListTile(
                    leading: Icon(Icons.verified_outlined,
                        color: context.colors.primary),
                    title: const Text('Get verified to post internships'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.pushNamed(RouteNames.verification),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _MetricCard(
                      icon: Icons.work_rounded,
                      label: 'Active internships',
                      value: '$activeCount',
                      color: context.colors.primary),
                  _MetricCard(
                      icon: Icons.people_rounded,
                      label: 'Total applicants',
                      value: '${applications.where((a) => a.status != ApplicationStatus.draft).length}',
                      color: context.colors.secondary),
                  _MetricCard(
                      icon: Icons.visibility_rounded,
                      label: 'Total views',
                      value: '$totalViews',
                      color: context.colors.tertiary),
                  _MetricCard(
                      icon: Icons.hourglass_bottom_rounded,
                      label: 'Pending review',
                      value: '$pendingApps',
                      color: context.colors.error),
                ],
              ),
            ),
            SectionHeader(
              title: 'Recent applicants',
              onSeeAll: () => context.goNamed(RouteNames.applicants),
            ),
            if (applications.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No applications yet.',
                    style: context.text.bodyMedium),
              )
            else
              ...applications
                  .where((a) => a.status != ApplicationStatus.draft)
                  .take(4)
                  .map(
                    (a) => ListTile(
                      leading: UserAvatar(
                          url: a.studentPhotoUrl, name: a.studentName),
                      title: Text(a.studentName),
                      subtitle: Text(a.internshipTitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: StatusChip(
                          status: a.status.name, label: a.status.label),
                      onTap: () => context.pushNamed(
                        RouteNames.applicationDetails,
                        pathParameters: {'id': a.id},
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.insights_rounded),
                label: const Text('View full analytics'),
                onPressed: () =>
                    context.pushNamed(RouteNames.startupAnalytics),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Text(value, style: context.text.headlineMedium),
            Text(label,
                style: context.text.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
