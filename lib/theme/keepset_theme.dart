import 'package:flutter/material.dart';

import 'keepset_colors.dart';

enum KeepsetThemeMode {
  system,
  light,
  dark,
}

class KeepsetThemeResolver {
  static KeepsetThemeMode _mode = KeepsetThemeMode.system;

  /// Call this when DB value changes
  static void setMode(KeepsetThemeMode mode, Brightness systemBrightness) {
    _mode = mode;
    _apply(systemBrightness);
  }

  /// Call this when system theme changes
  static void onSystemBrightnessChanged(Brightness brightness) {
    if (_mode == KeepsetThemeMode.system) {
      _apply(brightness);
    }
  }

  static void _apply(Brightness systemBrightness) {
    final effective = _mode == KeepsetThemeMode.system
        ? systemBrightness
        : _mode.toBrightness();

    if (effective == Brightness.dark) {
      KeepsetColors.applyDark();
    } else {
      KeepsetColors.applyLight();
    }
  }
}

@immutable
class KeepsetTheme {
  final Color background;
  final Color card;
  final Color cardSoft;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color error;

  const KeepsetTheme(
      {required this.background,
      required this.card,
      required this.cardSoft,
      required this.textPrimary,
      required this.textSecondary,
      required this.textMuted,
      required this.error});

  static KeepsetTheme of(BuildContext context) {
    return KeepsetTheme(
      background: KeepsetColors.base,
      card: KeepsetColors.layer1,
      cardSoft: KeepsetColors.layer2,
      textPrimary: KeepsetColors.textPrimary,
      textSecondary: KeepsetColors.textSecondary,
      textMuted: KeepsetColors.textMuted,
      error: KeepsetColors.error,
    );
  }
}

extension _ThemeModeX on KeepsetThemeMode {
  Brightness toBrightness() {
    switch (this) {
      case KeepsetThemeMode.dark:
        return Brightness.dark;
      case KeepsetThemeMode.light:
        return Brightness.light;
      case KeepsetThemeMode.system:
        throw StateError('system should be resolved externally');
    }
  }
}
