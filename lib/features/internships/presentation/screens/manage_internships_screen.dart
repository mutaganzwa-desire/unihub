import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../profile/domain/entities/startup_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/internship.dart';
import '../providers/internship_providers.dart';

/// Startup-side internship management: create, edit, pause, close,
/// duplicate, delete. Posting is gated on verification status.
class ManageInternshipsScreen extends ConsumerWidget {
  const ManageInternshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internships = ref.watch(myInternshipsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My internships')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.internshipForm),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post internship'),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncView(
              value: internships,
              onRetry: () => ref.invalidate(myInternshipsProvider),
              builder: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.work_outline_rounded,
                      title: 'No internships yet',
                      message:
                          'Publish your first opportunity and start receiving applications.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          _ManageCard(internship: items[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageCard extends ConsumerWidget {
  const _ManageCard({required this.internship});
  final Internship internship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(internshipRepositoryProvider);

    Future<void> run(Future<dynamic> Function() action, String done) async {
      await action();
      if (context.mounted) context.showSnack(done);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(internship.title,
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                StatusChip(status: internship.status.name),
                PopupMenuButton<String>(
                  onSelected: (v) => switch (v) {
                    'edit' => context.pushNamed(
                        RouteNames.internshipForm,
                        queryParameters: {'id': internship.id},
                      ),
                    'pause' => run(
                        () => repo.setStatus(
                            internship.id, InternshipStatus.paused),
                        'Internship paused.'),
                    'resume' => run(
                        () =>
                            repo.setStatus(internship.id, InternshipStatus.open),
                        'Internship re-opened.'),
                    'close' => run(
                        () => repo.setStatus(
                            internship.id, InternshipStatus.closed),
                        'Internship closed.'),
                    'duplicate' => run(
                        () => repo.duplicate(internship),
                        'Duplicated as draft.'),
                    'delete' => _confirmDelete(context, ref),
                    _ => null,
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (internship.status == InternshipStatus.open)
                      const PopupMenuItem(value: 'pause', child: Text('Pause'))
                    else if (internship.status != InternshipStatus.closed)
                      const PopupMenuItem(
                          value: 'resume', child: Text('Publish / Resume')),
                    const PopupMenuItem(value: 'close', child: Text('Close')),
                    const PopupMenuItem(
                        value: 'duplicate', child: Text('Duplicate')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              [
                '${internship.applicantsCount} applicants',
                '${internship.viewsCount} views',
                if (internship.deadline != null)
                  'closes ${internship.deadline!.shortDate}',
              ].join('  •  '),
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete internship?'),
        content: const Text(
            'This permanently removes the posting. Existing applications stay in your applicants list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(internshipRepositoryProvider).delete(internship.id);
      if (context.mounted) context.showSnack('Internship deleted.');
    }
  }
}
