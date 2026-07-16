import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

/// Blocks the app until the user confirms their email. Polls every 4s so
/// the moment they tap the link in their inbox the app moves on by itself.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final verified =
          await ref.read(authControllerProvider.notifier).checkVerified();
      if (verified) _timer?.cancel(); // authStateProvider re-emits, router moves on
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider)?.email ?? 'your inbox';
    final loading = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(
      title: 'Verify your email',
      subtitle:
          'We sent a verification link to $email. Open it, then come back — this screen updates automatically.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.mark_email_unread_rounded,
              size: 72, color: context.colors.primary),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Resend email',
            loading: loading,
            onPressed: () async {
              final ok = await ref
                  .read(authControllerProvider.notifier)
                  .resendVerification();
              if (context.mounted) {
                context.showSnack(
                  ok ? 'Verification email sent.' : 'Could not send email.',
                  error: !ok,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
