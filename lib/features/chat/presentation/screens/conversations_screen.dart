import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/chat_providers.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(myConversationsProvider);
    final myUid = ref.watch(currentUserProvider)?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: AsyncView(
              value: conversations,
              onRetry: () => ref.invalidate(myConversationsProvider),
              builder: (items) {
                final filtered = items
                    .where((c) =>
                        _query.isEmpty ||
                        c.peerName(myUid).toLowerCase().contains(_query) ||
                        c.lastMessage.toLowerCase().contains(_query))
                    .toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No conversations',
                    message:
                        'Chats with startups and applicants will appear here.',
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final unread = c.unreadFor(myUid);
                    return ListTile(
                      leading: UserAvatar(
                        url: c.peerPhoto(myUid),
                        name: c.peerName(myUid),
                        radius: 24,
                      ),
                      title: Text(c.peerName(myUid)),
                      subtitle: Text(
                        c.peerIsTyping(myUid) ? 'typing…' : c.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.peerIsTyping(myUid)
                              ? context.colors.primary
                              : null,
                          fontStyle: c.peerIsTyping(myUid)
                              ? FontStyle.italic
                              : null,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (c.lastMessageAt != null)
                            Text(c.lastMessageAt!.relative,
                                style: context.text.bodySmall),
                          if (unread > 0)
                            Badge(label: Text('$unread')),
                        ],
                      ),
                      onTap: () => context.pushNamed(
                        RouteNames.chat,
                        pathParameters: {'id': c.id},
                        queryParameters: {'peer': c.peerName(myUid)},
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
