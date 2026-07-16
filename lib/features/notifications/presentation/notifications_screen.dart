import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';
import 'notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationType type) => switch (type) {
        NotificationType.applicationAccepted => Icons.celebration_rounded,
        NotificationType.applicationRejected => Icons.info_outline_rounded,
        NotificationType.applicationShortlisted => Icons.star_outline_rounded,
        NotificationType.interviewScheduled => Icons.event_available_rounded,
        NotificationType.newMessage => Icons.chat_bubble_outline_rounded,
        NotificationType.newInternship => Icons.work_outline_rounded,
        NotificationType.profileVerified => Icons.verified_rounded,
        _ => Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(myNotificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              final uid = ref.read(currentUserProvider)?.uid;
              if (uid != null) {
                ref.read(notificationRepositoryProvider).markAllRead(uid);
              }
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: AsyncView(
        value: notifications,
        onRetry: () => ref.invalidate(myNotificationsProvider),
        builder: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'No notifications yet',
                message: 'Application updates and messages will show up here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final n = items[i];
                  return Card(
                    color: n.read
                        ? null
                        : context.colors.primaryContainer.withOpacity(.35),
                    child: ListTile(
                      leading: Icon(_icon(n.type),
                          color: context.colors.primary),
                      title: Text(n.title,
                          style: context.text.titleSmall),
                      subtitle: Text(
                        '${n.body}\n${n.createdAt?.relative ?? ''}',
                        maxLines: 3,
                      ),
                      isThreeLine: true,
                      onTap: () {
                        ref
                            .read(notificationRepositoryProvider)
                            .markRead(n.id);
                        final route = n.route;
                        if (route != null && route.isNotEmpty) {
                          context.push(route);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
