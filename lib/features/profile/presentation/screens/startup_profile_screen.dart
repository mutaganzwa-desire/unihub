import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/startup_profile.dart';
import '../providers/profile_providers.dart';
import '../widgets/completion_ring.dart';
import '../widgets/profile_menu_tile.dart';

class StartupProfileScreen extends ConsumerWidget {
  const StartupProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myStartupProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Startup profile')),
      body: AsyncView(
        value: profile,
        onRetry: () => ref.invalidate(myStartupProfileProvider),
        builder: (p) {
          if (p == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  UserAvatar(url: p.logoUrl, name: p.name, radius: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(p.name,
                                  style: context.text.titleLarge,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (p.isVerified) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified_rounded,
                                  size: 20, color: context.colors.primary),
                            ],
                          ],
                        ),
                        if (p.industry.isNotEmpty)
                          Text(p.industry,
                              style: context.text.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        StatusChip(
                          status: p.verificationStatus.name,
                          label: switch (p.verificationStatus) {
                            VerificationStatus.verified => 'Verified',
                            VerificationStatus.pending =>
                              'Verification pending',
                            VerificationStatus.rejected =>
                              'Verification rejected',
                            _ => 'Not verified',
                          },
                        ),
                      ],
                    ),
                  ),
                  CompletionRing(percent: p.completionPercent),
                ],
              ),
              if (p.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(p.description, style: const TextStyle(height: 1.5)),
              ],
              const SizedBox(height: 24),
              ProfileMenuTile(
                icon: Icons.edit_outlined,
                label: 'Edit startup profile',
                onTap: () => context.pushNamed(RouteNames.editStartupProfile),
              ),
              ProfileMenuTile(
                icon: Icons.verified_outlined,
                label: 'Verification',
                onTap: () => context.pushNamed(RouteNames.verification),
              ),
              ProfileMenuTile(
                icon: Icons.insights_rounded,
                label: 'Analytics',
                onTap: () => context.pushNamed(RouteNames.startupAnalytics),
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
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
