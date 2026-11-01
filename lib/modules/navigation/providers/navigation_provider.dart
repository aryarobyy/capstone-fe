import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void navigateToDashboard() => setIndex(0);
  void navigateToHome() => setIndex(0);
  void navigateToMonitoring() => setIndex(0);
  void navigateToRiwayat() => setIndex(1);
  void navigateToHistory() => setIndex(1);
  void navigateToArea() => setIndex(2);
  void navigateToProfile() => setIndex(3);
}
