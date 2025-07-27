// lib/services/admin_api_service.dart - НОВЫЙ СЕРВИС ДЛЯ РАБОТЫ С СЕРВЕРОМ
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AdminApiService {
  // URL сервера - должен совпадать с основным API
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

  // HTTP клиент с настройками
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
        print('AdminAPI: Ответ - ${response.statusCode}');
      }

      // Обрабатываем ответ
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'success': true,
            ...data,
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Ошибка обработки ответа сервера',
          };
        }
      } else {
        // Обрабатываем ошибки сервера
        String errorMessage = 'Ошибка сервера (${response.statusCode})';

        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['error']?.toString() ?? errorMessage;
        } catch (e) {
          // Если не удалось распарсить ошибку, используем стандартное сообщение
        }

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('AdminAPI: Ошибка - $e');
      }
      return {
        'success': false,
        'error': 'Ошибка подключения к серверу: $e',
      };
    }
  }

  // === МЕТОДЫ ДЛЯ АВТОРИЗАЦИИ АДМИНА ===

  /// Авторизация администратора
  Future<Map<String, dynamic>> adminLogin({
    required String phone,
    required String smsCode,
  }) async {
    final result = await _makeRequest('POST', '/auth/login', body: {
      'phone': phone,
      'smsCode': smsCode,
    });

    if (result['success'] && result['token'] != null) {
      setAuthToken(result['token']);
    }

    return result;
  }

  /// Проверка прав администратора
  Future<Map<String, dynamic>> checkAdminRights() async {
    return await _makeRequest('GET', '/auth/profile');
  }

  // === МЕТОДЫ ДЛЯ ПОЛЬЗОВАТЕЛЕЙ ===

  /// Получить всех пользователей
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    return await _makeRequest('GET', '/users', queryParams: queryParams);
  }

  /// Получить пользователя по ID
  Future<Map<String, dynamic>> getUser(int userId) async {
    return await _makeRequest('GET', '/users/$userId');
  }

  /// Обновить пользователя
  Future<Map<String, dynamic>> updateUser(
      int userId, Map<String, dynamic> userData) async {
    return await _makeRequest('PUT', '/users/$userId', body: userData);
  }

  /// Заблокировать/разблокировать пользователя
  Future<Map<String, dynamic>> toggleUserStatus(
      int userId, bool isActive) async {
    return await _makeRequest('PUT', '/users/$userId/status', body: {
      'isActive': isActive,
    });
  }

  // === МЕТОДЫ ДЛЯ ТОВАРОВ ===

  /// Получить все товары
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 50,
    String? search,
    int? categoryId,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (categoryId != null) {
      queryParams['categoryId'] = categoryId.toString();
    }

    return await _makeRequest('GET', '/products', queryParams: queryParams);
  }

  /// Создать товар
  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> productData) async {
    return await _makeRequest('POST', '/products', body: productData);
  }

  /// Обновить товар
  Future<Map<String, dynamic>> updateProduct(
      int productId, Map<String, dynamic> productData) async {
    return await _makeRequest('PUT', '/products/$productId', body: productData);
  }

  /// Удалить товар
  Future<Map<String, dynamic>> deleteProduct(int productId) async {
    return await _makeRequest('DELETE', '/products/$productId');
  }

  // === МЕТОДЫ ДЛЯ КАТЕГОРИЙ ===

  /// Получить все категории
  Future<Map<String, dynamic>> getCategories() async {
    return await _makeRequest('GET', '/products/categories/all');
  }

  /// Создать категорию
  Future<Map<String, dynamic>> createCategory(
      Map<String, dynamic> categoryData) async {
    return await _makeRequest('POST', '/categories', body: categoryData);
  }

  /// Обновить категорию
  Future<Map<String, dynamic>> updateCategory(
      int categoryId, Map<String, dynamic> categoryData) async {
    return await _makeRequest('PUT', '/categories/$categoryId',
        body: categoryData);
  }

  /// Удалить категорию
  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    return await _makeRequest('DELETE', '/categories/$categoryId');
  }

  // === МЕТОДЫ ДЛЯ ЗАКАЗОВ ===

  /// Получить все заказы
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 50,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    return await _makeRequest('GET', '/orders', queryParams: queryParams);
  }

  /// Получить заказ по ID
  Future<Map<String, dynamic>> getOrder(int orderId) async {
    return await _makeRequest('GET', '/orders/$orderId');
  }

  /// Обновить статус заказа
  Future<Map<String, dynamic>> updateOrderStatus(
      int orderId, String status) async {
    return await _makeRequest('PUT', '/orders/$orderId/status', body: {
      'status': status,
    });
  }

  // === МЕТОДЫ ДЛЯ ЗАКУПОК ===

  /// Получить все закупки
  Future<Map<String, dynamic>> getBatches({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    return await _makeRequest('GET', '/batches', queryParams: queryParams);
  }

  /// Создать закупку
  Future<Map<String, dynamic>> createBatch(
      Map<String, dynamic> batchData) async {
    return await _makeRequest('POST', '/batches', body: batchData);
  }

  /// Обновить закупку
  Future<Map<String, dynamic>> updateBatch(
      int batchId, Map<String, dynamic> batchData) async {
    return await _makeRequest('PUT', '/batches/$batchId', body: batchData);
  }

  /// Обновить статус закупки
  Future<Map<String, dynamic>> updateBatchStatus(
      int batchId, String status) async {
    return await _makeRequest('PUT', '/batches/$batchId/status', body: {
      'status': status,
    });
  }

  // === МЕТОДЫ ДЛЯ АНАЛИТИКИ ===

  /// Получить статистику дашборда
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await _makeRequest('GET', '/admin/dashboard/stats');
  }

  /// Получить данные для графиков
  Future<Map<String, dynamic>> getAnalyticsData({
    String period = 'month',
    String type = 'orders',
  }) async {
    return await _makeRequest('GET', '/admin/analytics', queryParams: {
      'period': period,
      'type': type,
    });
  }

  // === ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

  /// Проверка здоровья сервера
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final uri = Uri.parse('${baseUrl.replaceAll('/api', '')}/health');
      final response = await _client.get(uri).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Сервер работает',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Сервер недоступен (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Не удалось подключиться к серверу: $e',
      };
    }
  }

  /// Закрытие клиента
  void dispose() {
    _client.close();
  }
}
