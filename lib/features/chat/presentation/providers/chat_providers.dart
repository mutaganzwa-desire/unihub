import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_entities.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageServiceProvider),
    ref.watch(notificationRepositoryProvider),
  ),
);

final myConversationsProvider =
    StreamProvider.autoDispose<List<Conversation>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchConversations(uid);
});

final conversationProvider =
    StreamProvider.autoDispose.family<Conversation?, String>(
  (ref, id) => ref.watch(chatRepositoryProvider).watchConversation(id),
);

final messagesProvider =
    StreamProvider.autoDispose.family<List<Message>, String>(
  (ref, conversationId) =>
      ref.watch(chatRepositoryProvider).watchMessages(conversationId),
);

/// Total unread messages across conversations (badge on dashboards).
final totalUnreadMessagesProvider = Provider.autoDispose<int>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  final conversations = ref.watch(myConversationsProvider).value ?? const [];
  if (uid == null) return 0;
  return conversations.fold(0, (sum, c) => sum + c.unreadFor(uid));
});

/// Opens (creating if needed) the conversation with [peerId] and navigates.
Future<void> openConversationWith(
  BuildContext context,
  WidgetRef ref, {
  required String peerId,
  required String peerName,
  String? peerPhotoUrl,
}) async {
  final me = ref.read(currentUserProvider);
  if (me == null) return;
  final res = await ref.read(chatRepositoryProvider).ensureConversation(
        myUid: me.uid,
        myName: me.displayName,
        myPhoto: me.photoUrl,
        peerId: peerId,
        peerName: peerName,
        peerPhoto: peerPhotoUrl,
      );
  if (!context.mounted) return;
  res.when(
    success: (id) => context.pushNamed(
      RouteNames.chat,
      pathParameters: {'id': id},
      queryParameters: {'peer': peerName},
    ),
    failure: (f) => context.showSnack(f.message, error: true),
  );
}
