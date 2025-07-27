// lib/providers/auth_provider.dart - НОВЫЙ ПРОВАЙДЕР
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_api_service.dart';

class AuthProvider with ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();

  // Состояние аутентификации
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;

  // Геттеры
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;

  // Проверяем является ли пользователь администратором
  bool get isAdmin {
    if (_user == null) return false;

    // Для админа проверяем роль
    return _user!['role'] == 'admin';
  }

  // Инициализация - проверяем сохраненный токен
  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');

      if (savedToken != null) {
        _apiService.setAuthToken(savedToken);

        // Проверяем токен на сервере
        final response = await _apiService.checkAdminToken();
        if (response['success'] == true) {
          // Получаем данные профиля
          await _loadUserProfile();
        } else {
          // Токен недействителен, очищаем
          await _clearAuthData();
        }
      }
    } catch (e) {
      print('Ошибка инициализации авторизации: $e');
      await _clearAuthData();
    } finally {
      _setLoading(false);
    }
  }

  /// Простой вход по логину и паролю - РЕАЛЬНЫЙ API
  Future<bool> loginWithPassword(String login, String password) async {
    _clearError();
    _setLoading(true);

    try {
      final response = await _apiService.loginWithPassword(login, password);

      if (response['success'] == true && response['token'] != null) {
        // Сохраняем токен
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);

        // Устанавливаем токен в API сервисе
        _apiService.setAuthToken(response['token']);

        // Устанавливаем данные пользователя
        _user = response['user'];

        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _setError(response['error'] ?? 'Неверный логин или пароль');
        return false;
      }
    } catch (e) {
      _setError('Ошибка подключения к серверу: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Отправка SMS кода - оставляем для будущего
  Future<bool> sendSmsCode(String phone) async {
    _clearError();
    _setLoading(true);

    try {
      final response = await _apiService.sendSmsCode(phone);
      if (response['success'] == true) {
        return true;
      } else {
        _setError(response['error'] ?? 'Ошибка отправки SMS');
        return false;
      }
    } catch (e) {
      _setError('Ошибка отправки SMS: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Вход по SMS коду - оставляем для будущего
  Future<bool> loginWithSms(String phone, String code) async {
    _clearError();
    _setLoading(true);

    try {
      final response = await _apiService.loginWithSms(phone, code);

      if (response['success'] == true && response['token'] != null) {
        // Сохраняем токен
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);

        // Устанавливаем данные пользователя
        _user = response['user'];

        // Проверяем права администратора
        if (!isAdmin) {
          _setError('У вас нет прав администратора');
          await _clearAuthData();
          return false;
        }

        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _setError(response['error'] ?? 'Неверный код');
        return false;
      }
    } catch (e) {
      _setError('Ошибка входа: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Загрузка профиля администратора
  Future<void> _loadUserProfile() async {
    try {
      final response = await _apiService.getAdminProfile();
      if (response['success'] == true) {
        _user = response['user'];
        _isAuthenticated = true;
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      await _clearAuthData();
    }
  }

  /// Выход из системы
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _apiService.logout();
      await _clearAuthData();
    } catch (e) {
      print('Ошибка выхода: $e');
      await _clearAuthData();
    } finally {
      _setLoading(false);
    }
  }

  /// Очистка данных аутентификации
  Future<void> _clearAuthData() async {
    _isAuthenticated = false;
    _user = null;
    _apiService.clearAuthToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    notifyListeners();
  }

  /// Установка состояния загрузки
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Установка ошибки
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Очистка ошибки
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Проверка подключения к серверу
  Future<bool> checkServerConnection() async {
    try {
      await _apiService.checkHealth();
      return true;
    } catch (e) {
      return false;
    }
  }
}
