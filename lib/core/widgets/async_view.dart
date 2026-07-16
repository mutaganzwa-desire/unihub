import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'empty_state.dart';
import 'skeletons.dart';

/// Renders an [AsyncValue] with consistent loading / error / data handling —
/// the single place where retry buttons and skeletons come from.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => loading ?? const ListSkeleton(),
      error: (e, _) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load data',
        message: e.toString(),
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      ),
    );
  }
}
