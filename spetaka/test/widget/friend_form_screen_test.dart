import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/encryption/encryption_service.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/core/lifecycle/app_lifecycle_service.dart';
import 'package:spetaka/core/router/app_router.dart';
import 'package:spetaka/features/acquittement/data/acquittement_providers.dart';
import 'package:spetaka/features/daily/data/daily_view_provider.dart';
import 'package:spetaka/features/events/data/event_type_providers.dart';
import 'package:spetaka/features/events/data/events_providers.dart';
import 'package:spetaka/features/friends/data/friend_repository.dart';
import 'package:spetaka/features/friends/data/friend_repository_provider.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';
import 'package:spetaka/features/friends/domain/friend_form_draft.dart';
import 'package:spetaka/features/friends/domain/friend_tags_codec.dart';
import 'package:spetaka/features/friends/presentation/friend_form_screen.dart';
import 'package:spetaka/features/friends/presentation/friends_list_screen.dart';
import 'package:spetaka/features/friends/providers/friend_form_draft_provider.dart';
import 'package:spetaka/features/shell/presentation/app_shell_screen.dart';

GoRouter _createTestRouter() => GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: const HomeRoute().location,
      builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
    ),
    GoRoute(
      path: const FriendsRoute().location,
      builder: (_, __) => const FriendsListScreen(),
    ),
    GoRoute(
      path: const NewFriendRoute().location,
      builder: (_, __) => const FriendFormScreen(),
    ),
    GoRoute(
      path: const SettingsRoute().location,
      builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
    ),
  ],
);

GoRouter _createDraftTestRouter() => GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: const FriendsRoute().location,
      builder: (_, __) => const Scaffold(body: Center(child: Text('Friends'))),
    ),
    GoRoute(
      path: const NewFriendRoute().location,
      builder: (_, __) => const FriendFormScreen(),
    ),
    GoRoute(
      path: '/friends/:id/edit',
      builder: (_, state) => FriendFormScreen(
        editFriendId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/friends/:id',
      builder: (_, state) => Scaffold(
        body: Center(
          child: Text('Friend detail ${state.pathParameters['id']}'),
        ),
      ),
    ),
  ],
);

/// Builds the full router-test scaffold with an in-memory repo.
/// Friends list data is reactive via repository watchAll() (StreamProvider).
Future<_TestHarness> _buildHarness(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});

  final db = AppDatabase(NativeDatabase.memory());
  final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
  final enc = EncryptionService(lifecycleService: lifecycle);
  await enc.initialize('spetaka-widget-test-pass');

  final repo = FriendRepository(db: db, encryptionService: enc);
  final router = _createTestRouter();

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
        lastContactByFriendProvider.overrideWith(
          (ref) => Stream<Map<String, int>>.value(const <String, int>{}),
        ),
        // Story 4.2: DailyViewScreen (root route, beneath this stack) also
        // needs its event stream stubbed to prevent Drift timer leaks.
        watchPriorityInputEventsProvider.overrideWith(
          (ref) => Stream<List<Event>>.value(const <Event>[]),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
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
      isDemo: false,
      createdAt: now,
      updatedAt: now,
    ),);

    final router = _createTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendRepositoryProvider.overrideWithValue(repo),
          lastContactByFriendProvider.overrideWith(
            (_) => Stream<Map<String, int>>.value(const <String, int>{}),
          ),
          // Story 4.2: DailyViewScreen (root route, beneath /friends) watches
          // this provider; stub it to prevent Drift timer leaks.
          watchPriorityInputEventsProvider.overrideWith(
            (_) => Stream<List<Event>>.value(const <Event>[]),
          ),
        ],
        child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
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

    final router = _createTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendRepositoryProvider.overrideWithValue(repo),
          // Keep the real StreamProvider so the list updates after insert.
          // Do NOT use pumpAndSettle in this test (live Drift stream).
          allFriendsProvider.overrideWith(
            (ref) => ref.watch(friendRepositoryProvider).watchAll(),
          ),
          lastContactByFriendProvider.overrideWith(
            (_) => Stream<Map<String, int>>.value(const <String, int>{}),
          ),
          // Story 4.2: DailyViewScreen (root route) also watches events;
          // stub it to prevent a second open Drift timer on teardown.
          watchPriorityInputEventsProvider.overrideWith(
            (_) => Stream<List<Event>>.value(const <Event>[]),
          ),
        ],
        child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
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
    await tester.tap(find.text('Famille'));
    await tester.pump();
    await tester.tap(find.text('Travail'));
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
    expect(find.widgetWithText(Chip, 'Famille'), findsAtLeastNWidgets(1));
    expect(find.widgetWithText(Chip, 'Travail'), findsAtLeastNWidgets(1));

    // Also sanity-check persistence format is stable JSON.
    final all = await repo.findAll();
    expect(all, hasLength(1));
    expect(decodeFriendTags(all.first.tags), <String>['Famille', 'Travail']);

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

  // ---------------------------------------------------------------------------
  // Story 10.4 — Session-Draft Auto-Save tests
  // ---------------------------------------------------------------------------

  testWidgets('10.4/AC1 — typing, navigating away, and returning restores the draft', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final db = AppDatabase(NativeDatabase.memory());
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize('spetaka-widget-test-pass');
    final repo = FriendRepository(db: db, encryptionService: enc);
    final router = _createDraftTestRouter();

    final container = ProviderContainer(
      overrides: [
        friendRepositoryProvider.overrideWithValue(repo),
        allFriendsProvider.overrideWith(
          (ref) => Stream<List<Friend>>.value(const <Friend>[]),
        ),
        watchPriorityInputEventsProvider.overrideWith(
          (ref) => Stream<List<Event>>.value(const <Event>[]),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );

    router.go(const NewFriendRoute().location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Enter manually'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).at(0), 'DraftAlice');
    await tester.pump(const Duration(milliseconds: 350));

    expect(container.read(friendFormDraftProvider)?.name, 'DraftAlice');

    router.go(const FriendsRoute().location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    router.go(const NewFriendRoute().location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // AC1 — banner is visible.
    expect(find.text('Resuming your draft'), findsOneWidget);
    // AC1 — name field is pre-filled from draft.
    expect(find.text('DraftAlice'), findsOneWidget);

    container.dispose();
    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });

  testWidgets('10.4/AC3 — draft cleared after successful save', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final db = AppDatabase(NativeDatabase.memory());
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize('spetaka-widget-test-pass');
    final repo = FriendRepository(db: db, encryptionService: enc);
    final router = _createDraftTestRouter();

    // Use a ProviderContainer to verify draft state after save.
    final container = ProviderContainer(
      overrides: [
        friendRepositoryProvider.overrideWithValue(repo),
        allFriendsProvider.overrideWith(
          (ref) => Stream<List<Friend>>.value(const <Friend>[]),
        ),
        watchPriorityInputEventsProvider.overrideWith(
          (ref) => Stream<List<Event>>.value(const <Event>[]),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );

    router.go(const NewFriendRoute().location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Enter manually'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Enter data — triggers debounced draft save.
    await tester.enterText(find.byType(TextField).at(0), 'Alice');
    await tester.enterText(find.byType(TextField).at(1), '06 12 34 56 78');
    // Wait for 300 ms debounce to fire.
    await tester.pump(const Duration(milliseconds: 350));

    // Verify draft was saved.
    expect(container.read(friendFormDraftProvider)?.name, 'Alice');

    // Save the friend.
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    // AC3 — draft is cleared after successful save.
    expect(container.read(friendFormDraftProvider), isNull);

    container.dispose();
    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });

  testWidgets('10.4/AC3 — save cancels pending debounce before it can restore the draft', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final db = AppDatabase(NativeDatabase.memory());
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize('spetaka-widget-test-pass');
    final repo = FriendRepository(db: db, encryptionService: enc);
    final router = _createDraftTestRouter();

    final container = ProviderContainer(
      overrides: [
        friendRepositoryProvider.overrideWithValue(repo),
        allFriendsProvider.overrideWith(
          (ref) => Stream<List<Friend>>.value(const <Friend>[]),
        ),
        watchPriorityInputEventsProvider.overrideWith(
          (ref) => Stream<List<Event>>.value(const <Event>[]),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );

    router.go(const NewFriendRoute().location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Enter manually'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).at(0), 'Alice');
    await tester.enterText(find.byType(TextField).at(1), '06 12 34 56 78');

    // Save immediately, before the 300 ms debounce callback can fire.
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(friendFormDraftProvider), isNull);

    container.dispose();
    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });

  testWidgets('10.4/AC4 — discard banner resets form to empty in create mode', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final db = AppDatabase(NativeDatabase.memory());
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize('spetaka-widget-test-pass');
    final repo = FriendRepository(db: db, encryptionService: enc);
    final router = _createDraftTestRouter();

    final container = ProviderContainer(
      overrides: [
        friendRepositoryProvider.overrideWithValue(repo),
        allFriendsProvider.overrideWith(
          (ref) => Stream<List<Friend>>.value(const <Friend>[]),
        ),
        watchPriorityInputEventsProvider.overrideWith(
          (ref) => Stream<List<Event>>.value(const <Event>[]),
        ),
      ],
    );

    container.read(friendFormDraftProvider.notifier).update(
      const FriendFormDraft(name: 'DraftBob', mobile: '06 99 88 77 66'),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );

    router.go(const NewFriendRoute().location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Banner and draft name visible.
    expect(find.text('Resuming your draft'), findsOneWidget);
    expect(find.text('DraftBob'), findsOneWidget);

    // AC4 — tap Discard.
    await tester.tap(find.text('Discard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Banner gone.
    expect(find.text('Resuming your draft'), findsNothing);
    // Draft cleared in provider.
    expect(container.read(friendFormDraftProvider), isNull);
    // Name field is now empty.
    final nameField = tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    expect(nameField.controller?.text ?? '', isEmpty);

    container.dispose();
    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });

  testWidgets('10.4/AC1/AC4 — edit mode restores draft and discard resets to persisted values', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final db = AppDatabase(NativeDatabase.memory());
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize('spetaka-widget-test-pass');
    final repo = FriendRepository(db: db, encryptionService: enc);
    final router = _createDraftTestRouter();

    final now = DateTime.now().millisecondsSinceEpoch;
    const friendId = 'friend-1';
    await repo.insert(Friend(
      id: friendId,
      name: 'Persisted Alice',
      mobile: '+33600000001',
      tags: encodeFriendTags({'Famille'}),
      notes: 'Saved note',
      careScore: 0.0,
      isConcernActive: false,
      concernNote: null,
      isDemo: false,
      createdAt: now,
      updatedAt: now,
    ),);

    final container = ProviderContainer(
      overrides: [
        friendRepositoryProvider.overrideWithValue(repo),
        allFriendsProvider.overrideWith(
          (ref) => Stream<List<Friend>>.value(const <Friend>[]),
        ),
        watchPriorityInputEventsProvider.overrideWith(
          (ref) => Stream<List<Event>>.value(const <Event>[]),
        ),
      ],
    );

    container.read(friendFormDraftProvider.notifier).update(
      const FriendFormDraft(
        name: 'Draft Alice',
        mobile: '06 11 22 33 44',
        notes: 'Draft note',
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );

    router.go('/friends/$friendId/edit');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Resuming your draft'), findsOneWidget);
    expect(find.text('Draft Alice'), findsOneWidget);
    expect(find.text('Draft note'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(friendFormDraftProvider), isNull);

    final nameField = tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    final mobileField = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
    final notesField = tester.widget<TextFormField>(find.byType(TextFormField).at(2));

    expect(nameField.controller?.text, 'Persisted Alice');
    expect(mobileField.controller?.text, '+33600000001');
    expect(notesField.controller?.text, 'Saved note');

    container.dispose();
    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });

  testWidgets('2.7/AC4 — stacked edit save pops back to friend detail route', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final db = AppDatabase(NativeDatabase.memory());
    final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
    final enc = EncryptionService(lifecycleService: lifecycle);
    await enc.initialize('spetaka-widget-test-pass');
    final repo = FriendRepository(db: db, encryptionService: enc);
    final router = _createDraftTestRouter();

    final now = DateTime.now().millisecondsSinceEpoch;
    const friendId = 'friend-2';
    await repo.insert(Friend(
      id: friendId,
      name: 'Before Edit',
      mobile: '+33600000002',
      tags: null,
      notes: null,
      careScore: 0.0,
      isConcernActive: false,
      concernNote: null,
      isDemo: false,
      createdAt: now,
      updatedAt: now,
    ),);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendRepositoryProvider.overrideWithValue(repo),
          allFriendsProvider.overrideWith(
            (ref) => Stream<List<Friend>>.value(const <Friend>[]),
          ),
          watchPriorityInputEventsProvider.overrideWith(
            (ref) => Stream<List<Event>>.value(const <Event>[]),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );

    router.go('/friends/$friendId');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Friend detail $friendId'), findsOneWidget);

    router.push('/friends/$friendId/edit');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextFormField).at(0), 'After Edit');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Friend detail $friendId'), findsOneWidget);

    final saved = await repo.findById(friendId);
    expect(saved, isNotNull);
    expect(saved!.name, 'After Edit');

    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });

  // M2 (4.7 review): verify that edit-save preserves the real AppShellScreen
  // when stacked above the friend-detail overlay on the root navigator.
  testWidgets(
    '4.7/AC6 — edit-save with real shell pops back to detail overlay, shell stays mounted',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final db = AppDatabase(NativeDatabase.memory());
      final lifecycle = AppLifecycleService(binding: WidgetsBinding.instance);
      final enc = EncryptionService(lifecycleService: lifecycle);
      await enc.initialize('spetaka-shell-edit-test-pass');
      final repo = FriendRepository(db: db, encryptionService: enc);

      final now = DateTime.now().millisecondsSinceEpoch;
      const friendId = 'friend-shell-edit';
      await repo.insert(Friend(
        id: friendId,
        name: 'Shell Edit Before',
        mobile: '+33600000099',
        tags: null,
        notes: null,
        careScore: 0.0,
        isConcernActive: false,
        concernNote: null,
        isDemo: false,
        createdAt: now,
        updatedAt: now,
      ),);

      // Use the real createAppRouter so AppShellScreen is in the tree.
      final router = createAppRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendRepositoryProvider.overrideWithValue(repo),
            allFriendsProvider.overrideWith(
              (ref) => Stream<List<Friend>>.value(const <Friend>[]),
            ),
            lastContactByFriendProvider.overrideWith(
              (_) => Stream<Map<String, int>>.value(const <String, int>{}),
            ),
            watchDailyViewProvider.overrideWith(
              (_) => const AsyncData(<DailyViewEntry>[]),
            ),
            watchFriendByIdProvider(friendId).overrideWith(
              (_) => Stream<Friend?>.value(Friend(
                id: friendId,
                name: 'Shell Edit Before',
                mobile: '+33600000099',
                tags: null,
                notes: null,
                careScore: 0.0,
                isConcernActive: false,
                concernNote: null,
                isDemo: false,
                createdAt: now,
                updatedAt: now,
              ),),
            ),
            watchEventsByFriendProvider(friendId).overrideWith(
              (_) => Stream<List<Event>>.value(const <Event>[]),
            ),
            watchEventTypesProvider.overrideWith(
              (_) => Stream<List<EventTypeEntry>>.value(const <EventTypeEntry>[]),
            ),
            watchAcquittementsProvider(friendId).overrideWith(
              (_) => Stream<List<Acquittement>>.value(const <Acquittement>[]),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate shell to Friends, then push detail overlay.
      router.go(const FriendsRoute().location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      router.push(const FriendDetailRoute(friendId).location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Shell Edit Before'), findsAtLeastNWidgets(1));

      // Push edit overlay on top.
      router.push(const EditFriendRoute(friendId).location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'Shell Edit After');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should have popped back to detail overlay — shell still mounted.
      expect(find.byType(AppShellScreen, skipOffstage: false), findsOneWidget);

      await db.close();
      enc.dispose();
      lifecycle.dispose();
    },
  );
}

