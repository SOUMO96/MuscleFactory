import 'package:flutter/material.dart';

/// Holds the user's theme preference (light / dark / follow system) so the
/// whole app can react to it. A real per-user setting lands on the Me tab
/// in a later phase (backed by the `theme_preference` profile column) --
/// this controller is the plumbing that setting will call into.
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
}
