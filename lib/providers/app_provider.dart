import 'package:flutter/foundation.dart';

class AppProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void updateIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  String get currentScreenName {
    switch (_currentIndex) {
      case 0: return 'HTML to PPT';
      case 1: return 'AI Chat';
      case 2: return 'Effects';
      default: return 'HTML to PPT';
    }
  }
}
