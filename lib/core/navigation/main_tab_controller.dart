import 'package:flutter/foundation.dart';

/// Lets any screen ask MainShell to switch tabs. Tabs like Train have no back
/// button, so pushing them as standalone routes would strand the user.
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
