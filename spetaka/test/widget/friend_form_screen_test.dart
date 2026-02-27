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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('manual entry saves friend and navigates to /friends', (tester) async {
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
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    router.go(const NewFriendRoute().location);
    await tester.pumpAndSettle();

    expect(find.text('Add Friend'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Alice');
    await tester.enterText(find.byType(TextField).at(1), '06 12 34 56 78');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Friends'), findsAtLeastNWidgets(1));

    final all = await repo.findAll();
    expect(all, hasLength(1));
    expect(all.first.name, 'Alice');
    expect(all.first.mobile, '+33612345678');

    await db.close();
    enc.dispose();
    lifecycle.dispose();
  });
}
