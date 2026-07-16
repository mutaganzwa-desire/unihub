import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeletons.dart';
import '../providers/internship_providers.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/internship_card.dart';

/// Browse + search + filter + infinite scroll.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filter = ref.read(internshipFilterProvider);
      ref.invalidate(internshipFeedProvider(filter));
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        final filter = ref.read(internshipFilterProvider);
        ref.read(internshipFeedProvider(filter).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final filter = ref.read(internshipFilterProvider);
      ref.read(internshipFilterProvider.notifier).state =
          filter.copyWith(searchQuery: value);
      if (value.trim().isNotEmpty) {
        ref.read(analyticsServiceProvider).logSearch(value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(internshipFilterProvider);
    final feed = ref.watch(internshipFeedProvider(filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search opportunities...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Badge(
                  isLabelVisible: !filter.isDefault,
                  child: IconButton.filledTonal(
                    tooltip: 'Filters',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => showFilterSheet(context, ref),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: feed.when(
              loading: () => const ListSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load opportunities',
                message: e.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(internshipFeedProvider(filter)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No opportunities found',
                    message: filter.isDefault
                        ? 'New roles will appear here as startups post them.'
                        : 'Try removing some filters or a different search.',
                  );
                }
                final notifier =
                    ref.read(internshipFeedProvider(filter).notifier);
                return RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length + (notifier.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      if (i == items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return InternshipCard(internship: items[i]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
