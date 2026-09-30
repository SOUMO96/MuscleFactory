import 'package:flutter/foundation.dart';

/// Lets any screen request MainShell switch its selected bottom tab --
/// needed because tabs like Train have no AppBar/back button of their
/// own (they rely on being embedded in MainShell's bottom nav), so
/// pushing them as a standalone route would strand the user with no way
/// to navigate elsewhere.
class MainTabController extends ChangeNotifier {
  MainTabController._();
  static final MainTabController instance = MainTabController._();

  int _requestedIndex = 0;
  int get requestedIndex => _requestedIndex;

  void goToTab(int index) {
    _requestedIndex = index;
    notifyListeners();
  }
}
