// providers/users_provider.dart
import 'package:flutter/material.dart';
import 'package:severnaya_korzina_admin/models/user.dart';
import 'package:severnaya_korzina_admin/services/data_service.dart';

class UsersProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  List<AdminUser> _users = [];
  bool _isLoading = false;
  String? _error;

  List<AdminUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _dataService.getUsers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUser(AdminUser user) async {
    try {
      await _dataService.saveUser(user);
      _users.add(user);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUser(AdminUser user) async {
    try {
      await _dataService.updateUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _dataService.deleteUser(userId);
      _users.removeWhere((user) => user.id == userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleUserStatus(String userId) async {
    final user = _users.firstWhere((u) => u.id == userId);
    final updatedUser = AdminUser(
      id: user.id,
      phone: user.phone,
      name: user.name,
      lastName: user.lastName,
      isActive: !user.isActive,
      isVerified: user.isVerified,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
      totalOrders: user.totalOrders,
      totalSpent: user.totalSpent,
    );
    await updateUser(updatedUser);
  }

  List<AdminUser> searchUsers(String query) {
    if (query.isEmpty) return _users;

    return _users.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.phone.contains(query) ||
          (user.lastName?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  Map<String, int> getUsersStats() {
    return {
      'total': _users.length,
      'active': _users.where((u) => u.isActive).length,
      'verified': _users.where((u) => u.isVerified).length,
      'new_today': _users
          .where((u) =>
              u.createdAt.isAfter(DateTime.now().subtract(Duration(days: 1))))
          .length,
    };
  }
}
