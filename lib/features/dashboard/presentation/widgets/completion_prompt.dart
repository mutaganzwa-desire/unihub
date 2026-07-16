import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';

/// Nudges students to finish their profile — better profiles get better
/// recommendations and stronger applications.
class CompletionPrompt extends StatelessWidget {
  const CompletionPrompt({super.key, required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    if (percent >= 100) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: context.colors.primaryContainer.withOpacity(.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complete your profile',
                        style: context.text.titleSmall),
                    const SizedBox(height: 4),
                    Text('$percent% done — stand out to startups.',
                        style: context.text.bodySmall),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () =>
                    context.pushNamed(RouteNames.editStudentProfile),
                child: const Text('Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
