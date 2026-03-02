// display_prefs_provider.dart
//
// Persists the user's font-scale and icon-size preferences via
// shared_preferences.  Both notifiers follow the same pattern as
// DensityNotifier: initialise with a sensible default then asynchronously
// load the stored value so the UI never blocks on I/O at startup.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Font scale
// ---------------------------------------------------------------------------

/// Three discrete text-scaling levels.
enum FontScaleMode {
  small(0.85),
  medium(1.0),
  large(1.2);

  const FontScaleMode(this.factor);

  /// The [TextScaler.linear] factor applied at the [MaterialApp] level.
  final double factor;
}

const _kFontScaleKey = 'font_scale_mode';

/// Notifier that exposes and persists the user's [FontScaleMode].
class FontScaleNotifier extends Notifier<FontScaleMode> {
  @override
  FontScaleMode build() {
    Future.microtask(_load);
    return FontScaleMode.medium;
  }

  Future<void> set(FontScaleMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontScaleKey, mode.name);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kFontScaleKey);
    if (stored == null) return;
    final found = FontScaleMode.values.where((m) => m.name == stored);
    if (found.isNotEmpty) state = found.first;
  }
}

/// Provider for [FontScaleMode].
final fontScaleModeProvider =
    NotifierProvider<FontScaleNotifier, FontScaleMode>(FontScaleNotifier.new);

// ---------------------------------------------------------------------------
// Icon size
// ---------------------------------------------------------------------------

/// Three discrete icon-size levels (in logical pixels).
enum IconSizeMode {
  small(20.0),
  medium(24.0),
  large(30.0);

  const IconSizeMode(this.size);

  /// Logical-pixel icon size applied via [ThemeData.iconTheme].
  final double size;
}

const _kIconSizeKey = 'icon_size_mode';

/// Notifier that exposes and persists the user's [IconSizeMode].
class IconSizeNotifier extends Notifier<IconSizeMode> {
  @override
  IconSizeMode build() {
    Future.microtask(_load);
    return IconSizeMode.medium;
  }

  Future<void> set(IconSizeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIconSizeKey, mode.name);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kIconSizeKey);
    if (stored == null) return;
    final found = IconSizeMode.values.where((m) => m.name == stored);
    if (found.isNotEmpty) state = found.first;
  }
}

/// Provider for [IconSizeMode].
final iconSizeModeProvider =
    NotifierProvider<IconSizeNotifier, IconSizeMode>(IconSizeNotifier.new);
