import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

/// Slides in when the device loses connectivity. Firestore keeps working
/// from cache; this just makes the state visible to the user.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: online ? 0 : 32,
          color: Colors.orange.shade800,
          alignment: Alignment.center,
          child: online
              ? null
              : const Text(
                  'You are offline — changes will sync automatically',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
