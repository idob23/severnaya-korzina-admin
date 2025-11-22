// lib/screens/add_product_screen.dart - ПОЛНЫЙ ФАЙЛ

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:severnaya_korzina_admin/services/excel_parser_service.dart';
import 'dart:io';
import 'dart:math';
import '../services/admin_api_service.dart';
import 'manage_categories_screen.dart';
import '../services/category_mapper_service.dart';
import '../services/category_mapping_service.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final AdminApiService _apiService = AdminApiService();

  // Состояние
  bool _isLoading = false;
  bool _isLoadingProducts = true;
  String? _error;

  // Данные
  PlatformFile? _selectedFile;
  List<Map<String, dynamic>> _parsedItems = [];
  Set<int> _selectedIndices = {}; // ✨ НОВОЕ: выбранные товары
  List<Map<String, dynamic>> _existingProducts = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, int> _categoryMappings = {}; // ← ДОБАВЬ ЭТУ СТРОКУ
  bool _useMappings = true; // ← И ЭТУ СТРОКУ
  int? _selectedCategoryFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _excelCategories = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadMappings();
  }

  // ← ДОБАВЬ ВЕСЬ ЭТОТ МЕТОД:
  Future<void> _loadMappings() async {
    try {
      print('📥 Загрузка маппингов категорий...');
      print('🌐 URL: ${CategoryMappingService.baseUrl}'); // ← ДОБАВЬ ЭТУ СТРОКУ
      final mappings = await CategoryMappingService.loadMappings();

      setState(() {
        _categoryMappings = mappings;
      });

      print('✅ Загружено ${mappings.length} маппингов');
      print(
          '📋 Первые 3 маппинга: ${mappings.entries.take(3).toList()}'); // ← И ЭТУ
    } catch (e) {
      print('⚠️ Ошибка загрузки маппингов: $e');
      print('⚠️ Stack trace: ${StackTrace.current}'); // ← И ЭТУ
    }
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
    await _loadExistingProducts();
  }

  Future<void> _manageCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManageCategoriesScreen()),
    );

    // Перезагружаем категории после возврата
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.getCategories();
      setState(() {
        _categories = List<Map<String, dynamic>>.from(
          response['categories'] ?? [],
        );
      });
      print('Категории загружены: ${_categories.length}');
    } catch (e) {
      print('Ошибка загрузки категорий: $e');
      // Используем дефолтные если не удалось загрузить
      setState(() {
        _categories = [
          {'id': 1, 'name': 'Молочные продукты'},
          {'id': 2, 'name': 'Мясо и птица'},
          {'id': 3, 'name': 'Овощи и фрукты'},
          {'id': 4, 'name': 'Хлебобулочные изделия'},
          {'id': 5, 'name': 'Напитки'},
          {'id': 6, 'name': 'Бакалея'},
        ];
      });
    }
  }

  Future<void> _loadExistingProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      // Используем существующий метод getProducts
      final response = await _apiService.getProducts();
      print('Товары загружены: ${response['products']?.length ?? 0}');

      setState(() {
        _existingProducts = List<Map<String, dynamic>>.from(
          response['products'] ?? [],
        ).where((p) => p['isActive'] == true).toList();
        _isLoadingProducts = false;
      });
    } catch (e) {
      print('Ошибка загрузки товаров: $e');
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _pickAndProcessFile() async {
    try {
      print('Выбираем файл...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'xlsx', 'xls'], // ✨ ДОБАВЛЕНО
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _isLoading = true;
          _error = null;
          _selectedIndices.clear();
        });

        print('Файл выбран: ${_selectedFile!.name}');
        print('Путь к файлу: ${_selectedFile!.path}');

        final extension = _selectedFile!.extension?.toLowerCase();
        if (extension == 'xlsx' || extension == 'xls') {
          // ✨ НОВОЕ: Парсим Excel локально
          await _parseExcelFile(_selectedFile!.path!);
        } else {
          // Отправляем файл на сервер для парсинга
          try {
            final response = await _apiService.parseProductFile(
              _selectedFile!.path!,
            );
            print('Ответ сервера: $response');

            setState(() {
              _parsedItems = List<Map<String, dynamic>>.from(
                response['items'] ?? [],
              );
              _isLoading = false;
            });

            print('Распарсено товаров: ${_parsedItems.length}');
          } catch (e) {
            print('Ошибка при отправке на сервер: $e');
            setState(() {
              _error = 'Ошибка обработки файла';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Общая ошибка выбора файла: $e');
      setState(() {
        _error = 'Ошибка выбора файла: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _existingProducts;

    // Фильтр по категории
    if (_selectedCategoryFilter != null) {
      filtered = filtered.where((product) {
        return product['category']?['id'] == _selectedCategoryFilter;
      }).toList();
    }

    // Фильтр по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        final name = (product['name'] ?? '').toLowerCase();
        final category = (product['category']?['name'] ?? '').toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _editItem(int index) {
    final item = _parsedItems[index];
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        product: item,
        categories: _categories,
        onSave: (updatedProduct) {
          setState(() {
            _parsedItems[index] = updatedProduct;
          });
        },
        onCategoriesUpdated: () async {
          await _loadCategories(); // Ждем загрузки категорий
        },
      ),
    );
  }

  void _removeFromParsedList(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить из списка?'),
        content: Text(
          'Товар "${_parsedItems[index]['name']}" будет убран из списка загруженных товаров.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _parsedItems.removeAt(index);
              });
              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Товар удалён из списка'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _addToDatabase(Map<String, dynamic> item) async {
    // Проверяем что категория выбрана
    if (item['suggestedCategoryId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Сначала выберите категорию для товара'),
          backgroundColor: Colors.orange,
        ),
      );
      _editItem(_parsedItems.indexOf(item)); // Открываем диалог редактирования
      return;
    }

    try {
      await _apiService.createProduct({
        'name': item['name'],
        'price': item['price'],
        'unit': item['unit'],
        'description': item['description'] ?? '',
        'categoryId': item['suggestedCategoryId'],
        'minQuantity': 1,
      });

      // Обновляем список товаров
      await _loadExistingProducts();

      // Убираем товар из списка для добавления
      setState(() {
        _parsedItems.removeWhere((p) => p['name'] == item['name']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Товар "${item['name']}" добавлен')),
        );
      }
    } catch (e) {
      print('Ошибка добавления товара: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: проверьте данные товара'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addAllToDatabase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить все товары?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Будет добавлено ${_parsedItems.length} товаров'),
            SizedBox(height: 8),
            if (_getUniqueExcelCategories().isNotEmpty)
              Text(
                'Новых категорий: ${_getUniqueExcelCategories().length}',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              int successCount = 0;
              int errorCount = 0;
              int categoriesCreated = 0;

              // ✅ ДОБАВЛЕНО: Сначала создаём недостающие категории
              if (_excelCategories.isNotEmpty) {
                print('\n🏷️ Создание категорий перед добавлением товаров...');
                categoriesCreated = await _autoCreateCategoriesFromExcel(
                  _excelCategories,
                );

                // Перезагружаем категории после создания
                await _loadCategories();

                // Обновляем сопоставление товаров с категориями
                final reEnrichedProducts = await _enrichProductsWithCategories(
                  _parsedItems,
                  useMappings: _useMappings,
                  mappings: _categoryMappings,
                );
                setState(() {
                  _parsedItems = reEnrichedProducts;
                });

                print('✅ Категории созданы, товары обновлены');
              }

              // Теперь добавляем товары
              for (var item in [..._parsedItems]) {
                try {
                  // Проверяем что categoryId существует
                  final categoryExists = _categories.any(
                    (cat) => cat['id'] == item['suggestedCategoryId'],
                  );

                  await _apiService.createProduct({
                    'name': item['name'],
                    'price': item['price'],
                    'unit': item['unit'],
                    'description': item['description'] ?? '',
                    'categoryId':
                        categoryExists ? item['suggestedCategoryId'] : null,
                    'minQuantity': 1,
                  });
                  successCount++;
                } catch (e) {
                  print('Ошибка добавления товара ${item['name']}: $e');
                  errorCount++;
                }
              }

              // Обновляем список и очищаем импортированные только если были успешные
              if (successCount > 0) {
                await _loadExistingProducts();
                setState(() {
                  _parsedItems.clear();
                  _excelCategories.clear(); // Очищаем также категории
                });
              }

              if (mounted) {
                String message = '';
                if (categoriesCreated > 0) {
                  message += '✅ Создано категорий: $categoriesCreated\n';
                }
                message += successCount > 0
                    ? '✅ Добавлено товаров: $successCount'
                    : '❌ Не удалось добавить товары';

                if (errorCount > 0) {
                  message += '\n⚠️ Ошибок: $errorCount';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor:
                        errorCount > 0 ? Colors.orange : Colors.green,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            },
            child: Text('Добавить'),
          ),
        ],
      ),
    );
  }

  // ✨ НОВОЕ: Быстрый выбор первых N товаров
  void _selectFirst(int count) {
    int actualCount = count < _parsedItems.length ? count : _parsedItems.length;

    setState(() {
      _selectedIndices.clear();
      for (int i = 0; i < actualCount; i++) {
        _selectedIndices.add(i);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Выбрано первых $actualCount товаров')),
    );
  }

  // ✨ НОВОЕ: Случайный выбор N товаров
  void _selectRandom(int count) {
    int actualCount = count < _parsedItems.length ? count : _parsedItems.length;

    setState(() {
      _selectedIndices.clear();
      final random = Random();
      final indices = List.generate(_parsedItems.length, (i) => i);
      indices.shuffle(random);
      _selectedIndices.addAll(indices.take(actualCount));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Выбрано $actualCount случайных товаров')),
    );
  }

  // ✨ НОВОЕ: Выбор по категориям
  void _selectByCategories(int totalCount) {
    setState(() {
      _selectedIndices.clear();

      final Map<String?, List<int>> byCategory = {};
      for (int i = 0; i < _parsedItems.length; i++) {
        final category = _parsedItems[i]['originalCategory'] as String?;
        byCategory.putIfAbsent(category, () => []).add(i);
      }

      final categoriesCount = byCategory.length;
      final perCategory = (totalCount / categoriesCount).ceil();

      for (var indices in byCategory.values) {
        final take =
            perCategory < indices.length ? perCategory : indices.length;
        _selectedIndices.addAll(indices.take(take));
        if (_selectedIndices.length >= totalCount) break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Выбрано ${_selectedIndices.length} товаров по категориям',
        ),
      ),
    );
  }

  // ✨ НОВОЕ: Выбрать все/снять все
  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndices.length == _parsedItems.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices = Set.from(
          List.generate(_parsedItems.length, (i) => i),
        );
      }
    });
  }

  // ✨ НОВОЕ: Добавление только выбранных товаров
  void _addSelectedToDatabase() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Выберите товары для добавления'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить выбранные товары?'),
        content: Text(
          'Будет добавлено ${_selectedIndices.length} товаров из ${_parsedItems.length}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Добавить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ✨ Создаём категории ПЕРЕД добавлением товаров (как было)
    int categoriesCreated = 0;
    if (_excelCategories.isNotEmpty) {
      print('🏷️ Создаём категории из Excel...');
      categoriesCreated = await _autoCreateCategoriesFromExcel(
        _excelCategories,
      );
      if (categoriesCreated > 0) {
        await _loadCategories();
        final reEnriched = await _enrichProductsWithCategories(
          _parsedItems,
          useMappings: _useMappings,
          mappings: _categoryMappings,
        );
        setState(() {
          _parsedItems = reEnriched;
        });
      }
    }

    // ✨ Показываем диалог прогресса
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Добавление ${_selectedIndices.length} товаров...',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Пожалуйста, подождите',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // ✨ ПОДГОТАВЛИВАЕМ товары для массового добавления
      final productsToAdd = <Map<String, dynamic>>[];
      final sortedIndices = _selectedIndices.toList()..sort();

      for (var index in sortedIndices) {
        final item = _parsedItems[index];
        final categoryExists = _categories.any(
          (cat) => cat['id'] == item['suggestedCategoryId'],
        );

// ✅ ОТЛАДКА
        print('=== ITEM DEBUG ===');
        print('name: ${item['name']}');
        print('basePrice: ${item['basePrice']}');
        print('baseUnit: ${item['baseUnit']}');
        print('inPackage: ${item['inPackage']}');
        print('==================');

        productsToAdd.add({
          'name': item['name'],
          'price': item['price'],
          'unit': item['unit'],
          'basePrice': item['basePrice'], // ✅ ДОБАВИТЬ
          'baseUnit': item['baseUnit'], // ✅ ДОБАВИТЬ
          'inPackage': item['inPackage'], // ✅ ДОБАВИТЬ
          'description': item['description'] ?? '',
          'categoryId': categoryExists ? item['suggestedCategoryId'] : null,
          'minQuantity': 1,
          'maxQuantity': item['maxQuantity'],
        });
      }

      // ✨ МАССОВОЕ ДОБАВЛЕНИЕ ОДНИМ ЗАПРОСОМ!
      print('🚀 Массовое добавление ${productsToAdd.length} товаров...');
      final result = await _apiService.bulkCreateProducts(productsToAdd);

      Navigator.pop(context); // Закрываем диалог прогресса

      final successCount = result['created'] ?? 0;
      final skippedCount = result['skipped'] ?? 0; // ← ДОБАВИТЬ
// ✨ ИСПРАВЛЕНИЕ: errors может быть числом или массивом
      final errorCount = result['errors'] is int
          ? result['errors']
          : (result['errors'] as List?)?.length ?? 0;

      if (successCount > 0) {
        await _loadExistingProducts();
        setState(() {
          final indicesToRemove = _selectedIndices.toList()
            ..sort((a, b) => b.compareTo(a));
          for (var index in indicesToRemove) {
            _parsedItems.removeAt(index);
          }
          _selectedIndices.clear();
          _excelCategories.clear();
        });
      }

      if (mounted) {
        String message = '';
        if (categoriesCreated > 0) {
          message += '✅ Создано категорий: $categoriesCreated\n';
        }

        if (successCount > 0) {
          message += '✅ Добавлено товаров: $successCount';
        }

        // ✨ ДОБАВИТЬ: Показываем пропущенные дубликаты
        if (skippedCount > 0) {
          message += message.isNotEmpty ? '\n' : '';
          message += '⏭️ Пропущено дубликатов: $skippedCount';
        }

        if (errorCount > 0) {
          message += message.isNotEmpty ? '\n' : '';
          message += '⚠️ Ошибок: $errorCount';
        }

        // Если ничего не добавилось
        if (successCount == 0 && skippedCount > 0) {
          message = '✅ Все товары уже есть в базе\n⏭️ Пропущено: $skippedCount';
        } else if (successCount == 0 && errorCount == 0) {
          message = '❌ Не удалось добавить товары';
        }

        // Показываем время если есть
        if (result['duration'] != null) {
          message += '\n⏱️ Время: ${result['duration']}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Закрываем диалог прогресса
      print('❌ Ошибка массового добавления: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// ✨ НОВЫЙ МЕТОД: Парсинг Excel файла локально
  Future<void> _parseExcelFile(String filePath) async {
    try {
      print('📊 Парсим Excel файл локально...');

      final result = await ExcelParserService.parseExcelFile(filePath);

      if (!result['success']) {
        throw Exception(result['error'] ?? 'Ошибка парсинга Excel');
      }

      final products = List<Map<String, dynamic>>.from(result['products']);
      final excelCategories = List<Map<String, dynamic>>.from(
        result['categories'],
      );
      // Сохраняем категории из Excel для создания при добавлении товаров
      _excelCategories = excelCategories;

      print('Excel парсинг: найдено ${products.length} товаров');
      print('Excel парсинг: найдено ${excelCategories.length} категорий');

      // ✨ НОВОЕ: Применяем 15% наценку к ценам
      final productsWithMarkup = products.map((product) {
        final originalPrice = product['price'] as double;
        final newPrice = (originalPrice * 1.15).roundToDouble();
        return {...product, 'price': newPrice, 'originalPrice': originalPrice};
      }).toList();

      print('💰 Применена наценка 15% к ${productsWithMarkup.length} товарам');

      // ✨ Сохраняем категории из Excel
      _excelCategories = excelCategories;

      // ✨ СОЗДАЁМ категории из Excel в БД ПЕРЕД обогащением товаров
      print('🏷️ Создаём категории из Excel в БД...');
      final createdCount = await _autoCreateCategoriesFromExcel(
        excelCategories,
      );
      if (createdCount > 0) {
        print('✅ Создано новых категорий: $createdCount');
        // Перезагружаем категории из БД
        await _loadCategories();
      }

      // ✨ Теперь обогащаем товары - категории уже есть в БД!
      final enrichedProducts = await _enrichProductsWithCategories(
        productsWithMarkup,
        useMappings: _useMappings,
        mappings: _categoryMappings,
      );

// ✨ ДИАГНОСТИКА: Проверяем уникальность
      print('\n📊 ДИАГНОСТИКА ТОВАРОВ:');
      print('   После парсинга: ${productsWithMarkup.length}');
      print('   После обогащения: ${enrichedProducts.length}');

      final uniqueNamesBefore =
          productsWithMarkup.map((p) => p['name']).toSet();
      final uniqueNamesAfter = enrichedProducts.map((p) => p['name']).toSet();

      print('   Уникальных названий ДО: ${uniqueNamesBefore.length}');
      print('   Уникальных названий ПОСЛЕ: ${uniqueNamesAfter.length}');
      print(
          '   Дубликатов в прайсе: ${productsWithMarkup.length - uniqueNamesBefore.length}');

// ✨ Показываем примеры дубликатов если есть
      if (productsWithMarkup.length != uniqueNamesBefore.length) {
        final nameCounts = <String, int>{};
        for (var p in productsWithMarkup) {
          final name = p['name'] as String;
          nameCounts[name] = (nameCounts[name] ?? 0) + 1;
        }

        final duplicates =
            nameCounts.entries.where((e) => e.value > 1).take(5).toList();

        print('\n   📋 Примеры дубликатов:');
        for (var dup in duplicates) {
          print('      "${dup.key}" - встречается ${dup.value} раз');
        }
      }

      setState(() {
        _parsedItems = enrichedProducts;
        _isLoading = false;
      });

      if (mounted) {
        final productsWithCategory = enrichedProducts
            .where((p) => p['suggestedCategoryId'] != null)
            .length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Загружено ${products.length} товаров\n'
              '✓ С категорией: $productsWithCategory/${products.length}\n'
              '💰 Наценка +5% применена',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Ошибка парсинга Excel: $e');
      setState(() {
        _error = 'Ошибка парсинга Excel: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка парсинга Excel: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ✅ ИЗМЕНЕНИЕ 3: Добавляем метод получения уникальных категорий из Excel
  Set<String> _getUniqueExcelCategories() {
    final uniqueCategories = <String>{};
    for (var cat in _excelCategories) {
      if (cat['level'] == 1) {
        final name = cat['name'] as String;
        // Проверяем что такой категории еще нет в БД
        final exists = _categories.any(
          (c) => c['name'].toString().toLowerCase() == name.toLowerCase(),
        );
        if (!exists) {
          uniqueCategories.add(name);
        }
      }
    }
    return uniqueCategories;
  }

  /// ✨ НОВЫЙ: Автосоздание категорий из Excel
  Future<int> _autoCreateCategoriesFromExcel(
      List<Map<String, dynamic>> excelCategories) async {
    print('\n🏷️ Автосоздание категорий с умным маппингом...');

    // ✨ Собираем оригинальные → упрощённые
    final Map<String, String> categoryMapping = {};

    for (var cat in excelCategories) {
      if (cat['level'] == 1) {
        final originalName = cat['name'] as String;

        // ✨ Маппим в упрощённую категорию
        final simplifiedName =
            CategoryMapperService.mapToSimplifiedCategory(originalName);

        if (simplifiedName != null) {
          categoryMapping[simplifiedName] = originalName;
          print('   📌 "$originalName" → "$simplifiedName"');
        } else {
          // Если не смаппилось - оставляем как есть
          categoryMapping[originalName] = originalName;
          print('   ⚠️ "$originalName" → (без изменений)');
        }
      }
    }

    // ✨ Получаем уникальные упрощённые названия
    final uniqueSimplified = categoryMapping.keys.toSet();
    print(
        '   📊 Всего категорий в прайсе: ${excelCategories.where((c) => c['level'] == 1).length}');
    print('   ✅ Уникальных упрощённых: ${uniqueSimplified.length}');

    int created = 0;
    int skipped = 0;

    // ✨ Создаём упрощённые категории
    for (var simplifiedName in uniqueSimplified) {
      try {
        final exists = _categories.any((c) =>
            c['name'].toString().toLowerCase() == simplifiedName.toLowerCase());

        if (exists) {
          skipped++;
          print('   ⏭️ Пропущена: "$simplifiedName"');
          continue;
        }

        await _apiService.createCategory(
          simplifiedName,
          description: 'Автоматически из прайса',
        );

        created++;
        print('   ✅ Создана: "$simplifiedName"');
      } catch (e) {
        print('   ⚠️ Ошибка создания "$simplifiedName": $e');
      }
    }

    print('📊 ИТОГО: Создано: $created, Пропущено: $skipped');
    return created;
  }

  /// ✨ НОВЫЙ МЕТОД: Обогащение товаров категориями из БД
  Future<List<Map<String, dynamic>>> _enrichProductsWithCategories(
    List<Map<String, dynamic>> products, {
    bool useMappings = true, // ← ДОБАВЬ ЭТИ
    Map<String, int>? mappings, // ← ТРИ СТРОКИ
  }) async {
    print('\n🔗 Обогащение товаров категориями с маппингом...');

    final enriched = <Map<String, dynamic>>[];
    int mappedCount = 0;
    int exactMatchCount = 0;
    int unmappedCount = 0;

    for (var product in products) {
      final excelCategory = product['category'];

      int? suggestedCategoryId;
      String? suggestedCategoryName;
      String matchType = 'none';
      int? categoryId;
      // ДОБАВЬ ЭТИ СТРОКИ:
      if (excelCategory == '- Пирожные, десерты, пончики') {
        print('🧪 ТЕСТ для "- Пирожные, десерты, пончики":');
        print('   useMappings = $useMappings');
        print('   mappings != null = ${mappings != null}');
        print('   mappings.length = ${mappings?.length}');
        print('   excelCategory = "$excelCategory"');
      }

      // 1. Сначала пытаемся использовать маппинг
      if (useMappings && mappings != null && excelCategory != null) {
        categoryId = CategoryMappingService.findCategoryId(
          excelCategory,
          mappings,
        );

        if (categoryId != null) {
          mappedCount++;
          print('   ✅ Маппинг: "$excelCategory" → категория #$categoryId');
        }
      }

      // 2. Fallback на старый метод CategoryMapperService
      if (categoryId == null && excelCategory != null) {
        final simplified = CategoryMapperService.mapToSimplifiedCategory(
          excelCategory,
        );

        if (simplified != null) {
          final matchedCategory = _categories.firstWhere(
            (c) =>
                c['name'].toString().toLowerCase() == simplified.toLowerCase(),
            orElse: () => <String, dynamic>{},
          );

          if (matchedCategory.isNotEmpty) {
            categoryId = matchedCategory['id'] as int;
            exactMatchCount++;
          }
        }
      }

      if (categoryId == null) {
        unmappedCount++;
        if (excelCategory != null) {
          print('   ⚠️ НЕ СМАППИЛОСЬ: "$excelCategory"');
        }
      }

      // Находим название категории
      String? categoryName;
      if (categoryId != null) {
        final category = _categories.firstWhere(
          (c) => c['id'] == categoryId,
          orElse: () => <String, dynamic>{},
        );
        categoryName = category['name'] as String?;
      }

      enriched.add({
        ...product,
        'suggestedCategoryId': categoryId,
        'suggestedCategoryName': categoryName, // ← ДОБАВЬ ЭТУ СТРОКУ
        'originalCategory': excelCategory,
      });
    }

    print('   ✅ Смаппировано: $mappedCount');
    print('   🎯 Точное совпадение: $exactMatchCount');
    print('   ⚠️ Без категории: $unmappedCount');

    return enriched;
  }

  /// ✨ НОВЫЙ: Поиск категории по точному названию
  Map<String, dynamic>? _findCategoryByExactName(String excelCategoryName) {
    final nameLower = excelCategoryName.toLowerCase().trim();

    try {
      final found = _categories.firstWhere(
        (c) => c['name'].toString().toLowerCase().trim() == nameLower,
        orElse: () => <String, dynamic>{},
      );
      return found.isNotEmpty ? found : null;
    } catch (e) {
      return null;
    }
  }

  /// ✨ НОВЫЙ МЕТОД: Поиск похожей категории в БД
  Map<String, dynamic>? _findMatchingCategory(String categoryName) {
    final nameLower = categoryName.toLowerCase();

    // Словарь соответствий
    final keywords = {
      'молочные': 1,
      'молоко': 1,
      'кефир': 1,
      'творог': 1,
      'сметана': 1,
      'мясо': 2,
      'мясные': 2,
      'птица': 2,
      'курица': 2,
      'говядина': 2,
      'овощи': 3,
      'фрукты': 3,
      'хлеб': 4,
      'выпечка': 4,
      'хлебобулочные': 4,
      'торты': 4,
      'пирожные': 4,
      'напитки': 5,
      'вода': 5,
      'сок': 5,
      'бакалея': 6,
      'крупы': 6,
      'макароны': 6,
    };

    // Пытаемся найти ключевое слово в названии категории
    for (var entry in keywords.entries) {
      if (nameLower.contains(entry.key)) {
        try {
          final found = _categories.firstWhere(
            (c) => c['id'] == entry.value,
            orElse: () => <String, dynamic>{},
          );
          // Если нашли пустую мапу - значит не нашли категорию
          return found.isNotEmpty ? found : null;
        } catch (e) {
          return null;
        }
      }
    }

    return null;
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить товар?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вы действительно хотите удалить товар:'),
            SizedBox(height: 8),
            Text(
              '"${product['name']}"',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Цена: ${product['price']} ₽ / ${product['unit'] ?? 'шт'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (product['category'] != null)
              Text(
                'Категория: ${product['category']['name']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Это действие нельзя отменить!',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );

    // Если пользователь подтвердил удаление
    if (confirmed == true) {
      try {
        print('Начинаем удаление товара ID: ${product['id']}');

        // Вызываем API для удаления
        await _apiService.deleteProduct(product['id']);

        print('Товар успешно удален с сервера');

        // Обновляем список товаров
        await _loadExistingProducts();

        // Показываем успешное сообщение
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Товар "${product['name']}" удален'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Ошибка удаления товара: $e');

        // Показываем ошибку пользователю
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAllProducts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Удалить ВСЕ товары?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Это действие удалит ВСЕ товары из базы данных безвозвратно!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Проверки безопасности:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '✓ Нет активных заказов',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text('✓ Нет активных партий', style: TextStyle(fontSize: 12)),
                  Text(
                    '✓ Все заказы завершены',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Это действие НЕЛЬЗЯ отменить!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить ВСЁ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Удаление всех товаров...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      print('Начинаем удаление ВСЕХ товаров');

      final response = await _apiService.deleteAllProducts();

      // Закрываем индикатор загрузки
      Navigator.pop(context);

      print('Результат: ${response}');

      if (response['success']) {
        final deletedCount = response['deleted'] ?? 0;

        // Обновляем список товаров
        await _loadExistingProducts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Удалено товаров: $deletedCount'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Обработка ошибок с подсказками
        final error = response['error'] ?? 'Неизвестная ошибка';
        final hint = response['hint'] ?? '';
        final activeOrders = response['activeOrders'];
        final activeBatches = response['activeBatches'];

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.block, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Невозможно удалить'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error, style: TextStyle(fontWeight: FontWeight.bold)),
                  if (hint.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text(hint, style: TextStyle(color: Colors.grey[700])),
                  ],
                  if (activeOrders != null) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Активных заказов: $activeOrders'),
                    ),
                  ],
                  if (activeBatches != null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Активных партий: $activeBatches'),
                    ),
                  ],
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Понятно'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Закрываем индикатор загрузки
      Navigator.pop(context);

      print('Ошибка удаления всех товаров: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Загрузка товаров'),
        backgroundColor: Colors.blue[600],
      ),
      body: Row(
        children: [
          // Левая панель - загруженные товары
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  // Заголовок и кнопка загрузки
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Новые товары от поставщика',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        // ✨ НОВОЕ: Ряд с двумя кнопками
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isLoading ? null : _pickAndProcessFile,
                                icon: Icon(Icons.upload_file),
                                label: Text('Загрузить файл'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(0, 40),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _manageCategories,
                              icon: Icon(Icons.category),
                              label: Text('Категории'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                minimumSize: Size(0, 40),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedFile != null) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              // ✨ НОВОЕ: Чип с типом файла
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedFile!.extension?.toLowerCase() ==
                                                  'xlsx' ||
                                              _selectedFile!.extension
                                                      ?.toLowerCase() ==
                                                  'xls'
                                          ? Colors.green[100]
                                          : Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _selectedFile!.extension?.toUpperCase() ??
                                      'FILE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedFile!.extension
                                                    ?.toLowerCase() ==
                                                'xlsx' ||
                                            _selectedFile!.extension
                                                    ?.toLowerCase() ==
                                                'xls'
                                        ? Colors.green[700]
                                        : Colors.blue[700],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Файл: ${_selectedFile!.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_error != null) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ✨ ПАНЕЛЬ БЫСТРОГО ВЫБОРА - ДОБАВЬ СЮДА
                  if (_parsedItems.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      color: Colors.blue[50],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Быстрый выбор',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Spacer(),
                              Text(
                                'Загружено: ${_parsedItems.length} товаров',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _selectFirst(500),
                                icon: Icon(Icons.filter_1, size: 18),
                                label: Text('Первые 500'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _selectRandom(500),
                                icon: Icon(Icons.shuffle, size: 18),
                                label: Text('Случайные 500'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _selectByCategories(500),
                                icon: Icon(Icons.category, size: 18),
                                label: Text('По категориям'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _toggleSelectAll,
                                icon: Icon(
                                  _selectedIndices.length == _parsedItems.length
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                ),
                                label: Text(
                                  _selectedIndices.length == _parsedItems.length
                                      ? 'Снять все'
                                      : 'Выбрать все',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[700],
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Выбрано: ${_selectedIndices.length} из ${_parsedItems.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedIndices.isEmpty
                                  ? Colors.grey[600]
                                  : Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Список загруженных товаров
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _parsedItems.isEmpty
                            ? Center(
                                child: Text(
                                  'Загрузите файл для начала работы',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _parsedItems.length,
                                itemBuilder: (context, index) {
                                  final item = _parsedItems[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    color: _selectedIndices.contains(index)
                                        ? Colors.blue[50]
                                        : null,
                                    child: ListTile(
                                      leading: Checkbox(
                                        // ← ДОБАВЬ весь этот блок
                                        value: _selectedIndices.contains(index),
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedIndices.add(index);
                                            } else {
                                              _selectedIndices.remove(index);
                                            }
                                          });
                                        },
                                      ),
                                      title: Text(item['name'] ?? ''),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.attach_money,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              Text(
                                                '${item['price']} ₽ / ${item['unit']}',
                                              ),
                                              // ✨ НОВОЕ: Показываем остаток если есть
                                              if (item['maxQuantity'] !=
                                                  null) ...[
                                                SizedBox(width: 12),
                                                Icon(
                                                  Icons.inventory_2,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                Text(
                                                  '${item['maxQuantity']}',
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          // ✨ НОВОЕ: Категория из Excel
                                          if (item['originalCategory'] != null)
                                            Text(
                                              'Excel: ${item['originalCategory']}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue[600],
                                              ),
                                            ),
                                          // Предложенная категория из БД
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  item['suggestedCategoryId'] !=
                                                          null
                                                      ? Colors.green[100]
                                                      : Colors.orange[100],
                                              borderRadius:
                                                  BorderRadius.circular(
                                                4,
                                              ),
                                            ),
                                            child: Text(
                                              'БД: ${item['suggestedCategoryName'] ?? 'Не определена'}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    item['suggestedCategoryId'] !=
                                                            null
                                                        ? Colors.green[700]
                                                        : Colors.orange[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, size: 20),
                                            onPressed: () => _editItem(index),
                                            tooltip: 'Редактировать',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red[400],
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _removeFromParsedList(index),
                                            tooltip: 'Убрать из списка',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _addToDatabase(item),
                                            tooltip: 'Добавить в базу',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),

                  // Нижняя панель с действиями
                  if (_parsedItems.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          Text(
                            'Выбрано: ${_selectedIndices.length} товаров',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          ElevatedButton.icon(
                            onPressed: _selectedIndices.isEmpty
                                ? null
                                : _addSelectedToDatabase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            icon: Icon(Icons.add_shopping_cart),
                            label: Text('Добавить выбранные'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Правая панель - существующие товары в БД
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Заголовок
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Товары в базе данных',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      // Поиск товаров
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Поиск товаров',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      SizedBox(height: 8),
                      // Фильтр по категории
                      DropdownButtonFormField<int?>(
                        value: _selectedCategoryFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Фильтр по категории',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Все категории'),
                          ),
                          ..._categories.map<DropdownMenuItem<int?>>(
                            (cat) => DropdownMenuItem<int?>(
                              value: cat['id'] as int?,
                              child: Text(cat['name'] as String),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryFilter = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Список существующих товаров
                Expanded(
                  child: _isLoadingProducts
                      ? Center(child: CircularProgressIndicator())
                      : _filteredProducts.isEmpty
                          ? Center(
                              child: Text(
                                _selectedCategoryFilter != null
                                    ? 'Нет товаров в выбранной категории'
                                    : 'База данных пуста',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  color: Colors.green[50],
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green[200],
                                      child: Text(
                                        '${product['id']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(product['name'] ?? ''),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Цена: ${product['price']} ₽ / ${product['unit'] ?? 'шт'}',
                                        ),
                                        if (product['category'] != null)
                                          Text(
                                            product['category']['name'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red[400],
                                      ),
                                      onPressed: () => _deleteProduct(product),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),

                // Информационная панель
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.green[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Всего товаров в БД: ${_existingProducts.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      if (_existingProducts.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _deleteAllProducts,
                          icon: Icon(Icons.delete_forever, size: 18),
                          label: Text(
                            'Удалить все',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size(0, 32),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ДИАЛОГ РЕДАКТИРОВАНИЯ ТОВАРА - отдельный класс в том же файле
class ProductEditDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> categories;
  final Function(Map<String, dynamic>) onSave;
  final Future<void> Function() onCategoriesUpdated;

  const ProductEditDialog({
    Key? key,
    required this.product,
    required this.categories,
    required this.onSave,
    required this.onCategoriesUpdated,
  }) : super(key: key);

  @override
  _ProductEditDialogState createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final AdminApiService _apiService = AdminApiService();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;
  int? _selectedCategoryId;
  bool _isCreatingCategory = false;
  final _formKey = GlobalKey<FormState>();
  late List<Map<String, dynamic>> _localCategories;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _priceController = TextEditingController(
      text: widget.product['price'].toString(),
    );
    _unitController = TextEditingController(text: widget.product['unit']);
    _descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );
    _selectedCategoryId = widget.product['suggestedCategoryId'];
    _localCategories = List.from(widget.categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showCreateCategoryDialog() {
    final categoryNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Создать новую категорию'),
        content: TextField(
          controller: categoryNameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Название категории',
            border: OutlineInputBorder(),
            hintText: 'Например: Замороженные продукты',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final categoryName = categoryNameController.text.trim();
              if (categoryName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Введите название категории')),
                );
                return;
              }

              Navigator.pop(context);
              setState(() => _isCreatingCategory = true);

              try {
                final response = await _apiService.createCategory(categoryName);
                final newCategory = response['category'];

                // Обновляем список категорий в родительском виджете
                await widget.onCategoriesUpdated();

                // Добавляем новую категорию в локальный список
                setState(() {
                  _localCategories.add(newCategory);
                  _selectedCategoryId = newCategory['id'];
                  _isCreatingCategory = false;
                });

                // Безопасно показываем SnackBar
                if (mounted) {
                  final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
                  if (scaffoldMessenger != null) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Категория "$categoryName" создана'),
                      ),
                    );
                  }
                }
              } catch (e) {
                setState(() => _isCreatingCategory = false);
                if (mounted) {
                  final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
                  if (scaffoldMessenger != null) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Ошибка создания категории'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Редактирование товара'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Название обязательно';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Цена',
                  border: OutlineInputBorder(),
                  suffixText: '₽',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Цена обязательна';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: 'Единица измерения',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Единица измерения обязательна';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Категория *',
                        border: OutlineInputBorder(),
                      ),
                      items: _localCategories
                          .map<DropdownMenuItem<int>>(
                            (cat) => DropdownMenuItem<int>(
                              value: cat['id'] as int,
                              child: Text(cat['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Выберите категорию';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        _isCreatingCategory ? null : _showCreateCategoryDialog,
                    icon: _isCreatingCategory
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.add_circle),
                    tooltip: 'Создать категорию',
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            final updatedProduct = {
              ...widget.product,
              'name': _nameController.text.trim(),
              'price': double.tryParse(_priceController.text) ?? 0,
              'unit': _unitController.text.trim(),
              'description': _descriptionController.text.trim(),
              'suggestedCategoryId': _selectedCategoryId,
            };
            widget.onSave(updatedProduct);
            Navigator.pop(context);
          },
          child: Text('Сохранить'),
        ),
      ],
    );
  }
}
