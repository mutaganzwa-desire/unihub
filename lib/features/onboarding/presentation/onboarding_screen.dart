import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/primary_button.dart';
import 'onboarding_providers.dart';

class _Page {
  const _Page(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    Icons.explore_rounded,
    'Real experience, on campus',
    'Discover internships and project roles at student-led startups inside your university innovation ecosystem.',
  ),
  _Page(
    Icons.handshake_rounded,
    'Two sides, one platform',
    'Students showcase skills and portfolios. Startups post roles, review applicants and build their first teams.',
  ),
  _Page(
    Icons.bolt_rounded,
    'From application to offer',
    'Apply in minutes, track your status in real time, chat with founders and get notified at every step.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.goNamed(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Skip')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                context.colors.primary.withOpacity(.15),
                                context.colors.primary.withOpacity(.05),
                              ],
                            ),
                          ),
                          child: Icon(p.icon,
                              size: 72, color: context.colors.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(p.title,
                            style: context.text.headlineMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(
                          p.body,
                          style: context.text.bodyLarge?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: active ? 24 : 8,
                  decoration: BoxDecoration(
                    color: active
                        ? context.colors.primary
                        : context.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: last ? 'Get started' : 'Next',
                  onPressed: last
                      ? _finish
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
