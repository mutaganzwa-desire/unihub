import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/application.dart';
import '../providers/application_providers.dart';
import '../widgets/status_timeline.dart';

/// Student-side application tracking with status tabs and a timeline sheet.
class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  String _tab = 'All';

  static const _tabs = ['All', 'Applied', 'Interview', 'Accepted', 'Closed'];

  bool _matches(Application a) => switch (_tab) {
        'Applied' => a.status == ApplicationStatus.applied ||
            a.status == ApplicationStatus.underReview ||
            a.status == ApplicationStatus.shortlisted,
        'Interview' => a.status == ApplicationStatus.interview,
        'Accepted' => a.status == ApplicationStatus.accepted,
        'Closed' => a.status == ApplicationStatus.rejected ||
            a.status == ApplicationStatus.withdrawn,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(myApplicationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My applications')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(_tabs[i]),
                selected: _tab == _tabs[i],
                onSelected: (_) => setState(() => _tab = _tabs[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncView(
              value: apps,
              onRetry: () => ref.invalidate(myApplicationsProvider),
              builder: (items) {
                final filtered = items.where(_matches).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No applications here',
                    message:
                        'Opportunities you apply to will appear in this list.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _ApplicationCard(application: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.application});
  final Application application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatar(
                url: application.startupLogoUrl,
                name: application.startupName,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.internshipTitle,
                        style: context.text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(application.startupName,
                        style: context.text.bodySmall),
                    if (application.appliedAt != null)
                      Text('Applied ${application.appliedAt!.relative}',
                          style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
              StatusChip(status: application.status.name,
                  label: application.status.label),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(application.internshipTitle,
                style: Theme.of(ctx).textTheme.titleLarge),
            Text(application.startupName),
            const SizedBox(height: 20),
            Text('Timeline', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: StatusTimeline(timeline: application.timeline),
              ),
            ),
            if (application.isActive &&
                application.status != ApplicationStatus.accepted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Withdraw application'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final res = await ref
                        .read(applicationRepositoryProvider)
                        .updateStatus(
                            application, ApplicationStatus.withdrawn);
                    if (context.mounted) {
                      context.showSnack(
                        res.isSuccess
                            ? 'Application withdrawn.'
                            : res.failureOrNull!.message,
                        error: !res.isSuccess,
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
