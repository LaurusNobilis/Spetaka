import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/ai/hf_token_service.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hfToken = await const HfTokenService().getToken();
  await FlutterGemma.initialize(
    huggingFaceToken: hfToken,
  );
  // Pre-fetch DM Sans and Lora via google_fonts cache so the first frame
  // already renders the correct typefaces.
  unawaited(AppTheme.loadFonts());
  runApp(
    const ProviderScope(
      child: SpetakaApp(),
    ),
  );
}
