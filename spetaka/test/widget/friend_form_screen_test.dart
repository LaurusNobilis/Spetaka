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

/// Builds the full router-test scaffold with an in-memory repo.
/// [allFriendsFutureProvider] is overridden to use the same repo instance,
/// ensuring the FutureProvider resolves synchronously-ish after navigation.
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
        // Override allFriendsFutureProvider to avoid real-async timing in tests.
        // It delegates to the real repo so save → list round-trips work.
        allFriendsFutureProvider.overrideWith((ref) => repo.findAll()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );

  router.go(const NewFriendRoute().location);
  await tester.pumpAndSettle();

  // Tap "Enter manually" to reveal the manual-entry form.
  await tester.tap(find.text('Enter manually'));
  await tester.pumpAndSettle();

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

    // runAsync lets the full async chain complete:
    // PhoneNormalizer → Friend() → repo.insert() → context.go()
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));

    // Pump to render the navigation to /friends and the loading indicator.
    await tester.pump();
    // Allow the FutureProvider (findAll) which runs in real async to resolve.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
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
          allFriendsFutureProvider.overrideWith((ref) => repo.findAll()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go(const FriendsRoute().location);
    // runAsync lets the FutureProvider complete its findAll() DB call.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Friends'), findsAtLeastNWidgets(1));
    expect(find.text('Alice'), findsAtLeastNWidgets(1));

    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });

  testWidgets('AC2 — empty name shows inline error, no snackbar', (tester) async {
    final h = await _buildHarness(tester);

    // Leave name empty; provide a valid phone.
    await tester.enterText(find.byType(TextField).at(1), '06 12 34 56 78');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    expect(find.text('Please enter a mobile number.'), findsOneWidget);
    expect(find.text('Add Friend'), findsAtLeastNWidgets(1));
    expect(find.byType(SnackBar), findsNothing);

    await h.dispose();
  });
}

