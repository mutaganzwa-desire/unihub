import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/application.dart';

/// Vertical timeline of every status the application has passed through.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.timeline});
  final List<StatusEvent> timeline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < timeline.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            AppColors.statusColor(timeline[i].status.name),
                      ),
                    ),
                    if (i != timeline.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: context.colors.outlineVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(timeline[i].status.label,
                            style: context.text.titleSmall),
                        Text(
                          timeline[i].at.shortDate,
                          style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
