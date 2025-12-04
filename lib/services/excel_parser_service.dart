// lib/services/excel_parser_service.dart
// Умный парсер Excel файлов для прайс-листов
// ИСПОЛЬЗУЕМ spreadsheet_decoder вместо excel

import 'dart:io';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class ExcelParserService {
  /// Парсит Excel файл и возвращает список товаров
  static Future<Map<String, dynamic>> parseExcelFile(String filePath) async {
    try {
      print('📊 Начинаем парсинг Excel файла: $filePath');

      // Проверяем существование файла
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('Файл не найден: $filePath');
      }

      print('   Размер файла: ${file.lengthSync()} байт');

      // Читаем файл
      final bytes = file.readAsBytesSync();
      print('   Файл прочитан: ${bytes.length} байт');

      // Декодируем Excel
      SpreadsheetDecoder? decoder;
      try {
        print('   Декодирование Excel...');
        decoder = SpreadsheetDecoder.decodeBytes(bytes);
        print('   ✅ Excel декодирован успешно');
      } catch (e) {
        print('   ❌ Ошибка декодирования: $e');
        throw Exception('Не удалось прочитать Excel файл: $e');
      }

      if (decoder == null) {
        throw Exception('Не удалось декодировать Excel файл');
      }

      print('   Найдено листов: ${decoder.tables.keys.length}');
      print('   Названия листов: ${decoder.tables.keys.join(", ")}');

      final products = <Map<String, dynamic>>[];
      final categories = <Map<String, dynamic>>[];

      // Обрабатываем каждый лист
      for (var tableName in decoder.tables.keys) {
        print('\n🔍 Обработка листа: "$tableName"');

        final table = decoder.tables[tableName];
        if (table == null) {
          print('   ⚠️ Лист пустой, пропускаем');
          continue;
        }

        print('   Строк в листе: ${table.rows.length}');
        if (table.rows.isEmpty) {
          print('   ⚠️ Нет данных в листе');
          continue;
        }

        print('   Колонок в первой строке: ${table.rows[0].length}');

        try {
          final sheetResult = _parseSheet(table, tableName);

          final sheetProducts =
              sheetResult['products'] as List<Map<String, dynamic>>?;
          final sheetCategories =
              sheetResult['categories'] as List<Map<String, dynamic>>?;

          if (sheetProducts != null) {
            products.addAll(sheetProducts);
            print('   ✅ Извлечено товаров: ${sheetProducts.length}');
          }

          if (sheetCategories != null) {
            categories.addAll(sheetCategories);
            print('   ✅ Извлечено категорий: ${sheetCategories.length}');
          }
        } catch (e, stackTrace) {
          print('   ❌ Ошибка обработки листа "$tableName": $e');
          print('   Stack trace: $stackTrace');
        }
      }

      // Формируем итоговую статистику
      final uniqueCount = _getUniqueCategories(categories).length;

      print('\n✅ Парсинг завершён:');
      print('   Товаров: ${products.length}');
      print('   Уникальных категорий: $uniqueCount');

      final result = {
        'success': true,
        'products': products,
        'categories': categories,
        'summary': {
          'totalProducts': products.length,
          'totalCategories': categories.length,
          'uniqueCategories': uniqueCount,
        },
      };

      return result;
    } catch (e, stackTrace) {
      print('❌ Ошибка парсинга Excel: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'products': <Map<String, dynamic>>[],
        'categories': <Map<String, dynamic>>[],
      };
    }
  }

  /// Парсит один лист Excel
  static Map<String, dynamic> _parseSheet(
      SpreadsheetTable table, String sheetName) {
    final products = <Map<String, dynamic>>[];
    final categories = <Map<String, dynamic>>[];

    try {
      print('   📋 Анализ листа "$sheetName"...');
      final rowCount = table.rows.length;
      print('   Строк: $rowCount');

      if (rowCount == 0) {
        print('   ⚠️ Лист пустой');
        return {'products': products, 'categories': categories};
      }

      // Ищем строку с заголовками
      final headerRow = _findHeaderRow(table);

      if (headerRow == -1) {
        print('   ⚠️ Заголовки не найдены, пропускаем лист');
        return {'products': products, 'categories': categories};
      }

      print('   ✅ Заголовки найдены на строке: ${headerRow + 1}');

      // Определяем индексы колонок
      final columnMap = _mapColumns(table, headerRow);
      print('   📊 Колонки: $columnMap');

      String? currentCategory;
      String? currentSubcategory;
      int processedRows = 0;
      int skippedRows = 0;

      // Парсим данные начиная со строки после заголовков
      for (int i = headerRow + 1; i < rowCount; i++) {
        try {
          final row = table.rows[i];

          // Безопасное получение значений ячеек
          final code = _getCellValue(row, columnMap['code']);
          final name = _getCellValue(row, columnMap['name']);
          final unit = _getCellValue(row, columnMap['unit']);
          final priceStr = _getCellValue(row, columnMap['price']);
          final stock = _getCellValue(row, columnMap['stock']);
          final inPackage = _getCellValue(row, columnMap['inPackage']);
          final packagePrice = _getCellValue(row, columnMap['packagePrice']);

          // Пропускаем пустые строки
          if (code == null && name == null) {
            skippedRows++;
            continue;
          }

          // Парсим цену
          final price = _parsePrice(priceStr);

          // Если есть код/название, но НЕТ цены - это категория
          if ((code != null || name != null) && price == null) {
            final categoryName = name ?? code ?? '';

            // Определяем уровень вложенности по отступам
            if (categoryName.startsWith('    ')) {
              // Подкатегория (с отступами)
              currentSubcategory = categoryName.trim();
              categories.add({
                'name': currentSubcategory,
                'parent': currentCategory,
                'level': 2,
                'row': i + 1,
              });
            } else {
              // Основная категория
              currentCategory = categoryName.trim();
              currentSubcategory = null;
              categories.add({
                'name': currentCategory,
                'parent': null,
                'level': 1,
                'row': i + 1,
              });
            }
            processedRows++;
            continue;
          }

          // // Если есть цена - это товар
          // if (price != null && name != null && name.trim().isNotEmpty) {
          //   final product = {
          //     'name': name.trim(),
          //     'price': price,
          //     'unit': unit?.trim() ?? 'шт',
          //     'code': code?.trim(),
          //     'maxQuantity': _parseInt(stock),
          //     'inPackage': _parseInt(inPackage),
          //     'packagePrice': _parsePrice(packagePrice),
          //     'category': currentCategory,
          //     'subcategory': currentSubcategory,
          //     'row': i + 1,
          //     'isNew': true,
          //     'isDuplicate': false,
          //   };

          //   products.add(product);
          //   processedRows++;
          // } else {
          //   skippedRows++;
          // }
// 🎯 ИСПРАВЛЕНИЕ: Приоритет цене упаковки
// Если есть цена - это товар
          if (price != null && name != null && name.trim().isNotEmpty) {
            // Парсим данные упаковки
            final parsedInPackage = _parseInt(inPackage);
            final parsedPackagePrice = _parsePrice(packagePrice);

            // Используем цену упаковки, если она есть
            final finalPrice = parsedPackagePrice ?? price;

            // Формируем единицу измерения
            final finalUnit =
                parsedPackagePrice != null && parsedInPackage != null
                    ? 'уп ($parsedInPackage шт)'
                    : (unit?.trim() ?? 'шт');

            final product = {
              'name': name.trim(),
              'price': finalPrice,
              'unit': finalUnit,
              'basePrice': price, // ✅ ЭТА СТРОКА ЕСТЬ?
              'baseUnit': unit?.trim(), // ✅ ЭТА СТРОКА ЕСТЬ?
              'inPackage': parsedInPackage, // ✅ ЭТА СТРОКА ЕСТЬ?
              'code': code?.trim(),
              'maxQuantity': _parseInt(stock),
              'inPackage': parsedInPackage,
              'packagePrice': parsedPackagePrice,
              'category': currentCategory,
              'subcategory': currentSubcategory,
              'row': i + 1,
              'isNew': true,
              'isDuplicate': false,
            };

            products.add(product);
            processedRows++;
          } else {
            skippedRows++;
          }
        } catch (e) {
          print('   ⚠️ Ошибка обработки строки ${i + 1}: $e');
          skippedRows++;
        }
      }

      print('   ✅ Обработано строк: $processedRows');
      print('   ⚠️ Пропущено строк: $skippedRows');
      print('   📦 Товаров: ${products.length}');
      print('   🏷️ Категорий: ${categories.length}');
    } catch (e, stackTrace) {
      print('   ❌ Критическая ошибка парсинга листа: $e');
      print('   Stack trace: $stackTrace');
    }

    return {'products': products, 'categories': categories};
  }

  /// Ищет строку с заголовками таблицы
  static int _findHeaderRow(SpreadsheetTable table) {
    final headerKeywords = [
      'код',
      'code',
      'номенклатура',
      'название',
      'name',
      'товар',
      'цена',
      'price',
      'стоимость',
      'ед',
      'unit',
      'единица'
    ];

    final rowCount = table.rows.length;
    final searchLimit = rowCount < 50 ? rowCount : 50;

    for (int i = 0; i < searchLimit; i++) {
      try {
        final row = table.rows[i];
        int keywordsFound = 0;

        for (var cell in row) {
          if (cell == null) continue;

          final value = cell.toString().toLowerCase();
          if (value.isEmpty) continue;

          for (var keyword in headerKeywords) {
            if (value.contains(keyword)) {
              keywordsFound++;
              break;
            }
          }
        }

        // Если нашли хотя бы 3 ключевых слова - это заголовки
        if (keywordsFound >= 3) {
          return i;
        }
      } catch (e) {
        print('   ⚠️ Ошибка проверки строки $i на заголовки: $e');
        continue;
      }
    }

    return -1;
  }

  /// Определяет индексы колонок по заголовкам
  static Map<String, int?> _mapColumns(SpreadsheetTable table, int headerRow) {
    final columnMap = <String, int?>{
      'code': null,
      'name': null,
      'unit': null,
      'price': null,
      'stock': null,
      'inPackage': null,
      'packagePrice': null,
    };

    try {
      final row = table.rows[headerRow];

      // 🔍 ДОБАВЬ ЭТИ СТРОКИ:
      print('   🔍 ОТЛАДКА заголовков (строка $headerRow):');
      for (int i = 0; i < row.length && i < 13; i++) {
        final cell = row[i];
        if (cell != null && cell.toString().trim().isNotEmpty) {
          print('      Колонка[$i] = "${cell}"');
        }
      }
      print('   🔍 Конец отладки\n');
      // КОНЕЦ ДОБАВЛЕНИЯ

      for (int i = 0; i < row.length; i++) {
        final cell = row[i];
        if (cell == null) continue;

        final header = cell.toString().toLowerCase();
        if (header.isEmpty) continue;

        // // Код товара
        // if (header.contains('код') ||
        //     header.contains('code') ||
        //     header.contains('артикул')) {
        //   columnMap['code'] = i;
        // }

        // Код товара
        if ((header.contains('код') ||
                header.contains('code') ||
                header.contains('артикул')) &&
            !header.contains('штрих') &&
            !header.contains('barcode')) {
          columnMap['code'] = i;
        }
        // Название
        else if (header.contains('номенклатура') ||
            header.contains('название') ||
            header.contains('name') ||
            header.contains('товар') ||
            header.contains('наименование')) {
          columnMap['name'] = i;
        }
        // Единица измерения
        else if ((header.contains('ед') && !header.contains('цена')) ||
            header.contains('unit') ||
            header.contains('единица')) {
          columnMap['unit'] = i;
        }
        // Цена
        else if ((header.contains('цена') && !header.contains('уп')) ||
            (header.contains('price') && !header.contains('уп')) ||
            (header.contains('стоимость') && !header.contains('уп'))) {
          columnMap['price'] = i;
        }
        // Остаток
        else if (header.contains('остаток') ||
            header.contains('stock') ||
            header.contains('наличие')) {
          columnMap['stock'] = i;
        }
        // В упаковке
        else if (header.contains('в уп') ||
            header.contains('в упак') ||
            header.contains('упаковка')) {
          columnMap['inPackage'] = i;
        }
        // Цена упаковки
        else if (header.contains('цена уп') ||
            header.contains('стоимость уп')) {
          columnMap['packagePrice'] = i;
        }
      }
    } catch (e) {
      print('   ⚠️ Ошибка определения колонок: $e');
    }

    return columnMap;
  }

  /// Получает значение ячейки безопасно
  static String? _getCellValue(List<dynamic> row, int? columnIndex) {
    try {
      if (columnIndex == null || columnIndex >= row.length || columnIndex < 0) {
        return null;
      }

      final cell = row[columnIndex];
      if (cell == null) return null;

      final value = cell.toString().trim();
      return value.isEmpty ? null : value;
    } catch (e) {
      return null;
    }
  }

  /// Парсит цену из строки
  static double? _parsePrice(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      final cleaned = value.replaceAll(RegExp(r'[^\d.,]'), '');
      if (cleaned.isEmpty) return null;

      final normalized = cleaned.replaceAll(',', '.');
      return double.tryParse(normalized);
    } catch (e) {
      return null;
    }
  }

  /// Парсит целое число
  static int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
      if (cleaned.isEmpty) return null;

      return int.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Получает уникальные категории
  static List<String> _getUniqueCategories(
      List<Map<String, dynamic>> categories) {
    try {
      return categories
          .map((c) => c['name'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
    } catch (e) {
      return [];
    }
  }
}
