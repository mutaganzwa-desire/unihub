import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';

/// Animated circular profile-completion indicator.
class CompletionRing extends StatelessWidget {
  const CompletionRing({super.key, required this.percent, this.size = 64});

  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        height: size,
        width: size,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: 6,
              backgroundColor: context.colors.surfaceContainerHighest,
            ),
            Center(
              child: Text(
                '${(value * 100).round()}%',
                style: context.text.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
