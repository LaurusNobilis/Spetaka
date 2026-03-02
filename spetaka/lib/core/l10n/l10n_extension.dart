// l10n_extension.dart
//
// Convenience extension to access [AppLocalizations] with `context.l10n`.

import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  /// Shorthand for [AppLocalizations.of(context)].
  AppLocalizations get l10n => AppLocalizations.of(this);
}
