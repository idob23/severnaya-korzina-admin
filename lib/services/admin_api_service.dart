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
        if (response.body.length < 500) {
          print('AdminAPI Response Body: ${response.body}');
        }
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
    final response = await _makeRequest('POST', '/auth/admin-login', body: {
      'login': login,
      'password': password,
    });

    // Сохраняем токен если получили его
    if (response['token'] != null) {
      setAuthToken(response['token']);
    }

    return response;
  }

  /// Получить профиль администратора
  Future<Map<String, dynamic>> getAdminProfile() async {
    return await _makeRequest('GET', '/auth/admin-profile');
  }

  /// Проверить токен администратора
  Future<Map<String, dynamic>> checkAdminToken() async {
    return await _makeRequest('GET', '/auth/admin-check');
  }

  /// Выход из системы
  Future<void> logout() async {
    clearAuthToken();
  }
  // === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ПОЛЬЗОВАТЕЛЯМИ ===

  /// Получить список всех пользователей (для админа)
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    return await _makeRequest('GET', '/auth/admin-users');
  }

  /// Получить статистику для dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await _makeRequest('GET', '/auth/admin-stats');
  }

  // === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ЗАКАЗАМИ ===

  /// Получить список заказов (для админа)
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    return await _makeRequest('GET', '/admin/orders', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    });
  }

  /// Обновить статус заказа
  Future<Map<String, dynamic>> updateOrderStatus(
      int orderId, String status) async {
    return await _makeRequest('PUT', '/orders/$orderId/status', body: {
      'status': status,
    });
  }

  /// Получить список товаров
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    return await _makeRequest('GET', '/products', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null) 'search': search,
    });
  }

  /// Создать новый товар
  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> productData) async {
    return await _makeRequest('POST', '/admin/products', body: productData);
  }

  /// Обновить товар
  Future<Map<String, dynamic>> updateProduct(
      int productId, Map<String, dynamic> productData) async {
    return await _makeRequest('PUT', '/admin/products/$productId',
        body: productData);
  }

  /// Удалить товар
  Future<Map<String, dynamic>> deleteProduct(int productId) async {
    return await _makeRequest('DELETE', '/admin/products/$productId');
  }

  // Загрузить файл товаров от поставщика
  Future<Map<String, dynamic>> uploadProductFile(String filePath) async {
    // TODO: Реализовать загрузку файла
    // Пока возвращаем заглушку
    return {
      'success': true,
      'message': 'Файл загружен успешно',
      'data': {
        'fileName': filePath.split('/').last,
        'fileSize': '1.2 MB',
        'parsedItems': 0
      }
    };
  }

  // Получить список категорий (для сопоставления)
  Future<Map<String, dynamic>> getCategories() async {
    return await _makeRequest('GET', '/auth/admin-categories');
  }

  // === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ПАРТИЯМИ ===

  /// Получить список партий
  Future<Map<String, dynamic>> getBatches({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    return await _makeRequest('GET', '/admin/batches', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    });
  }

  /// Создать новую партию
  Future<Map<String, dynamic>> createBatch(
      Map<String, dynamic> batchData) async {
    return await _makeRequest('POST', '/admin/batches', body: batchData);
  }

  /// Обновить статус партии
  Future<Map<String, dynamic>> updateBatchStatus(
      int batchId, String status) async {
    return await _makeRequest('PUT', '/admin/batches/$batchId/status', body: {
      'status': status,
    });
  }

  /// Начать сбор денег (создать или активировать партию)
  Future<Map<String, dynamic>> startMoneyCollection({
    required double targetAmount,
    String title = 'Коллективная закупка',
  }) async {
    return await _makeRequest('POST', '/batches/start-collection', body: {
      'targetAmount': targetAmount,
      'title': title,
    });
  }

  /// Завершить сбор денег (перевести партию в готовность)
  Future<Map<String, dynamic>> stopMoneyCollection() async {
    return await _makeRequest('POST', '/batches/stop-collection');
  }

  /// Получить активную партию для информационной панели
  Future<Map<String, dynamic>> getActiveBatch() async {
    return await _makeRequest('GET', '/batches/active');
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
