import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).register(
          email: _email.text,
          password: _password.text,
          displayName: _name.text.trim(),
          role: _role,
        );
    if (!mounted) return;
    if (!ok) {
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
      title: 'Create your account',
      subtitle: 'Join as a student looking for experience, or as a startup looking for talent.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RoleSelector(
              value: _role,
              onChanged: (r) => setState(() => _role = r),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: _role == UserRole.student ? 'Full name' : 'Startup name',
              controller: _name,
              validator: (v) => Validators.required(v, 'Name'),
              prefixIcon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: _role == UserRole.student ? 'University email' : 'Email',
              controller: _email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              controller: _password,
              validator: Validators.password,
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirm password',
              controller: _confirm,
              validator: (v) => Validators.confirmPassword(v, _password.text),
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Create account',
              onPressed: _submit,
              loading: loading,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () => context.goNamed(RouteNames.login),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            icon: Icons.school_rounded,
            title: 'Student',
            subtitle: 'Find internships',
            selected: value == UserRole.student,
            onTap: () => onChanged(UserRole.student),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            icon: Icons.rocket_launch_rounded,
            title: 'Startup',
            subtitle: 'Recruit talent',
            selected: value == UserRole.startup,
            onTap: () => onChanged(UserRole.startup),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title — $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 30,
                  color: selected ? colors.primary : colors.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(title, style: context.text.titleSmall),
              Text(
                subtitle,
                style: context.text.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
