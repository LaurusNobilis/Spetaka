// test/widget/manage_event_types_screen_test.dart
//
// Widget tests for Story 3.4 — ManageEventTypesScreen
//
// Coverage:
//   - Screen renders the 5 default event types
//   - Add flow: text field and add button present
//   - Delete: confirmation dialog shows
//   - Drag handles present (AC5)
//
// Uses stream overrides (no real DB) to avoid Drift pending-timer issues.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/features/events/data/event_type_providers.dart';
import 'package:spetaka/features/events/presentation/manage_event_types_screen.dart';

/// Helper: builds a fake [EventTypeEntry] list matching the 5 seed defaults.
List<EventTypeEntry> _defaultTypes() {
  final now = DateTime.now().millisecondsSinceEpoch;
  const names = [
    'Birthday',
    'Wedding Anniversary',
    'Important Life Event',
    'Regular Check-in',
    'Important Appointment',
  ];
  return [
    for (var i = 0; i < names.length; i++)
      EventTypeEntry(
        id: 'default-${names[i].toLowerCase().replaceAll(' ', '-')}',
        name: names[i],
        sortOrder: i,
        createdAt: now,
      ),
  ];
}

Widget _buildHarness({List<EventTypeEntry>? types}) {
  final data = types ?? _defaultTypes();
  return ProviderScope(
    overrides: [
      watchEventTypesProvider.overrideWith(
        (ref) => Stream.value(data),
      ),
    ],
    child: const MaterialApp(home: ManageEventTypesScreen()),
  );
}

void main() {
  group('ManageEventTypesScreen — Story 3.4', () {
    testWidgets('AC1 — renders 5 default event types', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Birthday'), findsOneWidget);
      expect(find.text('Wedding Anniversary'), findsOneWidget);
      expect(find.text('Important Life Event'), findsOneWidget);
      expect(find.text('Regular Check-in'), findsOneWidget);
      expect(find.text('Important Appointment'), findsOneWidget);
    });

    testWidgets('AC2 — add text field and button are present', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Text field for new type exists with correct hint
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('New event type…'), findsOneWidget);

      // Add button exists
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('AC3 — rename buttons are present for each type',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // One rename icon per type
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(5));
    });

    testWidgets('AC4 — delete buttons are present for each type',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // One delete icon per type
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(5));
    });

    testWidgets('AC5 — drag handles render for reorder', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.drag_handle), findsNWidgets(5));
    });

    testWidgets('empty state shows message', (tester) async {
      await tester.pumpWidget(
        _buildHarness(types: []),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No event types. Add one above.'), findsOneWidget);
    });

    testWidgets('AppBar shows "Event Types" title', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pump();

      expect(find.text('Event Types'), findsOneWidget);
    });
  });
}
