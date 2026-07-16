import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else {
      context.showSnack(
        ref.read(authControllerProvider).error.toString(),
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(
      title: 'Reset password',
      subtitle: _sent
          ? 'Check your inbox — we sent a reset link to ${_email.text.trim()}.'
          : 'Enter the email you registered with and we will send a reset link.',
      child: _sent
          ? PrimaryButton(
              label: 'Back to sign in',
              onPressed: () => Navigator.of(context).pop(),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Email',
                    controller: _email,
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Send reset link',
                    onPressed: _submit,
                    loading: loading,
                  ),
                ],
              ),
            ),
    );
  }
}
