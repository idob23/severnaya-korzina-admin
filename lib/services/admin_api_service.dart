// lib/services/admin_api_service.dart - ОБНОВЛЕННАЯ ВЕРСИЯ
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AdminApiService {
  // URL сервера - точно такой же как у вашего основного API
  static String get baseUrl {
    if (kDebugMode) {
      // Для разработки
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api';
      }
      return 'http://localhost:3000/api';
    }
    // Для продакшена
    return 'https://your-server.com/api';
  }

  // Singleton паттерн
  static final AdminApiService _instance = AdminApiService._internal();
  factory AdminApiService() => _instance;
  AdminApiService._internal();

  // HTTP клиент
  final http.Client _client = http.Client();
  String? _authToken;

  // Заголовки по умолчанию
  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Устанавливает токен авторизации
  void setAuthToken(String? token) {
    _authToken = token;
    if (kDebugMode) {
      print('AdminAPI: Токен установлен');
    }
  }

  /// Очищает токен авторизации
  void clearAuthToken() {
    _authToken = null;
    if (kDebugMode) {
      print('AdminAPI: Токен очищен');
    }
  }

  /// Универсальный метод для выполнения HTTP запросов
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      if (kDebugMode) {
        print('AdminAPI: $method $baseUrl$endpoint');
        if (body != null) print('AdminAPI Body: $body');
      }

      // Создаем URI с query параметрами
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      late http.Response response;

      // Выполняем запрос в зависимости от метода
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(uri, headers: _defaultHeaders)
              .timeout(Duration(seconds: 30));
          break;
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: _defaultHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(Duration(seconds: 30));
          break;
        case 'PUT':
          response = await _client
              .put(
                uri,
                headers: _defaultHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: _defaultHeaders)
              .timeout(Duration(seconds: 30));
          break;
        default:
          throw Exception('Неподдерживаемый HTTP метод: $method');
      }

      if (kDebugMode) {
        print('AdminAPI Response: ${response.statusCode}');
        print('AdminAPI Response Body: ${response.body}');
      }

      // Обрабатываем ответ
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Проверяем статус код
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: responseData['error'] ?? 'Неизвестная ошибка API',
          data: responseData,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('AdminAPI Error: $e');
      }
      rethrow;
    }
  }

  // === МЕТОДЫ АУТЕНТИФИКАЦИИ ===

  /// Простой вход по логину и паролю для админа
  Future<Map<String, dynamic>> loginWithPassword(
      String login, String password) async {
    return await _makeRequest('POST', '/auth/admin-login', body: {
      'login': login,
      'password': password,
    });
  }

  /// Получить профиль администратора
  Future<Map<String, dynamic>> getAdminProfile() async {
    return await _makeRequest('GET', '/auth/admin-profile');
  }

  /// Проверить токен администратора
  Future<Map<String, dynamic>> checkAdminToken() async {
    return await _makeRequest('GET', '/auth/admin-check');
  }

  /// Вход по номеру телефона (SMS код) - оставляем для будущего
  Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    return await _makeRequest('POST', '/auth/send-sms', body: {'phone': phone});
  }

  /// Вход по SMS коду - оставляем для будущего
  Future<Map<String, dynamic>> loginWithSms(String phone, String code) async {
    final response = await _makeRequest('POST', '/auth/verify-sms', body: {
      'phone': phone,
      'code': code,
    });

    // Сохраняем токен если получили его
    if (response['token'] != null) {
      setAuthToken(response['token']);
    }

    return response;
  }

  /// Получить профиль пользователя
  Future<Map<String, dynamic>> getProfile() async {
    return await _makeRequest('GET', '/auth/profile');
  }

  /// Проверить токен
  Future<Map<String, dynamic>> checkToken() async {
    return await _makeRequest('GET', '/auth/check');
  }

  /// Выход из системы
  Future<void> logout() async {
    clearAuthToken();
  }

  // === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ПОЛЬЗОВАТЕЛЯМИ ===

  /// Получить список всех пользователей
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    return await _makeRequest('GET', '/users', queryParams: queryParams);
  }

  /// Получить пользователя по ID
  Future<Map<String, dynamic>> getUser(String userId) async {
    return await _makeRequest('GET', '/users/$userId');
  }

  // === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ЗАКАЗАМИ ===

  /// Получить список заказов
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };

    return await _makeRequest('GET', '/orders', queryParams: queryParams);
  }

  // === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ТОВАРАМИ ===

  /// Получить список товаров
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    return await _makeRequest('GET', '/products', queryParams: queryParams);
  }

  // === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ПАРТИЯМИ ===

  /// Получить список партий
  Future<Map<String, dynamic>> getBatches({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };

    return await _makeRequest('GET', '/batches', queryParams: queryParams);
  }

  // === ПРОВЕРКА ЗДОРОВЬЯ СЕРВЕРА ===

  /// Проверить работоспособность сервера
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('${baseUrl.replaceAll('/api', '')}/health'))
          .timeout(Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Сервер недоступен: $e');
    }
  }

  /// Получить информацию об API
  Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final response =
          await _client.get(Uri.parse(baseUrl)).timeout(Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Не удалось получить информацию об API: $e');
    }
  }
}

/// Исключение для ошибок API
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }
}
