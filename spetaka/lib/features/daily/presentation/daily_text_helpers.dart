// daily_text_helpers.dart — Shared localized text helpers for the daily view.

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extension.dart';

/// Returns a localized string describing when the next event is due.
///
/// Mirrors DailyViewEntry.surfacingReason but uses l10n strings so the
/// UI always displays in the user's chosen language.
String localizedSurfacingReason(BuildContext context, int? days) {
  final l = context.l10n;
  if (days == null) return l.surfacingNoEvent;
  if (days < -1) return l.surfacingOverdueByDays(-days);
  if (days == -1) return l.surfacingOverdueByOneDay;
  if (days == 0) return l.surfacingDueToday;
  if (days == 1) return l.surfacingDueTomorrow;
  return l.surfacingDueInDays(days);
}
