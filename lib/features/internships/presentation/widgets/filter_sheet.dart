import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../domain/entities/internship.dart';
import '../providers/internship_providers.dart';

Future<void> showFilterSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(internshipFilterProvider);
    final notifier = ref.read(internshipFilterProvider.notifier);

    Widget chips<T>({
      required String title,
      required List<String> options,
      required String? selected,
      required void Function(String?) onSelect,
    }) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (o) => FilterChip(
                      label: Text(o),
                      selected: selected == o,
                      onSelected: (_) => onSelect(selected == o ? null : o),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: context.text.titleLarge),
                TextButton(
                  onPressed: () =>
                      notifier.state = const InternshipFilter(),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            chips(
              title: 'Category',
              options: AppConstants.internshipCategories,
              selected: filter.category,
              onSelect: (v) =>
                  notifier.state = filter.copyWith(category: () => v),
            ),
            chips(
              title: 'Work mode',
              options: AppConstants.workModes,
              selected: filter.workMode,
              onSelect: (v) =>
                  notifier.state = filter.copyWith(workMode: () => v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Paid opportunities only'),
              value: filter.paidOnly,
              onChanged: (v) => notifier.state = filter.copyWith(paidOnly: v),
            ),
            const SizedBox(height: 8),
            Text('Sort by', style: context.text.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<InternshipSort>(
              segments: const [
                ButtonSegment(
                    value: InternshipSort.newest, label: Text('Newest')),
                ButtonSegment(
                    value: InternshipSort.popular, label: Text('Popular')),
                ButtonSegment(
                    value: InternshipSort.deadline, label: Text('Deadline')),
              ],
              selected: {filter.sort},
              onSelectionChanged: (s) =>
                  notifier.state = filter.copyWith(sort: s.first),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Show results'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
