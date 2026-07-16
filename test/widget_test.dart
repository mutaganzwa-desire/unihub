import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unihub/core/widgets/empty_state.dart';
import 'package:unihub/core/widgets/status_chip.dart';

void main() {
  testWidgets('EmptyState renders title, message and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No results',
            message: 'Try another search',
            actionLabel: 'Retry',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Try another search'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(tapped, isTrue);
  });

  testWidgets('StatusChip prettifies camelCase status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusChip(status: 'underReview')),
      ),
    );
    expect(find.text('Under Review'), findsOneWidget);
  });
}
