import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../bookmarks/presentation/bookmark_providers.dart';
import '../../domain/entities/internship.dart';
import '../providers/internship_providers.dart';

class InternshipDetailsScreen extends ConsumerStatefulWidget {
  const InternshipDetailsScreen({super.key, required this.internshipId});
  final String internshipId;

  @override
  ConsumerState<InternshipDetailsScreen> createState() =>
      _InternshipDetailsScreenState();
}

class _InternshipDetailsScreenState
    extends ConsumerState<InternshipDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Count the view once per open; used by startup analytics.
    Future.microtask(() {
      ref
          .read(internshipRepositoryProvider)
          .registerView(widget.internshipId);
      ref.read(analyticsServiceProvider).logInternshipView(widget.internshipId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(internshipProvider(widget.internshipId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunity details'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              final i = async.value;
              if (i != null) {
                Share.share(
                  '${i.title} at ${i.startupName} on UniHub — unihub://internships/${i.id}',
                );
              }
            },
          ),
        ],
      ),
      body: AsyncView(
        value: async,
        onRetry: () =>
            ref.invalidate(internshipProvider(widget.internshipId)),
        builder: (internship) {
          if (internship == null) {
            return const EmptyState(
              icon: Icons.link_off_rounded,
              title: 'This opportunity was removed',
            );
          }
          return _Body(internship: internship, isStudent: user?.isStudent ?? false);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.internship, required this.isStudent});
  final Internship internship;
  final bool isStudent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked =
        ref.watch(bookmarkIdsProvider).value?.contains(internship.id) ?? false;
    final alreadyApplied = ref
            .watch(myApplicationIdsProvider)
            .value
            ?.contains(internship.id) ??
        false;

    Widget section(String title, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: 8),
            child,
            const SizedBox(height: 20),
          ],
        );

    Widget bullets(List<String> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: context.colors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r)),
                    ],
                  ),
                ),
              )
              .toList(),
        );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  UserAvatar(
                    url: internship.startupLogoUrl,
                    name: internship.startupName,
                    radius: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(internship.title, style: context.text.titleLarge),
                        Text(
                          internship.startupName,
                          style: context.text.bodyMedium
                              ?.copyWith(color: context.colors.primary),
                        ),
                      ],
                    ),
                  ),
                  if (isStudent)
                    IconButton.filledTonal(
                      tooltip: bookmarked ? 'Remove bookmark' : 'Save',
                      icon: Icon(bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded),
                      onPressed: () => toggleBookmark(ref, internship),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...internship.skills.take(6).map((s) => Chip(label: Text(s))),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(Icons.schedule_rounded, internship.employmentType),
                      _InfoRow(Icons.place_outlined,
                          '${internship.workMode}${internship.location.isEmpty ? '' : ' • ${internship.location}'}'),
                      if (internship.durationWeeks > 0)
                        _InfoRow(Icons.timelapse_rounded,
                            '${internship.durationWeeks} weeks'),
                      if (internship.compensation.isNotEmpty)
                        _InfoRow(
                            Icons.payments_outlined, internship.compensation),
                      if (internship.deadline != null)
                        _InfoRow(Icons.event_rounded,
                            'Apply by ${internship.deadline!.shortDate}'),
                      _InfoRow(Icons.people_outline_rounded,
                          '${internship.applicantsCount} applicant(s) • ${internship.positions} position(s)'),
                      if (internship.postedAt != null)
                        _InfoRow(Icons.history_rounded,
                            'Posted ${internship.postedAt!.relative}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              section('About', Text(internship.description,
                  style: const TextStyle(height: 1.5))),
              if (internship.responsibilities.isNotEmpty)
                section('Responsibilities', bullets(internship.responsibilities)),
              if (internship.requirements.isNotEmpty)
                section('Requirements', bullets(internship.requirements)),
              if (internship.applicationInstructions.isNotEmpty)
                section('How to apply',
                    Text(internship.applicationInstructions)),
            ],
          ),
        ),
        if (isStudent)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton(
                onPressed: !internship.isOpen || alreadyApplied
                    ? null
                    : () => context.pushNamed(
                          RouteNames.applyInternship,
                          pathParameters: {'id': internship.id},
                        ),
                child: Text(
                  alreadyApplied
                      ? 'Already applied'
                      : internship.isOpen
                          ? 'Apply now'
                          : 'Applications closed',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
