import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spetaka/core/database/app_database.dart';
import 'package:spetaka/core/l10n/app_localizations.dart';
import 'package:spetaka/core/router/app_router.dart';
import 'package:spetaka/features/daily/data/daily_view_provider.dart';
import 'package:spetaka/features/friends/data/friends_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpShellApp(WidgetTester tester) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchDailyViewProvider.overrideWith(
            (_) => const AsyncData(<DailyViewEntry>[]),
          ),
          allFriendsProvider.overrideWith(
            (_) => Stream<List<Friend>>.value(const <Friend>[]),
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

    await tester.pumpAndSettle();
  }

  testWidgets('swipe switches Daily → Friends', (tester) async {
    await pumpShellApp(tester);

    expect(find.text('Daily'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Friends'), findsOneWidget);
  });

  testWidgets('Android back from Friends returns to Daily', (tester) async {
    await pumpShellApp(tester);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Friends'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Daily'), findsOneWidget);
  });

  testWidgets('page indicator has localized semantics label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpShellApp(tester);

    expect(
      find.bySemanticsLabel(
        'Current page: Daily. Swipe left or right to switch pages.',
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        'Current page: Friends. Swipe left or right to switch pages.',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });
}
