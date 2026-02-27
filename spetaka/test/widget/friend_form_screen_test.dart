import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/core/router/app_router.dart';
import 'package:spetaka/features/friends/data/friend_repository.dart';
import 'package:spetaka/features/friends/data/friend_repository_provider.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/features/friends/domain/friend_tags_codec.dart';

/// Builds the full router-test scaffold with an in-memory repo.
/// Friends list data is reactive via repository watchAll() (StreamProvider).
Future<_TestHarness> _buildHarness(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});

  final db = AppDatabase(NativeDatabase.memory());
  final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
  final enc = EncryptionService(lifecycleService: lifecycle);
  await enc.initialize('spetaka-widget-test-pass');

  final repo = FriendRepository(db: db, encryptionService: enc);
  final router = createAppRouter();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        friendRepositoryProvider.overrideWithValue(repo),
        // Override the live Drift stream so FriendsListScreen (mounted
        // off-screen beneath /friends/new in the GoRouter Navigator stack)
        // does not keep Dart timers alive and block pumpAndSettle / pump.
        allFriendsProvider.overrideWith(
          (ref) => Stream<List<Friend>>.value(const <Friend>[]),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );

  router.go(const NewFriendRoute().location);
  // Do NOT use pumpAndSettle: FriendsListScreen's Drift StreamProvider is
  // mounted beneath this route and keeps the stream open.  pumpAndSettle
  // would wait 10 minutes before throwing in CI.
  // pump(300ms) is sufficient to complete GoRouter navigation and Material
  // entrance animations.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  // Tap "Enter manually" to reveal the manual-entry form.
  await tester.tap(find.text('Enter manually'));
  // One pump for setState rebuild + 300 ms for any InputDecorator animation.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  return _TestHarness(db: db, lifecycle: lifecycle, enc: enc, repo: repo);
}

class _TestHarness {
  _TestHarness({
    required this.db,
    required this.lifecycle,
    required this.enc,
    required this.repo,
  });

  final AppDatabase db;
  final AppLifecycleService lifecycle;
  final EncryptionService enc;
  final FriendRepository repo;

  Future<void> dispose() async {
    await db.close();
    enc.dispose();
    lifecycle.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AC1/AC3 — valid save persists friend and navigates to /friends', (tester) async {
    final h = await _buildHarness(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Alice');
    await tester.enterText(find.byType(TextField).at(1), '06 12 34 56 78');

    // AC3 — verify DB persistence via the repository directly.
    // We don't depend on the FutureProvider rendering for the persistence
    // test, just verify navigation (AC5) and DB state.
    await tester.tap(find.text('Save'));
    await tester.pump(); // dispatch tap

    // runAsync lets the full async chain complete in one pass:
    // PhoneNormalizer → Friend() → repo.insert() → context.go() → StreamProvider emit.
    // 500 ms is generous; real work is <10 ms on any CI machine.
    // TODO(2.5): replace with a FakeRepository once mock infra exists,
    //            eliminating real-async timing entirely.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));

    // Process any pending frames queued during runAsync before settling.
    // Without this intermediate pump, pumpAndSettle can hang on the live
    // Drift StreamProvider which never "completes".
    await tester.pump();
    await tester.pumpAndSettle();

    // AC5 — navigated back to the Friends list screen.
    expect(find.text('Friends'), findsAtLeastNWidgets(1));

    // AC3 — UUID v4 id, E.164 mobile, careScore 0.0 persisted to DB.
    final all = await h.repo.findAll();
    expect(all, hasLength(1));
    expect(all.first.name, 'Alice');
    expect(all.first.mobile, '+33612345678');
    expect(all.first.careScore, 0.0);

    await h.dispose();
  });

  /// Companion test: verifies AC5 (friend name visible) by navigating
  /// directly to the friends list after a friend already exists in the repo.
  testWidgets('AC5 — saved friend name appears in friends list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize('spetaka-widget-test-pass');
    final repo = FriendRepository(db: db, encryptionService: enc);

    // Pre-insert a friend so we don't rely on FutureProvider async timing
    // during the save flow.
    final now = DateTime.now().millisecondsSinceEpoch;
    await repo.insert(Friend(
      id: '00000000-0000-4000-8000-000000000001',
      name: 'Alice',
      mobile: '+33612345678',
      tags: null,
      notes: null,
      careScore: 0.0,
      isConcernActive: false,
      concernNote: null,
      createdAt: now,
      updatedAt: now,
    ),);

    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go(const FriendsRoute().location);
    // Avoid pumpAndSettle with a live Drift stream in the widget tree.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Friends'), findsAtLeastNWidgets(1));
    expect(find.text('Alice'), findsAtLeastNWidgets(1));

    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });

  testWidgets('Story 2.3 — selecting tags persists and renders chips in /friends list', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final db = AppDatabase(NativeDatabase.memory());
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize('spetaka-widget-test-pass');
    final repo = FriendRepository(db: db, encryptionService: enc);

    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendRepositoryProvider.overrideWithValue(repo),
          // Keep the real StreamProvider so the list updates after insert.
          // Do NOT use pumpAndSettle in this test (live Drift stream).
          allFriendsProvider.overrideWith(
            (ref) => ref.watch(friendRepositoryProvider).watchAll(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go(const NewFriendRoute().location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Enter manually'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).at(0), 'Charlie');
    await tester.enterText(find.byType(TextField).at(1), '06 12 34 56 78');

    // Select two tags.
    await tester.tap(find.text('Family'));
    await tester.pump();
    await tester.tap(find.text('Work'));
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pump();

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );

    // Allow navigation + provider rebuilds.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Friends'), findsAtLeastNWidgets(1));
    expect(find.text('Charlie'), findsAtLeastNWidgets(1));

    // Chips must be rendered (AC4).
    expect(find.widgetWithText(Chip, 'Family'), findsAtLeastNWidgets(1));
    expect(find.widgetWithText(Chip, 'Work'), findsAtLeastNWidgets(1));

    // Also sanity-check persistence format is stable JSON.
    final all = await repo.findAll();
    expect(all, hasLength(1));
    expect(decodeFriendTags(all.first.tags), <String>['Family', 'Work']);

    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });

  testWidgets('AC2 — empty name shows inline error, no snackbar', (tester) async {
    final h = await _buildHarness(tester);

    // Leave name empty; provide a valid phone.
    await tester.enterText(find.byType(TextField).at(1), '06 12 34 56 78');

    await tester.tap(find.text('Save'));
    // Form validation is synchronous — one pump rebuilds inline errors.
    // pumpAndSettle hangs here because the Drift StreamProvider keeps
    // emitting frames in the background (no navigation occurred).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Inline error must be visible.
    expect(find.text('Please enter a name.'), findsOneWidget);

    // Must NOT have navigated away or shown a SnackBar.
    expect(find.text('Add Friend'), findsAtLeastNWidgets(1));
    expect(find.byType(SnackBar), findsNothing);

    await h.dispose();
  });

  testWidgets('AC2 — invalid phone shows inline error, no snackbar', (tester) async {
    final h = await _buildHarness(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Bob');
    await tester.enterText(find.byType(TextField).at(1), 'abc-not-a-phone');

    await tester.tap(find.text('Save'));
    // Validation is synchronous — pump is sufficient, pumpAndSettle hangs.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Inline error from errorMessageFor(PhoneNormalizationAppError).
    expect(find.text('Invalid phone number. Please check and try again.'), findsOneWidget);

    // Must NOT have navigated away or shown a SnackBar.
    expect(find.text('Add Friend'), findsAtLeastNWidgets(1));
    expect(find.byType(SnackBar), findsNothing);

    await h.dispose();
  });

  testWidgets('AC2 — empty mobile shows inline error', (tester) async {
    final h = await _buildHarness(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Bob');
    // Leave mobile empty.

    await tester.tap(find.text('Save'));
    // Validation is synchronous — pump is sufficient, pumpAndSettle hangs.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Please enter a mobile number.'), findsOneWidget);
    expect(find.text('Add Friend'), findsAtLeastNWidgets(1));
    expect(find.byType(SnackBar), findsNothing);

    await h.dispose();
  });
}


