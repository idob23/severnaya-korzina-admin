// lib/services/admin_api_service.dart - ОБНОВЛЕННАЯ ВЕРСИЯ
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminApiService {
  // URL сервера - точно такой же как у вашего основного API
  static String get baseUrl {
    // Всегда используем внешний сервер, так как локального нет
    return 'http://84.201.149.245:3000/api';
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

  /// Удалить пользователя
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    print('AdminAPI: Удаление пользователя $userId');
    try {
      final result = await _makeRequest('DELETE', '/auth/admin-users/$userId');
      print('AdminAPI: Пользователь $userId удален');
      return result;
    } catch (e) {
      print('AdminAPI: Ошибка удаления пользователя: $e');
      rethrow;
    }
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
    return await _makeRequest('GET', '/auth/admin-orders', queryParams: {
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
    return await _makeRequest('GET', '/auth/admin-products', queryParams: {
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

  /// Обновить название закупки
  Future<Map<String, dynamic>> updateBatchTitle(
      int batchId, String newTitle) async {
    return await _makeRequest('PUT', '/batches/$batchId/title', body: {
      'title': newTitle,
    });
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

  /// Создать новую категорию
  Future<Map<String, dynamic>> createCategory(String name,
      {String? description}) async {
    return await _makeRequest('POST', '/auth/admin-categories', body: {
      'name': name,
      if (description != null) 'description': description,
    });
  }

  // === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ПАРТИЯМИ ===

  /// Получить список партий
  Future<Map<String, dynamic>> getBatches({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    return await _makeRequest('GET', '/auth/admin-batches', queryParams: {
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

  /// Удалить партию
  Future<Map<String, dynamic>> deleteBatch(int batchId) async {
    print('AdminAPI: Удаление партии $batchId');
    try {
      // Исправляем путь с /batches/$batchId на /admin/batches/$batchId
      final result = await _makeRequest('DELETE', '/admin/batches/$batchId');
      print('AdminAPI: Партия $batchId удалена');
      return result;
    } catch (e) {
      print('AdminAPI: Ошибка удаления партии: $e');
      rethrow;
    }
  }

  /// Отправить заказы (Машина уехала) - перевести paid → shipped
  Future<Map<String, dynamic>> shipOrders(int batchId) async {
    return await _makeRequest('POST', '/admin/batches/$batchId/ship-orders');
  }

  /// Доставить заказы (Машина приехала) - перевести shipped → delivered
  Future<Map<String, dynamic>> deliverOrders(int batchId) async {
    return await _makeRequest('POST', '/admin/batches/$batchId/deliver-orders');
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
    print('AdminAPI: Запрос активной партии...');
    try {
      final result = await _makeRequest('GET', '/batches/active');
      print('AdminAPI: Ответ активной партии: $result');
      return result;
    } catch (e) {
      print('AdminAPI: Ошибка получения активной партии: $e');
      // Возвращаем пустой результат вместо ошибки
      return {'success': true, 'batch': null, 'message': 'Нет активных партий'};
    }
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

  /// Парсинг файла с товарами
  Future<Map<String, dynamic>> parseProductFile(String filePath) async {
    try {
      // Используем существующий токен из класса
      if (_authToken == null) {
        // Пробуем получить из SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        _authToken = prefs.getString('admin_token');

        if (_authToken == null) {
          throw Exception('Токен авторизации не найден');
        }
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/products/parse'),
      );

      request.headers['Authorization'] = 'Bearer $_authToken';

      // Добавляем файл
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType('text', 'csv'), // Определим тип автоматически
        ),
      );
      print('Отправляем файл на сервер: $filePath');
      print('URL: $baseUrl/admin/products/parse');
      print('Токен есть: ${_authToken != null}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Ответ сервера: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Ошибка парсинга файла');
      }
    } catch (e) {
      print('Ошибка в parseProductFile: $e');
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  /// Массовое создание товаров
  Future<Map<String, dynamic>> bulkCreateProducts(
      List<Map<String, dynamic>> products) async {
    return await _makeRequest('POST', '/admin/products/bulk', body: {
      'products': products,
    });
  }

  /// Получить существующие товары для сравнения
  Future<Map<String, dynamic>> getExistingProducts({
    String? search,
    int? categoryId,
  }) async {
    return await _makeRequest('GET', '/auth/admin-products', queryParams: {
      if (search != null) 'search': search,
      if (categoryId != null) 'categoryId': categoryId.toString(),
    });
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

  /// Получить статус оформления заказов
  Future<Map<String, dynamic>> getCheckoutEnabled() async {
    try {
      print('AdminAPI: Получение статуса checkout...');

      final result = await _makeRequest('GET', '/settings/checkout-enabled');

      print('AdminAPI: Статус checkout получен: ${result['checkoutEnabled']}');
      return result;
    } catch (e) {
      print('AdminAPI: Ошибка получения статуса checkout: $e');
      // При ошибке возвращаем значение по умолчанию
      return {
        'success': false,
        'checkoutEnabled': true, // По умолчанию разрешаем
        'error': e.toString(),
      };
    }
  }

  /// Изменить статус оформления заказов
  Future<Map<String, dynamic>> setCheckoutEnabled(bool enabled) async {
    try {
      print('AdminAPI: Изменение статуса checkout на $enabled...');

      final result = await _makeRequest(
        'PUT',
        '/settings/checkout-enabled',
        body: {
          'enabled': enabled,
        },
      );

      print('AdminAPI: Статус checkout изменен успешно');
      return result;
    } catch (e) {
      print('AdminAPI: Ошибка изменения статуса checkout: $e');

      // Если это ApiException, пробрасываем её дальше
      if (e is ApiException) {
        throw Exception(e.message);
      }

      // Для других ошибок
      throw Exception('Не удалось изменить настройку: $e');
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
