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
              .timeout(Duration(seconds: 300));
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
              .delete(
                uri,
                headers: _defaultHeaders,
                body:
                    body != null ? jsonEncode(body) : null, // ✅ Добавляем body
              )
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
      // Исправляем путь с /auth/admin-users/$userId на /admin/users/$userId
      final result = await _makeRequest('DELETE', '/admin/users/$userId');
      print('AdminAPI: Пользователь $userId удален');
      return result;
    } catch (e) {
      print('AdminAPI: Ошибка удаления пользователя: $e');
      rethrow;
    }
  }

  /// Деактивировать пользователя (безопасная альтернатива удалению)
  Future<Map<String, dynamic>> deactivateUser(int userId) async {
    print('AdminAPI: Деактивация пользователя $userId');
    try {
      final result =
          await _makeRequest('PUT', '/admin/users/$userId/deactivate');
      print('AdminAPI: Пользователь $userId деактивирован');
      return result;
    } catch (e) {
      print('AdminAPI: Ошибка деактивации пользователя: $e');
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

  /// Удалить ВСЕ товары из БД (жёсткое удаление)
  Future<Map<String, dynamic>> deleteAllProducts() async {
    return await _makeRequest('DELETE', '/admin/products/delete-all');
  }

  // === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ РЕЖИМОМ ОБСЛУЖИВАНИЯ ===

  /// Получить статус режима обслуживания
  Future<Map<String, dynamic>> getMaintenanceStatus() async {
    return await _makeRequest('GET', '/admin/maintenance');
  }

  /// Обновить режим обслуживания
  Future<Map<String, dynamic>> updateMaintenanceMode({
    required bool enabled,
    required String message,
    String? endTime,
    List<String>? allowedPhones,
  }) async {
    return await _makeRequest('PUT', '/admin/maintenance', body: {
      'enabled': enabled,
      'message': message,
      'end_time': endTime ?? '',
      'allowed_phones': allowedPhones ?? [],
    });
  }

  /// Добавить телефон в белый список
  Future<Map<String, dynamic>> addAllowedPhone(String phone) async {
    return await _makeRequest('POST', '/admin/maintenance/allow-phone', body: {
      'phone': phone,
    });
  }

  /// Удалить телефон из белого списка
  Future<Map<String, dynamic>> removeAllowedPhone(String phone) async {
    return await _makeRequest(
      'DELETE',
      '/admin/maintenance/allow-phone/${Uri.encodeComponent(phone)}',
    );
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

  /// Удалить категорию
  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    return await _makeRequest('DELETE', '/auth/admin-categories/$categoryId');
  }

  /// Удалить все пустые категории
  Future<Map<String, dynamic>> deleteAllEmptyCategories() async {
    return await _makeRequest('DELETE', '/auth/admin-categories');
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

  /// Получить общий заказ по партии
  Future<Map<String, dynamic>> getTotalOrder(int batchId) async {
    print('AdminAPI: Получение общего заказа для партии $batchId');
    try {
      final result =
          await _makeRequest('GET', '/admin/batches/$batchId/total-order');
      print('AdminAPI: Общий заказ получен');
      return result;
    } catch (e) {
      print('AdminAPI: Ошибка получения общего заказа: $e');
      rethrow;
    }
  }

  /// Получить заказы сгруппированные по пользователям
  Future<Map<String, dynamic>> getOrdersByUsers(int batchId) async {
    print('AdminAPI: Получение заказов по пользователям для партии $batchId');
    try {
      final result =
          await _makeRequest('GET', '/admin/batches/$batchId/orders-by-users');
      print('AdminAPI: Заказы по пользователям получены');
      return result;
    } catch (e) {
      print('AdminAPI: Ошибка получения заказов по пользователям: $e');
      rethrow;
    }
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

  /// Удалить заказ (для админа)
  Future<Map<String, dynamic>> deleteOrder(int orderId) async {
    return await _makeRequest('DELETE', '/admin/orders/$orderId');
  }

  /// Массовое удаление товаров
  Future<Map<String, dynamic>> bulkDeleteProducts(List<int> productIds) async {
    return await _makeRequest('DELETE', '/admin/products/bulk-delete', body: {
      'productIds': productIds,
    });
  }

  /// Получить все ID товаров (для массового удаления)
  Future<List<int>> getAllProductIds() async {
    final response = await getProducts(limit: 10000); // Получаем все товары
    final products = response['products'] as List<dynamic>;
    return products.map((p) => p['id'] as int).toList();
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

  /// Обновить токен
  Future<bool> refreshToken() async {
    try {
      final response = await _makeRequest('POST', '/auth/admin-refresh');
      if (response['success'] == true && response['token'] != null) {
        setAuthToken(response['token']);

        // Сохраняем новый токен
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', response['token']);

        print('🔄 Токен успешно обновлён');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Ошибка обновления токена: $e');
      return false;
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

  // Получение настроек системы
  Future<Map<String, dynamic>> getSystemSettings() async {
    final response = await _makeRequest('GET', '/admin/settings');
    return response;
  }

// Обновление настройки
  Future<Map<String, dynamic>> updateSystemSetting(
      String key, String value) async {
    final response = await _makeRequest(
      'PUT',
      '/admin/settings/$key',
      body: {'value': value},
    );
    return response;
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

  /// Загрузить картинку для категории
  Future<Map<String, dynamic>> uploadCategoryImage(
    int categoryId,
    File imageFile,
  ) async {
    try {
      if (_authToken == null) {
        final prefs = await SharedPreferences.getInstance();
        _authToken = prefs.getString('admin_token');

        if (_authToken == null) {
          throw Exception('Токен не найден');
        }
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/categories/$categoryId/image'),
      );

      request.headers['Authorization'] = 'Bearer $_authToken';

      // Добавляем файл
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка загрузки картинки: $e');
      throw Exception('Не удалось загрузить картинку: $e');
    }
  }

  /// Удалить картинку категории
  Future<Map<String, dynamic>> deleteCategoryImage(int categoryId) async {
    return await _makeRequest('DELETE', '/categories/$categoryId/image');
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
