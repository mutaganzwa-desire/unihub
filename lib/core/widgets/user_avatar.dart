import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../extensions/context_ext.dart';
import '../extensions/string_ext.dart';

/// Cached avatar with an initials fallback — used for students and startups.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.url, required this.name, this.radius = 22});

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: context.colors.primaryContainer,
        child: Text(
          name.initials,
          style: TextStyle(
            color: context.colors.primary,
            fontWeight: FontWeight.w700,
            fontSize: radius * .7,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: CachedNetworkImageProvider(url!),
      backgroundColor: context.colors.surfaceContainerHighest,
    );
  }
}
