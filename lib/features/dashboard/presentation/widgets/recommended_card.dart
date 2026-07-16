import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../bookmarks/presentation/bookmark_providers.dart';
import '../../domain/recommendation_engine.dart';

/// The large gradient hero card for a recommended internship.
class RecommendedCard extends ConsumerWidget {
  const RecommendedCard({super.key, required this.scored});
  final ScoredInternship scored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = scored.internship;
    final bookmarked =
        ref.watch(bookmarkIdsProvider).value?.contains(i.id) ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.pushNamed(
            RouteNames.internshipDetails,
            pathParameters: {'id': i.id},
          ),
          child: Container(
            width: 300,
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => toggleBookmark(ref, i),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(i.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(i.startupName,
                    style: const TextStyle(color: Colors.white70)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(scored.reason,
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(height: 10),
                Text(
                  [
                    i.workMode,
                    if (i.postedAt != null) i.postedAt!.relative,
                  ].join('  •  '),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
