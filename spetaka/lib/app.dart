import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/ai/ai_capability_checker.dart';
import 'core/ai/model_manager.dart';
import 'core/encryption/encryption_service_provider.dart';
import 'core/l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'features/drafts/presentation/model_download_screen.dart';
import 'features/settings/data/display_prefs_provider.dart';
import 'shared/theme/app_theme.dart';

// Production router instance — wired with the real ModelDownloadScreen.
// Kept here so that app_router.dart itself does not import flutter_gemma,
// which would pull it into every test that imports any feature screen.
final GoRouter appRouter = createAppRouter(
  modelDownloadBuilder: (_) => const ModelDownloadScreen(),
);

/// Root widget. Initialises the device-local encryption key on first build
/// so every subsequent DB access can encrypt/decrypt fields transparently.
class SpetakaApp extends ConsumerStatefulWidget {
  const SpetakaApp({super.key});

  @override
  ConsumerState<SpetakaApp> createState() => _SpetakaAppState();
}

class _SpetakaAppState extends ConsumerState<SpetakaApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ref.read(encryptionServiceProvider).initializeWithDeviceKey();

    try {
      await ref.read(aiCapabilityCheckerProvider.notifier).initialize();
      if (ref.read(aiCapabilityCheckerProvider)) {
        await ref.read(modelManagerProvider.notifier).initialize();
      }
    } catch (error, stackTrace) {
      dev.log(
        'AI bootstrap failed: $error',
        name: 'ai.bootstrap',
        stackTrace: stackTrace,
      );
    }

    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final fontScale = ref.watch(fontScaleModeProvider);
    final iconSize = ref.watch(iconSizeModeProvider);
    final darkModeEnabled = ref.watch(darkModeEnabledProvider);
    final themeMode = darkModeEnabled ? ThemeMode.dark : ThemeMode.light;

    // Build themed variants with the user's preferred icon size.
    final lightTheme = AppTheme.light().copyWith(
      iconTheme: IconThemeData(size: iconSize.size),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(iconSize: iconSize.size),
      ),
    );
    final darkTheme = AppTheme.dark().copyWith(
      iconTheme: IconThemeData(size: iconSize.size),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(iconSize: iconSize.size),
      ),
    );

    // Show a blank loading screen for the < 50 ms it takes to read prefs.
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp.router(
      title: 'Spetaka',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
      // Apply user-selected text scale factor over the entire app.
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontScale.factor),
          ),
          child: child!,
        );
      },
    );
  }
}

