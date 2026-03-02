import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/encryption/encryption_service_provider.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

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
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    // Show a blank loading screen for the < 50 ms it takes to read prefs.
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp.router(
      title: 'Spetaka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
