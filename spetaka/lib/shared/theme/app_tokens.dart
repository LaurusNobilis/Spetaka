import 'package:flutter/material.dart';

/// Central design token registry for Spetaka.
///
/// All palette, spacing, radius, typography, and motion values live here.
/// Never hard-code design values outside this file — reference these constants.
abstract final class AppTokens {
  // ── Palette · Light (Warm Cream) ──────────────────────────────────────────

  /// App background — like aged paper, never pure white.
  static const Color lightBackground = Color(0xFFFAF7F2);

  /// Friend cards and bottom sheets — subtle warm separation.
  static const Color lightSurface = Color(0xFFF5F1EC);

  /// Action buttons, active states — muted terracotta.
  static const Color lightPrimary = Color(0xFFC47B5A);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  /// Acquittement completion, success — dusty sage.
  static const Color lightSecondary = Color(0xFF7D9E8C);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);

  /// Primary text — deep warm charcoal, intimate and soft.
  static const Color lightOnBackground = Color(0xFF2C2620);
  static const Color lightOnSurface = Color(0xFF2C2620);

  /// Supporting text, timestamps — warm greige.
  static const Color lightTextSub = Color(0xFF8C7B70);

  /// Dividers, inactive elements — warm sand.
  static const Color lightOutline = Color(0xFFC4B8B0);

  // ── Palette · Dark (Warm Brown) ────────────────────────────────────────────
  // Dark mode preserves the warm identity — avoids cold grey fallback.

  /// Dark app background — deep warm brown, not cold grey.
  static const Color darkBackground = Color(0xFF1E1A17);

  /// Dark cards — warm dark surface.
  static const Color darkSurface = Color(0xFF2A2420);

  /// Terracotta brightened for dark-mode legibility.
  static const Color darkPrimary = Color(0xFFD4956E);
  static const Color darkOnPrimary = Color(0xFF2C1A0F);

  /// Sage brightened for dark-mode legibility.
  static const Color darkSecondary = Color(0xFF9DB8A7);
  static const Color darkOnSecondary = Color(0xFF0D2019);

  /// Warm cream text on dark surfaces.
  static const Color darkOnBackground = Color(0xFFF5F1EC);
  static const Color darkOnSurface = Color(0xFFF5F1EC);

  /// Muted sub-text on dark.
  static const Color darkTextSub = Color(0xFFB0A09A);

  /// Outlines on dark.
  static const Color darkOutline = Color(0xFF6A5E58);

  // ── Spacing ────────────────────────────────────────────────────────────────

  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;

  /// Minimum generous padding — 20dp+.
  static const double spaceLG = 20.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;

  // ── Radius ─────────────────────────────────────────────────────────────────

  static const double radiusSM = 8.0;

  /// Card corner radius — soft, generous, never sharp.
  static const double radiusCard = 14.0;
  static const double radiusLG = 20.0;

  static const BorderRadius cardBorderRadius =
      BorderRadius.all(Radius.circular(radiusCard));

  // ── Typography ─────────────────────────────────────────────────────────────

  /// Primary UI typeface — DM Sans.
  /// Warm, legible, slightly informal.
  static const String fontBody = 'DM Sans';

  /// Display / greeting typeface — Lora.
  /// Used for greeting line and display-scale headings.
  static const String fontDisplay = 'Lora';

  // ── Motion ─────────────────────────────────────────────────────────────────

  static const Duration motionShort = Duration(milliseconds: 150);

  /// Standard transition — 300ms, nothing jolts.
  static const Duration motionNormal = Duration(milliseconds: 300);
  static const Duration motionLong = Duration(milliseconds: 450);
  static const Curve motionCurve = Curves.easeInOutCubic;
}
