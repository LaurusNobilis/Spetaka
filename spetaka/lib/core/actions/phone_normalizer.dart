import '../errors/app_error.dart';

/// Single source of truth for phone-number normalization.
///
/// All phone numbers flowing through the app MUST pass through this class.
/// No feature code may perform its own formatting or parsing.
///
/// ### Supported inputs (v1 — France scope)
/// | Input           | Output           |
/// |-----------------|------------------|
/// | `0612345678`    | `+33612345678`   |
/// | `+33612345678`  | `+33612345678`   |
///
/// Invalid inputs (letters, empty, ambiguous) throw [PhoneNormalizationAppError].
///
/// ### Multi-region note
/// True multi-region support must be introduced as a dedicated story with an
/// explicit phone-parsing dependency.  Silent heuristics are intentionally
/// avoided.
class PhoneNormalizer {
  const PhoneNormalizer();

  /// Normalizes [raw] to E.164 format (`+` followed by digits only).
  ///
  /// Strips common visual separators (spaces, dashes, dots, parentheses)
  /// before attempting normalization.
  ///
  /// Throws [PhoneNormalizationAppError] on invalid / unrecognizable input.
  String normalize(String raw) {
    // Strip common visual separators.
    final stripped = raw.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');

    if (stripped.isEmpty) {
      throw const PhoneNormalizationAppError('empty_input');
    }

    // Reject any character that is not a digit or a leading '+'.
    if (RegExp(r'[^+\d]').hasMatch(stripped)) {
      // Do not include the raw number (PII) in error details.
      throw const PhoneNormalizationAppError('invalid_characters');
    }

    // '+' is only valid as the very first character.
    if (stripped.contains('+') && !stripped.startsWith('+')) {
      throw const PhoneNormalizationAppError('misplaced_plus');
    }

    // Already E.164 — starts with '+' followed by digits only.
    if (stripped.startsWith('+')) {
      final digits = stripped.substring(1);
      if (digits.isEmpty || RegExp(r'\D').hasMatch(digits)) {
        throw const PhoneNormalizationAppError('invalid_e164_format');
      }
      return stripped;
    }

    // French local 10-digit format: 0X XXXXXXXX → +33 X XXXXXXXX
    if (stripped.startsWith('0') && stripped.length == 10) {
      return '+33${stripped.substring(1)}';
    }

    // Pure digits but unrecognisable format.
    // Do not include the raw number (PII) in error details.
    throw const PhoneNormalizationAppError('unrecognized_format');
  }
}
