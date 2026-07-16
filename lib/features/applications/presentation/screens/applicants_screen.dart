import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/application.dart';
import '../providers/application_providers.dart';

enum _SortBy { newest, name, status }

/// Startup-side applicant pipeline across all internships.
class ApplicantsScreen extends ConsumerStatefulWidget {
  const ApplicantsScreen({super.key});

  @override
  ConsumerState<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends ConsumerState<ApplicantsScreen> {
  _SortBy _sort = _SortBy.newest;
  ApplicationStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(startupApplicationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants'),
        actions: [
          PopupMenuButton<_SortBy>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _SortBy.newest, child: Text('Newest')),
              PopupMenuItem(value: _SortBy.name, child: Text('Name')),
              PopupMenuItem(value: _SortBy.status, child: Text('Status')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                for (final s in [
                  ApplicationStatus.applied,
                  ApplicationStatus.shortlisted,
                  ApplicationStatus.interview,
                  ApplicationStatus.accepted,
                  ApplicationStatus.rejected,
                ]) ...[
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncView(
              value: apps,
              onRetry: () => ref.invalidate(startupApplicationsProvider),
              builder: (items) {
                var list = items
                    .where((a) => a.status != ApplicationStatus.draft)
                    .where((a) => _filter == null || a.status == _filter)
                    .toList();
                list = switch (_sort) {
                  _SortBy.name => (list
                    ..sort((a, b) =>
                        a.studentName.compareTo(b.studentName))),
                  _SortBy.status => (list
                    ..sort((a, b) =>
                        a.status.index.compareTo(b.status.index))),
                  _ => list,
                };
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No applicants yet',
                    message:
                        'When students apply to your internships they will appear here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final a = list[i];
                    return Card(
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        leading: UserAvatar(
                            url: a.studentPhotoUrl, name: a.studentName),
                        title: Text(a.studentName),
                        subtitle: Text(
                          '${a.internshipTitle}\n${a.appliedAt?.relative ?? ''}',
                          maxLines: 2,
                        ),
                        isThreeLine: true,
                        trailing: StatusChip(
                            status: a.status.name, label: a.status.label),
                        onTap: () => context.pushNamed(
                          RouteNames.applicationDetails,
                          pathParameters: {'id': a.id},
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
