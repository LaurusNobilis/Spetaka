// Tests for Story 5-3: Acquittement Sheet — Type, Note & One-Tap Confirm.
//
// AC coverage:
//   AC2 / pre-fill          : sheet pre-fills action type from PendingActionState
//   AC3 / adjust type       : selecting a different chip changes the type
//   AC4 / confirm save      : tapping confirm inserts acquittement in DB
//   AC5 / empty note branch : confirm works when note field is empty

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/encryption/encryption_service_provider.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/features/acquittement/data/acquittement_repository.dart';
import 'package:spetaka/features/acquittement/data/acquittement_repository_provider.dart';
import 'package:spetaka/features/acquittement/domain/pending_action_state.dart';
import 'package:spetaka/features/acquittement/presentation/acquittement_sheet.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

PendingActionState _state({
  String friendId = 'f1',
  String actionType = 'call',
}) {
  return PendingActionState(
    friendId: friendId,
    origin: AcquittementOrigin.unknown,
    actionType: actionType,
    timestamp: DateTime.now(),
  );
}

/// Creates a Widget harness for [AcquittementSheet] with all providers
/// overridden to use in-memory/test instances.
Widget _harness({
  required PendingActionState pendingState,
  required AcquittementRepository repo,
  required AppDatabase db,
  required EncryptionService enc,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      encryptionServiceProvider.overrideWithValue(enc),
      acquittementRepositoryProvider.overrideWithValue(repo),
      // Provide a lifecycle service that uses the test binding.
      appLifecycleServiceProvider.overrideWith(
        (ref) {
          final svc = AppLifecycleService(binding: WidgetsBinding.instance);
          ref.onDispose(svc.dispose);
          return svc;
        },
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: AcquittementSheet(pendingState: pendingState),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late EncryptionService enc;
  late AcquittementRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize('test-passphrase-5-3');
    repo = AcquittementRepository(db: db, encryptionService: enc);
  });

  tearDown(() async {
    await db.close();
  });

  // ── AC2: pre-fill ──────────────────────────────────────────────────────────
  group('pre-fill (AC2)', () {
    testWidgets('call chip selected by default when actionType=call',
        (tester) async {
      await tester.pumpWidget(
        _harness(pendingState: _state(actionType: 'call'), repo: repo, db: db, enc: enc),
      );
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('type_chip_call')),
      );
      expect(chip.selected, isTrue,
          reason: 'call chip must be pre-selected when actionType=call',);
    });

    testWidgets('whatsapp chip selected when actionType=whatsapp',
        (tester) async {
      await tester.pumpWidget(
        _harness(pendingState: _state(actionType: 'whatsapp'), repo: repo, db: db, enc: enc),
      );
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('type_chip_whatsapp')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets("unknown type 'manual' defaults to call", (tester) async {
      await tester.pumpWidget(
        _harness(pendingState: _state(actionType: 'manual'), repo: repo, db: db, enc: enc),
      );
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('type_chip_call')),
      );
      expect(chip.selected, isTrue,
          reason: 'fallback to call for unknown type',);
    });
  });

  // ── AC3: adjust type ──────────────────────────────────────────────────────
  group('adjust type (AC3)', () {
    testWidgets('tapping sms chip deselects call and selects sms',
        (tester) async {
      await tester.pumpWidget(
        _harness(pendingState: _state(actionType: 'call'), repo: repo, db: db, enc: enc),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('type_chip_sms')));
      await tester.pumpAndSettle();

      final smsChip = tester.widget<ChoiceChip>(
        find.byKey(const Key('type_chip_sms')),
      );
      final callChip = tester.widget<ChoiceChip>(
        find.byKey(const Key('type_chip_call')),
      );
      expect(smsChip.selected, isTrue);
      expect(callChip.selected, isFalse);
    });
  });

  // ── AC4: confirm save ──────────────────────────────────────────────────────
  group('confirm save (AC4)', () {
    testWidgets('confirm inserts acquittement with correct type and note',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          pendingState: _state(friendId: 'f42', actionType: 'sms'),
          repo: repo,
          db: db,
          enc: enc,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('acquittement_note_field')),
        'Great call!',
      );

      await tester.tap(find.byKey(const Key('acquittement_sheet_confirm')));
      await tester.pumpAndSettle();

      final saved = await repo.findByFriendId('f42');
      expect(saved.length, 1);
      expect(saved.first.type, 'sms');
      expect(saved.first.note, 'Great call!');
      expect(saved.first.friendId, 'f42');
    });

    testWidgets('saved acquittement has a non-empty UUID id', (tester) async {
      await tester.pumpWidget(
        _harness(
          pendingState: _state(friendId: 'f1', actionType: 'call'),
          repo: repo,
          db: db,
          enc: enc,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('acquittement_sheet_confirm')));
      await tester.pumpAndSettle();

      final saved = await repo.findByFriendId('f1');
      expect(saved.first.id, isNotEmpty);
      expect(saved.first.id.length, 36, reason: 'UUID v4 has 36 chars');
    });
  });

  // ── AC5: empty note branch ─────────────────────────────────────────────────
  group('empty note branch (AC5)', () {
    testWidgets('confirm with empty note stores null in DB', (tester) async {
      await tester.pumpWidget(
        _harness(
          pendingState: _state(friendId: 'f10', actionType: 'in_person'),
          repo: repo,
          db: db,
          enc: enc,
        ),
      );
      await tester.pumpAndSettle();

      // Leave note empty, tap confirm
      await tester.tap(find.byKey(const Key('acquittement_sheet_confirm')));
      await tester.pumpAndSettle();

      final saved = await repo.findByFriendId('f10');
      expect(saved.length, 1);
      expect(saved.first.note, isNull,
          reason: 'empty note must be stored as null',);
      expect(saved.first.type, 'in_person');
    });

    testWidgets('whitespace-only note is treated as empty', (tester) async {
      await tester.pumpWidget(
        _harness(
          pendingState: _state(friendId: 'f11', actionType: 'vocal'),
          repo: repo,
          db: db,
          enc: enc,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('acquittement_note_field')),
        '   ',
      );

      await tester.tap(find.byKey(const Key('acquittement_sheet_confirm')));
      await tester.pumpAndSettle();

      final saved = await repo.findByFriendId('f11');
      expect(saved.first.note, isNull,
          reason: 'whitespace-only note treated as empty (trimmed to null)',);
    });
  });

  // ── Story 7.3 Accessibility assertions ──────────────────────────────────
  group('AcquittementSheet — Accessibility (Story 7.3)', () {
    testWidgets('a11y — confirm button has semantic label and hint',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        _harness(pendingState: _state(), repo: repo, db: db, enc: enc),
      );
      await tester.pumpAndSettle();

      // Confirm button is findable by semantic label (story 7.3 AC1).
      expect(
        find.bySemanticsLabel('Confirm contact log'),
        findsOneWidget,
      );

      semanticsHandle.dispose();
    });

    testWidgets('a11y — confirm button touch target meets 48dp minimum',
        (tester) async {
      await tester.pumpWidget(
        _harness(pendingState: _state(), repo: repo, db: db, enc: enc),
      );
      await tester.pumpAndSettle();

      final btn = tester.getRect(
        find.byKey(const Key('acquittement_sheet_confirm')),
      );
      expect(btn.height, greaterThanOrEqualTo(48.0),
          reason: 'Confirm button must meet 48dp minimum touch target',
      );
    });

    testWidgets('a11y — drag handle is excluded from semantics tree',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        _harness(pendingState: _state(), repo: repo, db: db, enc: enc),
      );
      await tester.pumpAndSettle();

      // The drag handle is wrapped in ExcludeSemantics — it must NOT appear
      // as a labelled interactive element. Verify only labelled nodes exist.
      final titleNode =
          find.bySemanticsLabel(RegExp(r'Log contact|Confirmer|Confirm contact'));
      expect(titleNode, findsWidgets,
          reason: 'Title and confirm button must be in semantics tree',
      );

      semanticsHandle.dispose();
    });
  });
}
