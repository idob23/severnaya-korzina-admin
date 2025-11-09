// lib/services/category_mapping_service.dart
// Сервис для работы с маппингом категорий поставщика

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CategoryMappingService {
  static const String baseUrl =
      'http://84.201.149.245:3000'; // Замените на ваш URL

  /// Загрузить все маппинги из API
  /// Возвращает Map<String, int> где ключ - категория поставщика, значение - ID целевой категории
  static Future<Map<String, int>> loadMappings({String? authToken}) async {
    try {
      if (kDebugMode) {
        print('📥 Загрузка маппингов категорий...');
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/category-mappings'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final mappings = data['mappings'] as List;

        final result = <String, int>{};
        for (var mapping in mappings) {
          final supplierCat = mapping['supplierCategory'] as String;
          final targetId = mapping['targetCategoryId'] as int;
          result[supplierCat] = targetId;
        }

        if (kDebugMode) {
          print('✅ Загружено ${result.length} маппингов');
        }

        return result;
      } else {
        throw Exception('Ошибка загрузки маппингов: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Ошибка загрузки маппингов: $e');
      }
      // Возвращаем пустой Map в случае ошибки
      return {};
    }
  }

  /// Найти ID целевой категории для товара
  /// Сначала пытается найти точное совпадение, потом ищет по части пути
  static int? findCategoryId(
    String? supplierCategory,
    Map<String, int> mappings,
  ) {
    if (supplierCategory == null || supplierCategory.isEmpty) {
      return null;
    }
    print('🔍 Ищем маппинг для: "$supplierCategory"');

    // 1. Точное совпадение
    if (mappings.containsKey(supplierCategory)) {
      return mappings[supplierCategory];
    }

    // 2. Поиск по началу строки (для подкатегорий)
    // Например: если есть маппинг для "МОРОЖЕНОЕ ТМ СЕЛО ЗЕЛЕНОЕ"
    // и товар из "МОРОЖЕНОЕ ТМ СЕЛО ЗЕЛЕНОЕ/Стаканчик"
    for (var entry in mappings.entries) {
      if (supplierCategory.startsWith(entry.key)) {
        if (kDebugMode) {
          print(
            '   🔍 Найден маппинг по префиксу: "${entry.key}" → ${entry.value}',
          );
        }
        return entry.value;
      }
    }

    // 3. Поиск по части пути (разбиваем по "/")
    if (supplierCategory.contains('/')) {
      final parts = supplierCategory.split('/');
      for (var i = parts.length - 1; i >= 0; i--) {
        final partialPath = parts.sublist(0, i + 1).join('/');
        if (mappings.containsKey(partialPath)) {
          if (kDebugMode) {
            print(
              '   🔍 Найден маппинг по частичному пути: "$partialPath" → ${mappings[partialPath]}',
            );
          }
          return mappings[partialPath];
        }
      }
    }

    // Не найдено
    return null;
  }

  /// Статистика по маппингам
  static Future<Map<String, dynamic>> getStats({String? authToken}) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/category-mappings/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка получения статистики: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Ошибка получения статистики: $e');
      }
      rethrow;
    }
  }

  /// Создать новый маппинг
  static Future<bool> createMapping({
    required String supplierCategory,
    required int targetCategoryId,
    String confidence = 'manual',
    String? authToken,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final body = json.encode({
        'supplierCategory': supplierCategory,
        'targetCategoryId': targetCategoryId,
        'confidence': confidence,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/category-mappings'),
        headers: headers,
        body: body,
      );

      return response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Ошибка создания маппинга: $e');
      }
      return false;
    }
  }

  /// Обновить существующий маппинг
  static Future<bool> updateMapping({
    required int id,
    required int targetCategoryId,
    String? confidence,
    String? authToken,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final body = json.encode({
        'targetCategoryId': targetCategoryId,
        if (confidence != null) 'confidence': confidence,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/category-mappings/$id'),
        headers: headers,
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Ошибка обновления маппинга: $e');
      }
      return false;
    }
  }

  /// Удалить маппинг
  static Future<bool> deleteMapping({
    required int id,
    String? authToken,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/category-mappings/$id'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Ошибка удаления маппинга: $e');
      }
      return false;
    }
  }
}
