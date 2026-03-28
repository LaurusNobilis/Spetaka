import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/features/drafts/domain/draft_message.dart';
import 'package:spetaka/features/drafts/presentation/draft_message_sheet.dart';
import 'package:spetaka/features/drafts/providers/draft_message_providers.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';

DraftMessage _draft({List<String> variants = const ['v1', 'v2', 'v3']}) {
  return DraftMessage(
    friendId: 'f1',
    friendName: 'Sophie',
    eventContext: 'Anniversaire',
    channel: 'whatsapp',
    variants: variants,
  );
}

Friend _friend({String mobile = '+33600000001'}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Friend(
    id: 'f1',
    name: 'Sophie',
    mobile: mobile,
    tags: null,
    notes: null,
    careScore: 0,
    isConcernActive: false,
    concernNote: null,
    isDemo: false,
    createdAt: now,
    updatedAt: now,
  );
}

Event _event({DateTime? date}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Event(
    id: 'e1',
    friendId: 'f1',
    type: 'Anniversaire',
    date: (date ?? DateTime(2026, 3, 28)).millisecondsSinceEpoch,
    isRecurring: false,
    comment: null,
    isAcknowledged: false,
    acknowledgedAt: null,
    createdAt: now,
    cadenceDays: null,
  );
}

class _ControlledDraftNotifier extends DraftMessageNotifier {
  _ControlledDraftNotifier({
    required this.initialState,
    this.onRequest,
    this.onClear,
  });

  final AsyncValue<DraftMessage?> initialState;
  final FutureOr<void> Function(_ControlledDraftNotifier notifier)? onRequest;
  final VoidCallback? onClear;

  @override
  AsyncValue<DraftMessage?> build() => initialState;

  @override
  Future<void> requestSuggestions({
    required String friendId,
    required Event event,
    required String channel,
  }) async {
    await onRequest?.call(this);
  }

  @override
  void clear() {
    onClear?.call();
    super.clear();
  }
}

class _SheetLauncher extends ConsumerWidget {
  const _SheetLauncher({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: () => showDraftMessageSheet(
        context: context,
        ref: ref,
        friendId: 'f1',
        event: event,
      ),
      child: const Text('Open sheet'),
    );
  }
}

Widget _buildHarness({
  required ProviderContainer container,
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('opening sheet in loading state shows LinearProgressIndicator', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        draftMessageProvider.overrideWith(
          () => _ControlledDraftNotifier(initialState: const AsyncLoading()),
        ),
        friendByIdProvider('f1').overrideWith((_) async => _friend()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildHarness(
        container: container,
        child: _SheetLauncher(event: _event()),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Generating...'), findsOneWidget);
  });

  testWidgets('data state shows relative header and confirm button', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        draftMessageProvider.overrideWith(
          () => _ControlledDraftNotifier(initialState: AsyncData(_draft())),
        ),
        friendByIdProvider('f1').overrideWith((_) async => _friend()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildHarness(
        container: container,
        locale: const Locale('fr'),
        child: _SheetLauncher(
          event: _event(date: DateTime.now().add(const Duration(days: 3))),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('v1'), findsWidgets);
    expect(find.text('v2'), findsOneWidget);
    expect(find.text('v3'), findsOneWidget);
    expect(
      find.text('Pour Sophie — Anniversaire dans 3 jours'),
      findsOneWidget,
    );
    expect(find.text('Copier et envoyer via WhatsApp'), findsOneWidget);
  });

  testWidgets('generate more button is enabled and re-requests suggestions', (
    tester,
  ) async {
    var requestCount = 0;
    final container = ProviderContainer(
      overrides: [
        draftMessageProvider.overrideWith(
          () => _ControlledDraftNotifier(
            initialState: AsyncData(_draft(variants: const ['v1'])),
            onRequest: (_) => requestCount++,
          ),
        ),
        friendByIdProvider('f1').overrideWith((_) async => _friend()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildHarness(
        container: container,
        locale: const Locale('fr'),
        child: _SheetLauncher(event: _event()),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Générer plus'), findsOneWidget);

    await tester.tap(find.text('Générer plus'));
    await tester.pump();

    expect(requestCount, 2);
  });

  testWidgets('discard button dismisses sheet and clears provider state', (
    tester,
  ) async {
    var clearCalled = false;
    final container = ProviderContainer(
      overrides: [
        draftMessageProvider.overrideWith(
          () => _ControlledDraftNotifier(
            initialState: AsyncData(_draft()),
            onClear: () => clearCalled = true,
          ),
        ),
        friendByIdProvider('f1').overrideWith((_) async => _friend()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildHarness(
        container: container,
        child: _SheetLauncher(event: _event()),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(clearCalled, isTrue);
    expect(find.text('Discard'), findsNothing);
    expect(container.read(draftMessageProvider).value, isNull);
  });

  testWidgets('back dismissal clears the in-memory draft', (tester) async {
    var clearCalled = false;
    final container = ProviderContainer(
      overrides: [
        draftMessageProvider.overrideWith(
          () => _ControlledDraftNotifier(
            initialState: AsyncData(_draft()),
            onClear: () => clearCalled = true,
          ),
        ),
        friendByIdProvider('f1').overrideWith((_) async => _friend()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildHarness(
        container: container,
        child: _SheetLauncher(event: _event()),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(clearCalled, isTrue);
    expect(container.read(draftMessageProvider).value, isNull);
  });

  testWidgets('error state shows error text and editable field', (tester) async {
    final container = ProviderContainer(
      overrides: [
        draftMessageProvider.overrideWith(
          () => _ControlledDraftNotifier(
            initialState: AsyncData(_draft(variants: const [])),
          ),
        ),
        friendByIdProvider('f1').overrideWith((_) async => _friend()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildHarness(
        container: container,
        child: _SheetLauncher(event: _event()),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Couldn't generate suggestions right now. You can write your own message below.",
      ),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
  });
}
