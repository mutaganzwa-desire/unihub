import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../bookmarks/presentation/bookmark_providers.dart';
import '../../domain/entities/internship.dart';

/// Compact internship row used in feeds, saved lists and dashboards.
class InternshipCard extends ConsumerWidget {
  const InternshipCard({super.key, required this.internship});

  final Internship internship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStudent = ref.watch(currentUserProvider)?.isStudent ?? false;
    final bookmarked =
        ref.watch(bookmarkIdsProvider).value?.contains(internship.id) ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.pushNamed(
            RouteNames.internshipDetails,
            pathParameters: {'id': internship.id},
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                UserAvatar(
                  url: internship.startupLogoUrl,
                  name: internship.startupName,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        internship.title,
                        style: context.text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        internship.startupName,
                        style: context.text.bodySmall
                            ?.copyWith(color: context.colors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          internship.employmentType,
                          internship.workMode,
                          if (internship.location.isNotEmpty)
                            internship.location,
                          if (internship.postedAt != null)
                            internship.postedAt!.relative,
                        ].join('  •  '),
                        style: context.text.bodySmall
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isStudent)
                  IconButton(
                    tooltip: bookmarked ? 'Remove bookmark' : 'Save',
                    icon: Icon(
                      bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: bookmarked ? context.colors.primary : null,
                    ),
                    onPressed: () => toggleBookmark(ref, internship),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
