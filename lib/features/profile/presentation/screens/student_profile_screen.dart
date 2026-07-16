import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/completion_ring.dart';
import '../widgets/profile_menu_tile.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myStudentProfileProvider);
    final stats = ref.watch(myApplicationStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AsyncView(
        value: profile,
        onRetry: () => ref.invalidate(myStudentProfileProvider),
        builder: (p) {
          if (p == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  UserAvatar(url: p.photoUrl, name: p.fullName, radius: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.fullName, style: context.text.titleLarge),
                        if (p.location.isNotEmpty)
                          Text(p.location,
                              style: context.text.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        if (p.program.isNotEmpty)
                          Text('${p.program} • Year ${p.yearOfStudy}',
                              style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  CompletionRing(percent: p.completionPercent),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      _Stat(label: 'Applications', value: stats.total),
                      _Stat(label: 'Shortlisted', value: stats.shortlisted),
                      _Stat(label: 'Accepted', value: stats.accepted),
                    ],
                  ),
                ),
              ),
              if (p.skills.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      p.skills.take(8).map((s) => Chip(label: Text(s))).toList(),
                ),
              ],
              const SizedBox(height: 24),
              ProfileMenuTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit profile',
                onTap: () => context.pushNamed(RouteNames.editStudentProfile),
              ),
              ProfileMenuTile(
                icon: Icons.bookmark_outline_rounded,
                label: 'Saved opportunities',
                onTap: () => context.pushNamed(RouteNames.bookmarks),
              ),
              ProfileMenuTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                onTap: () => context.pushNamed(RouteNames.conversations),
              ),
              ProfileMenuTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => context.pushNamed(RouteNames.notifications),
              ),
              ProfileMenuTile(
                icon: Icons.logout_rounded,
                label: 'Log out',
                danger: true,
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: context.text.titleLarge),
          Text(label,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
