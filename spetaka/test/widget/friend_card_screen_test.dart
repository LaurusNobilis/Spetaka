import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:spetaka/core/actions/contact_action_service.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/errors/app_error.dart';
import 'package:spetaka/features/acquittement/domain/pending_action_state.dart';
import 'package:spetaka/features/events/data/event_type_providers.dart';
import 'package:spetaka/features/events/data/events_providers.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/features/friends/presentation/friend_card_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Fake service that throws [ContactActionFailedAppError] on every action.
class _FailingContactActionService extends Fake
    implements ContactActionService {
  @override
  Future<void> call(
    String rawNumber, {
    String? friendId,
    AcquittementOrigin origin = AcquittementOrigin.unknown,
  }) async {
    throw const ContactActionFailedAppError('call');
  }

  @override
  Future<void> sms(
    String rawNumber, {
    String? friendId,
    AcquittementOrigin origin = AcquittementOrigin.unknown,
  }) async {
    throw const ContactActionFailedAppError('sms');
  }

  @override
  Future<void> whatsapp(
    String rawNumber, {
    String? friendId,
    AcquittementOrigin origin = AcquittementOrigin.unknown,
  }) async {
    throw const ContactActionFailedAppError('whatsapp');
  }
}

Friend _makeFriend({
  String id = 'f1',
  String name = 'Alice',
  String mobile = '+33600000001',
  String? tags,
  String? notes,
  bool isConcernActive = false,
  String? concernNote,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: id,
    name: name,
    mobile: mobile,
    tags: tags,
    notes: notes,
    careScore: 0.0,
    isConcernActive: isConcernActive,
    concernNote: concernNote,
    isDemo: false,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _harnessWithRouter({required Friend? friend}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const FriendCardScreen(id: 'f1'),
        routes: [
          GoRoute(
            path: 'friends/f1/edit',
            builder: (_, __) =>
                const Scaffold(body: Text('Edit Screen')),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      watchFriendByIdProvider('f1').overrideWith(
        (_) => Stream.value(friend),
      ),
      // Stub events stream — no events in widget tests (unit behaviour in repo tests).
      watchEventsByFriendProvider('f1').overrideWith(
        (_) => Stream.value([]),
      ),
      // Stub event types — 3.4 review fix: _EventsSection now watches this provider.
      watchEventTypesProvider.overrideWith(
        (_) => Stream.value(<EventTypeEntry>[]),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Harness that injects a [_FailingContactActionService] so action-button
/// error paths can be exercised without platform channel setup.
Widget _harnessWithFailingActions({required Friend? friend}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const FriendCardScreen(id: 'f1'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      watchFriendByIdProvider('f1').overrideWith(
        (_) => Stream.value(friend),
      ),
      watchEventsByFriendProvider('f1').overrideWith(
        (_) => Stream.value([]),
      ),
      watchEventTypesProvider.overrideWith(
        (_) => Stream.value(<EventTypeEntry>[]),
      ),
      contactActionServiceProvider
          .overrideWithValue(_FailingContactActionService()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests — Story 2.6
// ---------------------------------------------------------------------------

void main() {
  group('FriendCardScreen — Story 2.6', () {
    testWidgets('AC1 — displays friend name and mobile', (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(friend: _makeFriend(name: 'Alice', mobile: '+33600000001')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice'), findsAtLeastNWidgets(1));
      expect(find.text('+33600000001'), findsOneWidget);
    });

    testWidgets('AC1 — displays tags section', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend(tags: '["Family"]')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
    });

    testWidgets('AC1 — displays notes when present', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend(notes: 'Loves hiking')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Loves hiking'), findsOneWidget);
    });

    testWidgets('AC1 — shows concern section when active', (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(
          friend: _makeFriend(isConcernActive: true, concernNote: 'Going through a hard time'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Concern'), findsOneWidget);
      expect(find.text('Going through a hard time'), findsOneWidget);
    });

    testWidgets('AC1 — shows events and contact history placeholders', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Contact History'), findsOneWidget);
    });

    testWidgets('AC2 — shows Call, SMS, WhatsApp buttons', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Call'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
    });

    testWidgets('AC4 — edit icon button visible in AppBar', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byWidgetPredicate((w) => w is IconButton), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('shows not-found message for null friend', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: null));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Friend not found.'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Tests — Story 2.9
  // ---------------------------------------------------------------------------

  group('FriendCardScreen — Story 2.9', () {
    testWidgets('AC1 — shows Flag concern button when concern is inactive',
        (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(friend: _makeFriend(isConcernActive: false)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Flag concern'), findsOneWidget);
    });

    testWidgets('AC2 — concern section shows when isConcernActive=true',
        (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(
          friend: _makeFriend(isConcernActive: true, concernNote: 'Rough patch'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Concern'), findsOneWidget);
      expect(find.text('Rough patch'), findsOneWidget);
      expect(find.text('Flag concern'), findsNothing);
    });

    testWidgets('AC3 — Clear concern button visible when concern is active',
        (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(friend: _makeFriend(isConcernActive: true)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Clear concern'), findsOneWidget);
    });

    testWidgets('AC2 — Flag concern button absent when concern is active',
        (tester) async {
      await tester.pumpWidget(
        _harnessWithRouter(friend: _makeFriend(isConcernActive: false)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Clear concern'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Tests — Story 5.1
  // ---------------------------------------------------------------------------

  group('FriendCardScreen — Story 5.1', () {
    testWidgets('AC1 — Call, SMS, WhatsApp buttons are enabled (not null)', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify buttons exist and are enabled (onPressed is not null).
      final callButton = find.widgetWithText(OutlinedButton, 'Call');
      final smsButton = find.widgetWithText(OutlinedButton, 'SMS');
      final waButton = find.widgetWithText(OutlinedButton, 'WhatsApp');

      expect(callButton, findsOneWidget);
      expect(smsButton, findsOneWidget);
      expect(waButton, findsOneWidget);

      // Buttons must not be disabled (the old placeholder had onPressed: null).
      final callWidget = tester.widget<OutlinedButton>(callButton);
      expect(callWidget.onPressed, isNotNull);
    });

    testWidgets('AC6 — inline error shown when Call action fails', (tester) async {
      await tester.pumpWidget(
        _harnessWithFailingActions(friend: _makeFriend()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the Call button.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Call'));
      // Allow the async handler to complete.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Inline error text must appear.
      expect(find.byKey(const Key('action_error_text')), findsOneWidget);
    });

    testWidgets('AC6 — inline error shown when SMS action fails', (tester) async {
      await tester.pumpWidget(
        _harnessWithFailingActions(friend: _makeFriend()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(OutlinedButton, 'SMS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('action_error_text')), findsOneWidget);
    });

    testWidgets('AC6 — inline error shown when WhatsApp action fails', (tester) async {
      await tester.pumpWidget(
        _harnessWithFailingActions(friend: _makeFriend()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(OutlinedButton, 'WhatsApp'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('action_error_text')), findsOneWidget);
    });

    testWidgets('AC8 — action buttons meet 48dp minimum touch target', (tester) async {
      await tester.pumpWidget(_harnessWithRouter(friend: _makeFriend()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Each OutlinedButton for actions is wrapped in a ConstrainedBox with
      // minHeight: 48.  Verify the rendered height via getRect.
      for (final label in ['Call', 'SMS', 'WhatsApp']) {
        final buttonFinder = find.widgetWithText(OutlinedButton, label);
        final rect = tester.getRect(buttonFinder);
        expect(
          rect.height,
          greaterThanOrEqualTo(48),
          reason: '$label button must be at least 48dp tall',
        );
      }
    });
  });
}
