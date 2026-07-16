import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../internships/presentation/widgets/internship_card.dart';
import 'bookmark_providers.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkedInternshipsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved opportunities')),
      body: AsyncView(
        value: bookmarks,
        onRetry: () => ref.invalidate(bookmarkedInternshipsProvider),
        builder: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.bookmark_outline_rounded,
                title: 'Nothing saved yet',
                message:
                    'Tap the bookmark icon on any opportunity to keep it here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => InternshipCard(internship: items[i]),
              ),
      ),
    );
  }
}
