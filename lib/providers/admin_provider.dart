import 'package:flutter/material.dart';

class AdminProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentAdminId;
  String? _currentAdminName;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentAdminId => _currentAdminId;
  String? get currentAdminName => _currentAdminName;

  Future<bool> login(String username, String password) async {
    // Простая проверка для демо
    if (username == 'admin' && password == 'admin123') {
      _isAuthenticated = true;
      _currentAdminId = 'admin-001';
      _currentAdminName = 'Администратор';
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    _currentAdminId = null;
    _currentAdminName = null;
    notifyListeners();
  }
}
