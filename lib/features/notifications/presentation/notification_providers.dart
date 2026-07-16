import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_providers.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final myNotificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).watchForUser(uid);
});

final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(0);
  return ref.watch(notificationRepositoryProvider).watchUnreadCount(uid);
});
