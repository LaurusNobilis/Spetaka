import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-fetch DM Sans and Lora via google_fonts cache so the first frame
  // already renders the correct typefaces.
  unawaited(AppTheme.loadFonts());
  runApp(const SpetakaApp());
}
