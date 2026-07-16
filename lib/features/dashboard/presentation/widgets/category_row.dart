import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../internships/domain/entities/internship.dart';
import '../../../internships/presentation/providers/internship_providers.dart';

/// Horizontal "Browse by category" strip. Tapping a category applies it as a
/// filter and jumps to Explore.
class CategoryRow extends ConsumerWidget {
  const CategoryRow({super.key, required this.onSelected});
  final void Function(String category) onSelected;

  static const _icons = <String, IconData>{
    'Design': Icons.design_services_rounded,
    'Engineering': Icons.engineering_rounded,
    'Marketing': Icons.campaign_rounded,
    'Data': Icons.query_stats_rounded,
    'Business': Icons.business_center_rounded,
    'Finance': Icons.savings_rounded,
    'Research': Icons.science_rounded,
    'Operations': Icons.settings_suggest_rounded,
    'Other': Icons.auto_awesome_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppConstants.internshipCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final category = AppConstants.internshipCategories[i];
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  ref.read(internshipFilterProvider.notifier).state =
                      InternshipFilter(category: category);
                  onSelected(category);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: context.colors.primaryContainer,
                        child: Icon(_icons[category] ?? Icons.circle,
                            color: context.colors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(category, style: context.text.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
