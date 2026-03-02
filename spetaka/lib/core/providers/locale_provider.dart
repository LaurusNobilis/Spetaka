// locale_provider.dart
//
// Persists the user's language preference via shared_preferences.
// Defaults to French ('fr') — change the constant below to alter the default.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

/// Language codes supported by the app.
const supportedLocaleCodes = ['fr', 'en'];

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    Future.microtask(_load);
    return const Locale('fr'); // French by default
  }

  /// Switches to [locale] and persists the choice.
  Future<void> set(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLocaleKey);
    if (stored != null && supportedLocaleCodes.contains(stored)) {
      state = Locale(stored);
    }
  }
}

/// Provider for the current [Locale].
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
