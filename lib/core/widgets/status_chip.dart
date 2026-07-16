import 'package:flutter/material.dart';

import '../extensions/string_ext.dart';
import '../theme/app_colors.dart';

/// Colored pill for application / internship / verification statuses.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.label});

  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label ?? _pretty(status),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _pretty(String s) => s
      .replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]}')
      .trim()
      .capitalized;
}
