import 'package:flutter/material.dart';

/// Holds the theme preference (light / dark / follow system) so the whole app
/// can react to changes. The per-user setting lives in Profile -> Appearance.
class AppThemeController extends ChangeNotifier {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// The brightness [mode] currently resolves to. Used by main.dart and by
  /// MainShell, which keys its content on it to rebuild on theme change.
  Brightness get resolvedBrightness => switch (_mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
      };
}
