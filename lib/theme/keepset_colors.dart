import 'package:flutter/material.dart';

enum _KeepsetColorMode { light, dark }

class KeepsetColors {
  // ─────────────────────────────────────────
  // INTERNAL STATE (DO NOT USE OUTSIDE)
  // ─────────────────────────────────────────
  static _KeepsetColorMode _mode = _KeepsetColorMode.dark;

  static void _setMode(_KeepsetColorMode mode) {
    _mode = mode;
  }

  // Exposed later (Step 2)
  static void applyLight() => _setMode(_KeepsetColorMode.light);
  static void applyDark() => _setMode(_KeepsetColorMode.dark);

  // ─────────────────────────────────────────
  // DARK PALETTE (DEFAULT)
  // ─────────────────────────────────────────
  static const _darkBase = Color(0xFF2F3E46);
  static const _darkLayer1 = Color(0xFF263238);
  static const _darkLayer2 = Color(0xFF52796F);
  static const _darkLayer3 = Color(0xFF84A98C);

  static const _darkTextPrimary = Color(0xFFCAD2C5);
  static const _darkTextSecondary = Color(0xFF84A98C);
  static const _darkTextMuted = Color(0x8BCAD2C5);

  static const _darkDivider = Color(0x3352796F);
  static const _darkError = Color(0xFFC27D8A);

  // ─────────────────────────────────────────
  // LIGHT PALETTE
  // ─────────────────────────────────────────
  static const _lightBase = Color(0xFFF1F5F3);
  static const _lightLayer1 = Color(0xFFE3ECE7);
  static const _lightLayer2 = Color(0xFFCFE3DA);
  static const _lightLayer3 = Color(0xFF52796F);

  static const _lightTextPrimary = Color(0xFF1F2D2A);
  static const _lightTextSecondary = Color(0xFF52796F);
  static const _lightTextMuted = Color(0x8B1F2D2A);

  static const _lightDivider = Color(0x3352796F);
  static const _lightError = Color(0xFFC27D8A);

  // ─────────────────────────────────────────
  // PUBLIC API (UNCHANGED)
  // ─────────────────────────────────────────

  static Color get base =>
      _mode == _KeepsetColorMode.dark ? _darkBase : _lightBase;

  static Color get layer1 =>
      _mode == _KeepsetColorMode.dark ? _darkLayer1 : _lightLayer1;

  static Color get layer2 =>
      _mode == _KeepsetColorMode.dark ? _darkLayer2 : _lightLayer2;

  static Color get layer3 =>
      _mode == _KeepsetColorMode.dark ? _darkLayer3 : _lightLayer3;

  static Color get textPrimary =>
      _mode == _KeepsetColorMode.dark ? _darkTextPrimary : _lightTextPrimary;

  static Color get textSecondary => _mode == _KeepsetColorMode.dark
      ? _darkTextSecondary
      : _lightTextSecondary;

  static Color get textMuted =>
      _mode == _KeepsetColorMode.dark ? _darkTextMuted : _lightTextMuted;

  static Color get divider =>
      _mode == _KeepsetColorMode.dark ? _darkDivider : _lightDivider;

  static Color get error =>
      _mode == _KeepsetColorMode.dark ? _darkError : _lightError;

  KeepsetColors.applyMode(
    ThemeMode mode,
    Brightness systemBrightness,
  );
}
