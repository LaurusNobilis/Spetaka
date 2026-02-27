// This is a basic Flutter scaffold smoke test.
//
// To run: flutter test
// Expected: AppShell renders without exceptions — confirms dependency
// graph is wired correctly and the app shell starts with zero errors.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spetaka/app.dart';

void main() {
  group('SpetakaApp — scaffold smoke tests', () {
    testWidgets('App renders without exceptions (AC: 1)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SpetakaApp(),
        ),
      );
      // Verify MaterialApp widget tree is present
      expect(find.byType(MaterialApp), findsAtLeastNWidgets(1));
    });

    testWidgets('Placeholder daily-view screen is visible after boot (AC: 6)',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SpetakaApp(),
        ),
      );
      await tester.pumpAndSettle();
      // Root route renders the Daily placeholder — confirms navigation scaffold boots
      expect(find.text('Daily'), findsAtLeastNWidgets(1));
    });
  });
}
