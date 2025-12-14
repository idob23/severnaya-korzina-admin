// lib/screens/add_product_screen.dart - ПОЛНЫЙ ФАЙЛ

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:severnaya_korzina_admin/services/excel_parser_service.dart';
import 'dart:math';
import 'dart:async';
import '../services/admin_api_service.dart';
import 'manage_categories_screen.dart';
import '../services/category_mapper_service.dart';
import '../services/category_mapping_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/foundation.dart';
import 'add_product/widgets/parsed_product_tile.dart';
import 'add_product/widgets/product_edit_dialog.dart';

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
  Timer? _searchDebounce;

  // Данные
  PlatformFile? _selectedFile;
  List<Map<String, dynamic>> _parsedItems = [];
  Set<int> _selectedIndices = {}; // ✨ НОВОЕ: выбранные товары
  List<Map<String, dynamic>> _existingProducts = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, Map<String, dynamic>> _categoryMappings = {};
  bool _useMappings = true; // ← И ЭТУ СТРОКУ
  int? _selectedCategoryFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _excelCategories = [];
  final ScrollController _listScrollController = ScrollController();
  final TextEditingController _parsedSearchController = TextEditingController();
  int? _highlightedIndex; // Индекс подсвеченного товара

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadMappings();
  }

  // ← ДОБАВЬ ВЕСЬ ЭТОТ МЕТОД:
  Future<void> _loadMappings() async {
    try {
      if (kDebugMode) print('📥 Загрузка маппингов категорий...');
      if (kDebugMode)
        print(
            '🌐 URL: ${CategoryMappingService.baseUrl}'); // ← ДОБАВЬ ЭТУ СТРОКУ
      final mappings = await CategoryMappingService.loadMappings();

      setState(() {
        _categoryMappings = mappings;
      });

      if (kDebugMode) print('✅ Загружено ${mappings.length} маппингов');
      if (kDebugMode)
        print(
            '📋 Первые 3 маппинга: ${mappings.entries.take(3).toList()}'); // ← И ЭТУ
    } catch (e) {
      if (kDebugMode) print('⚠️ Ошибка загрузки маппингов: $e');
      if (kDebugMode) print('⚠️ Stack trace: ${StackTrace.current}'); // ← И ЭТУ
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
      if (kDebugMode) print('Категории загружены: ${_categories.length}');
    } catch (e) {
      if (kDebugMode) print('Ошибка загрузки категорий: $e');
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
      if (kDebugMode)
        print('Товары загружены: ${response['products']?.length ?? 0}');

      setState(() {
        _existingProducts = List<Map<String, dynamic>>.from(
          response['products'] ?? [],
        ).where((p) => p['isActive'] == true).toList();
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (kDebugMode) print('Ошибка загрузки товаров: $e');
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _pickAndProcessFile() async {
    try {
      if (kDebugMode) print('Выбираем файл...');

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

        if (kDebugMode) print('Файл выбран: ${_selectedFile!.name}');
        if (kDebugMode) print('Путь к файлу: ${_selectedFile!.path}');

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
            if (kDebugMode) print('Ответ сервера: $response');

            setState(() {
              _parsedItems = List<Map<String, dynamic>>.from(
                response['items'] ?? [],
              );
              _isLoading = false;
            });

            if (kDebugMode) print('Распарсено товаров: ${_parsedItems.length}');
          } catch (e) {
            if (kDebugMode) print('Ошибка при отправке на сервер: $e');
            setState(() {
              _error = 'Ошибка обработки файла';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Общая ошибка выбора файла: $e');
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    _parsedSearchController.dispose();
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
        // Новый callback для применения маппинга ко всем товарам
        onMappingCreated: (supplierCategory, categoryId, saleType) async {
          await _applyMappingToAllProducts(supplierCategory, categoryId, saleType);
        },
      ),
    );
  }

  /// Применяет маппинг ко всем товарам с такой же категорией из Excel
  Future<void> _applyMappingToAllProducts(
    String supplierCategory,
    int categoryId,
    String saleType,
  ) async {
    // Находим название категории
    String? categoryName;
    try {
      final category = _categories.firstWhere((c) => c['id'] == categoryId);
      categoryName = category['name'] as String?;
    } catch (e) {
      categoryName = null;
    }

    int updatedCount = 0;

    setState(() {
      for (int i = 0; i < _parsedItems.length; i++) {
        final item = _parsedItems[i];
        final itemCategory = item['originalCategory'] as String?;

        // Если категория из Excel совпадает — применяем маппинг
        if (itemCategory == supplierCategory) {
          _parsedItems[i] = {
            ...item,
            'suggestedCategoryId': categoryId,
            'suggestedCategoryName': categoryName,
            'saleType': saleType,
          };
          updatedCount++;
        }
      }

      // Обновляем локальный кэш маппингов
      _categoryMappings[supplierCategory] = {
        'categoryId': categoryId,
        'saleType': saleType,
      };
    });

    if (mounted && updatedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Маппинг сохранён!\nОбновлено товаров: $updatedCount',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }

    if (kDebugMode) {
      print('📝 Создан маппинг: "$supplierCategory" → категория #$categoryId ($categoryName)');
      print('   Обновлено товаров: $updatedCount');
    }
  }

  /// Возвращает количество уникальных немаппированных категорий
  int _getUnmappedCategoriesCount() {
    final unmappedCategories = <String>{};
    for (var item in _parsedItems) {
      if (item['suggestedCategoryId'] == null) {
        final originalCat = item['originalCategory'] as String?;
        if (originalCat != null && originalCat.isNotEmpty) {
          unmappedCategories.add(originalCat);
        }
      }
    }
    return unmappedCategories.length;
  }

  /// Возвращает количество товаров без категории
  int _getUnmappedProductsCount() {
    return _parsedItems.where((item) => item['suggestedCategoryId'] == null).length;
  }

  /// Показывает диалог со списком немаппированных категорий
  void _showUnmappedCategoriesDialog() {
    // Собираем статистику по немаппированным категориям
    final unmappedStats = <String, int>{};
    for (var item in _parsedItems) {
      if (item['suggestedCategoryId'] == null) {
        final originalCat = item['originalCategory'] as String? ?? 'Без категории';
        unmappedStats[originalCat] = (unmappedStats[originalCat] ?? 0) + 1;
      }
    }

    // Сортируем по количеству товаров
    final sortedCategories = unmappedStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.category_outlined, color: Colors.orange[700]),
            SizedBox(width: 8),
            Text('Немаппированные категории'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Нажмите на категорию, чтобы назначить её товарам',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, index) {
                    final entry = sortedCategories[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                        title: Text(
                          entry.key,
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          '${entry.value} товаров',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: Icon(Icons.edit, size: 18, color: Colors.blue),
                        onTap: () {
                          Navigator.pop(context);
                          _showQuickMappingDialog(entry.key, entry.value);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Быстрый диалог назначения категории для всех товаров с определённой категорией из Excel
  void _showQuickMappingDialog(String supplierCategory, int productCount) {
    int? selectedCategoryId;
    String selectedSaleType = 'поштучно';
    bool saveMapping = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Назначить категорию'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Категория из прайса:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '"$supplierCategory"',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Товаров: $productCount',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Выберите категорию',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map<DropdownMenuItem<int>>(
                      (cat) => DropdownMenuItem<int>(
                        value: cat['id'] as int,
                        child: Text(cat['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedCategoryId = value;
                  });
                },
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedSaleType,
                decoration: InputDecoration(
                  labelText: 'Тип продажи',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'поштучно', child: Text('Поштучно')),
                  DropdownMenuItem(value: 'только уп', child: Text('Только упаковками')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedSaleType = value ?? 'поштучно';
                  });
                },
              ),
              SizedBox(height: 12),
              CheckboxListTile(
                value: saveMapping,
                onChanged: (value) {
                  setDialogState(() {
                    saveMapping = value ?? true;
                  });
                },
                title: Text('Сохранить маппинг', style: TextStyle(fontSize: 13)),
                subtitle: Text(
                  'Запомнить для будущих загрузок',
                  style: TextStyle(fontSize: 11),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: selectedCategoryId == null
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);

                      // Сохраняем маппинг если выбрано
                      if (saveMapping) {
                        try {
                          await CategoryMappingService.createMapping(
                            supplierCategory: supplierCategory,
                            targetCategoryId: selectedCategoryId!,
                          );
                        } catch (e) {
                          if (kDebugMode) print('Ошибка сохранения маппинга: $e');
                        }
                      }

                      // Применяем ко всем товарам
                      await _applyMappingToAllProducts(
                        supplierCategory,
                        selectedCategoryId!,
                        selectedSaleType,
                      );
                    },
              child: Text('Применить'),
            ),
          ],
        ),
      ),
    );
  }

  // ============== СРАВНЕНИЕ ПРАЙСА С БАЗОЙ ==============

  /// Нормализует название для сравнения
  /// Убирает лишние пробелы, приводит к нижнему регистру, заменяет запятые на точки
  String _normalizeProductName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // множественные пробелы → один
        .replaceAll(',', '.')            // запятые → точки
        .replaceAll('ё', 'е');           // ё → е
  }

  /// Безопасно парсит значение в double (может быть String, num или null)
  double _parseToDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// Безопасно парсит значение в int (может быть String, num или null)
  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Сравнивает загруженный прайс с товарами в базе
  /// Возвращает статистику: новые, обновление цен, без изменений, отсутствующие в прайсе
  Map<String, dynamic> _compareWithDatabase() {
    final result = {
      'newProducts': <Map<String, dynamic>>[],      // Новые товары (нет в базе)
      'priceChanges': <Map<String, dynamic>>[],     // Изменение цены/остатков
      'unchanged': <Map<String, dynamic>>[],        // Без изменений
      'missingInPrice': <Map<String, dynamic>>[],   // Есть в базе, нет в прайсе
    };

    // Создаём индекс товаров в базе по нормализованному названию
    final dbIndex = <String, Map<String, dynamic>>{};
    final dbNamesUsed = <String>{};

    for (var dbProduct in _existingProducts) {
      final name = dbProduct['name'] as String? ?? '';
      final normalizedName = _normalizeProductName(name);
      if (normalizedName.isNotEmpty) {
        dbIndex[normalizedName] = dbProduct;
      }
    }

    // Убираем дубликаты из прайса — оставляем только уникальные товары
    // (берём первый встреченный товар с таким названием)
    final uniqueParsedItems = <String, Map<String, dynamic>>{};
    for (var parsedItem in _parsedItems) {
      final parsedName = parsedItem['name'] as String? ?? '';
      final normalizedParsedName = _normalizeProductName(parsedName);
      if (normalizedParsedName.isNotEmpty && !uniqueParsedItems.containsKey(normalizedParsedName)) {
        uniqueParsedItems[normalizedParsedName] = parsedItem;
      }
    }

    // Сравниваем каждый УНИКАЛЬНЫЙ товар из прайса
    for (var entry in uniqueParsedItems.entries) {
      final normalizedParsedName = entry.key;
      final parsedItem = entry.value;

      if (dbIndex.containsKey(normalizedParsedName)) {
        // Товар найден в базе
        final dbProduct = dbIndex[normalizedParsedName]!;
        dbNamesUsed.add(normalizedParsedName);

        // Безопасный парсинг цен (могут быть String или num)
        final parsedPrice = _parseToDouble(parsedItem['price']);
        final dbPrice = _parseToDouble(dbProduct['price']);
        final parsedStock = _parseToInt(parsedItem['maxQuantity']);
        final dbStock = _parseToInt(dbProduct['maxQuantity']);

        // Получаем текущий тип продажи из базы
        final dbSaleType = dbProduct['saleType'] as String? ?? 'поштучно';

        // Проверяем изменения цены или остатков
        final priceChanged = (parsedPrice - dbPrice).abs() > 0.01;
        final stockChanged = parsedStock != null && parsedStock != dbStock;

        if (priceChanged || stockChanged) {
          (result['priceChanges'] as List).add({
            'parsed': parsedItem,
            'db': dbProduct,
            'oldPrice': dbPrice,
            'newPrice': parsedPrice,
            'oldStock': dbStock,
            'newStock': parsedStock,
            'priceChanged': priceChanged,
            'stockChanged': stockChanged,
            'saleType': dbSaleType,  // Текущий тип продажи из базы
          });
        } else {
          (result['unchanged'] as List).add({
            'parsed': parsedItem,
            'db': dbProduct,
          });
        }
      } else {
        // Товар не найден в базе — новый
        (result['newProducts'] as List).add(parsedItem);
      }
    }

    // Находим товары, которые есть в базе, но нет в прайсе
    for (var dbProduct in _existingProducts) {
      final name = dbProduct['name'] as String? ?? '';
      final normalizedName = _normalizeProductName(name);
      if (normalizedName.isNotEmpty && !dbNamesUsed.contains(normalizedName)) {
        (result['missingInPrice'] as List).add(dbProduct);
      }
    }

    return result;
  }

  /// Показывает диалог сравнения прайса с базой
  void _showCompareWithDatabaseDialog() {
    if (_parsedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Сначала загрузите прайс'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final comparison = _compareWithDatabase();
    final newProducts = comparison['newProducts'] as List;
    final priceChanges = comparison['priceChanges'] as List;
    final unchanged = comparison['unchanged'] as List;
    final missingInPrice = comparison['missingInPrice'] as List;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text('Сравнение с базой'),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Статистика
                    _buildComparisonStatCard(
                      icon: Icons.fiber_new,
                      color: Colors.green,
                      title: 'Новые товары',
                      count: newProducts.length,
                      onAction: newProducts.isEmpty ? null : () {
                        Navigator.pop(dialogContext);
                        _showNewProductsList(newProducts);
                      },
                      actionLabel: 'Показать',
                    ),
                    SizedBox(height: 8),
                    _buildComparisonStatCard(
                      icon: Icons.price_change,
                      color: Colors.orange,
                      title: 'Изменение цен/остатков',
                      count: priceChanges.length,
                      onAction: priceChanges.isEmpty ? null : () {
                        Navigator.pop(dialogContext);
                        _showPriceChangesDialog(priceChanges);
                      },
                      actionLabel: 'Обновить',
                    ),
                    SizedBox(height: 8),
                    _buildComparisonStatCard(
                      icon: Icons.check_circle,
                      color: Colors.grey,
                      title: 'Без изменений',
                      count: unchanged.length,
                      onAction: null,
                      actionLabel: '',
                    ),
                    SizedBox(height: 8),
                    _buildComparisonStatCard(
                      icon: Icons.warning_amber,
                      color: Colors.red,
                      title: 'Нет в новом прайсе',
                      count: missingInPrice.length,
                      onAction: missingInPrice.isEmpty ? null : () {
                        Navigator.pop(dialogContext);
                        _showMissingProductsDialog(missingInPrice);
                      },
                      actionLabel: 'Показать',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Закрыть'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComparisonStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required int count,
    required VoidCallback? onAction,
    required String actionLabel,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('$count товаров', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (onAction != null)
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(actionLabel, style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  /// Показывает список новых товаров с чекбоксами для выбора
  void _showNewProductsList(List newProducts) {
    final selectedProducts = List<bool>.filled(newProducts.length, true);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.fiber_new, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Новые товары (${newProducts.length})',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 450,
            child: Column(
              children: [
                // Кнопки выбора всех/снять все
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          for (int i = 0; i < selectedProducts.length; i++) {
                            selectedProducts[i] = true;
                          }
                        });
                      },
                      child: Text('Выбрать все'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          for (int i = 0; i < selectedProducts.length; i++) {
                            selectedProducts[i] = false;
                          }
                        });
                      },
                      child: Text('Снять все'),
                    ),
                    Spacer(),
                    Text(
                      'Выбрано: ${selectedProducts.where((s) => s).length}',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: newProducts.length,
                    itemBuilder: (context, index) {
                      final product = newProducts[index];
                      return CheckboxListTile(
                        value: selectedProducts[index],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedProducts[index] = value ?? false;
                          });
                        },
                        dense: true,
                        title: Text(
                          product['name'] ?? '',
                          style: TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_parseToDouble(product['price']).toStringAsFixed(0)} ₽ • ${product['category'] ?? 'Без категории'}',
                          style: TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Закрыть'),
            ),
            ElevatedButton(
              onPressed: selectedProducts.where((s) => s).isEmpty
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      // Выбираем только отмеченные новые товары
                      final selectedNewProducts = <Map<String, dynamic>>[];
                      for (int i = 0; i < newProducts.length; i++) {
                        if (selectedProducts[i]) {
                          selectedNewProducts.add(newProducts[i] as Map<String, dynamic>);
                        }
                      }
                      _selectOnlyNewProducts(selectedNewProducts);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Выбрать для добавления (${selectedProducts.where((s) => s).length})'),
            ),
          ],
        ),
      ),
    );
  }

  /// Выбирает только новые товары (которых нет в базе)
  void _selectOnlyNewProducts(List newProducts) {
    final newNames = newProducts.map((p) => _normalizeProductName(p['name'] ?? '')).toSet();

    setState(() {
      _selectedIndices.clear();
      for (int i = 0; i < _parsedItems.length; i++) {
        final name = _normalizeProductName(_parsedItems[i]['name'] ?? '');
        if (newNames.contains(name)) {
          _selectedIndices.add(i);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Выбрано ${_selectedIndices.length} новых товаров'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Показывает диалог с изменениями цен
  void _showPriceChangesDialog(List priceChanges) {
    final selectedChanges = List<bool>.filled(priceChanges.length, true);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.price_change, color: Colors.orange),
              SizedBox(width: 8),
              Text('Обновление цен (${priceChanges.length})'),
            ],
          ),
          content: SizedBox(
            width: 550,
            height: 450,
            child: Column(
              children: [
                // Кнопки выбора всех/снять все
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          for (int i = 0; i < selectedChanges.length; i++) {
                            selectedChanges[i] = true;
                          }
                        });
                      },
                      child: Text('Выбрать все'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          for (int i = 0; i < selectedChanges.length; i++) {
                            selectedChanges[i] = false;
                          }
                        });
                      },
                      child: Text('Снять все'),
                    ),
                    Spacer(),
                    Text(
                      'Выбрано: ${selectedChanges.where((s) => s).length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: priceChanges.length,
                    itemBuilder: (context, index) {
                      final change = priceChanges[index];
                      final oldPrice = change['oldPrice'] as double;
                      final newPrice = change['newPrice'] as double;
                      final priceDiff = newPrice - oldPrice;
                      final priceDiffPercent = oldPrice > 0 ? (priceDiff / oldPrice * 100) : 0;
                      final priceChanged = change['priceChanged'] as bool;
                      final stockChanged = change['stockChanged'] as bool;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            children: [
                              // Чекбокс выбора
                              Checkbox(
                                value: selectedChanges[index],
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedChanges[index] = value ?? false;
                                  });
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              // Название и изменения
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      change['parsed']['name'] ?? '',
                                      style: TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        if (priceChanged) ...[
                                          Text(
                                            '${oldPrice.toStringAsFixed(0)}₽ → ${newPrice.toStringAsFixed(0)}₽',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                          SizedBox(width: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: priceDiff > 0 ? Colors.red[100] : Colors.green[100],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${priceDiff > 0 ? '+' : ''}${priceDiffPercent.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: priceDiff > 0 ? Colors.red[800] : Colors.green[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (priceChanged && stockChanged)
                                          SizedBox(width: 8),
                                        if (stockChanged)
                                          Text(
                                            'Ост: ${change['oldStock'] ?? '?'} → ${change['newStock'] ?? '?'}',
                                            style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: selectedChanges.where((s) => s).isEmpty
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await _applyPriceChanges(priceChanges, selectedChanges);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Обновить выбранные'),
            ),
          ],
        ),
      ),
    );
  }

  /// Применяет выбранные изменения цен
  Future<void> _applyPriceChanges(List priceChanges, List<bool> selectedChanges) async {
    int updatedCount = 0;
    int errorCount = 0;

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Обновление товаров...'),
          ],
        ),
      ),
    );

    for (int i = 0; i < priceChanges.length; i++) {
      if (!selectedChanges[i]) continue;

      final change = priceChanges[i];
      final dbProduct = change['db'] as Map<String, dynamic>;
      final parsedProduct = change['parsed'] as Map<String, dynamic>;
      final productId = dbProduct['id'] as int?;

      if (productId == null) continue;

      try {
        // Используем существующий метод updateProduct
        await _apiService.updateProduct(productId, {
          'price': parsedProduct['price'],
          'maxQuantity': parsedProduct['maxQuantity'] ?? dbProduct['maxQuantity'],
        });
        updatedCount++;
      } catch (e) {
        errorCount++;
        if (kDebugMode) print('Ошибка обновления товара $productId: $e');
      }
    }

    // Закрываем индикатор
    if (mounted) Navigator.pop(context);

    // Перезагружаем товары
    await _loadExistingProducts();

    // Показываем результат
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorCount > 0
                ? '✅ Обновлено: $updatedCount, ❌ Ошибок: $errorCount'
                : '✅ Обновлено товаров: $updatedCount',
          ),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Показывает диалог с товарами, которых нет в новом прайсе
  void _showMissingProductsDialog(List missingProducts) {
    final selectedForDelete = List<bool>.filled(missingProducts.length, false);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Нет в новом прайсе (${missingProducts.length})',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Эти товары есть в базе, но отсутствуют в загруженном прайсе. '
                    'Возможно, их сняли с продажи.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          for (int i = 0; i < selectedForDelete.length; i++) {
                            selectedForDelete[i] = true;
                          }
                        });
                      },
                      child: Text('Выбрать все'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          for (int i = 0; i < selectedForDelete.length; i++) {
                            selectedForDelete[i] = false;
                          }
                        });
                      },
                      child: Text('Снять все'),
                    ),
                    Spacer(),
                    Text(
                      'Для удаления: ${selectedForDelete.where((s) => s).length}',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: missingProducts.length,
                    itemBuilder: (context, index) {
                      final product = missingProducts[index];
                      return CheckboxListTile(
                        value: selectedForDelete[index],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedForDelete[index] = value ?? false;
                          });
                        },
                        dense: true,
                        title: Text(
                          product['name'] ?? '',
                          style: TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_parseToDouble(product['price']).toStringAsFixed(0)} ₽ • ${product['category']?['name'] ?? 'Без категории'}',
                          style: TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: selectedForDelete.where((s) => s).isEmpty
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Подтверждение удаления'),
                          content: Text(
                            'Вы уверены, что хотите удалить ${selectedForDelete.where((s) => s).length} товаров?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Отмена'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: Text('Удалить'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        Navigator.pop(dialogContext);
                        await _deleteMissingProducts(missingProducts, selectedForDelete);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Удалить выбранные'),
            ),
          ],
        ),
      ),
    );
  }

  /// Удаляет выбранные товары, которых нет в прайсе
  Future<void> _deleteMissingProducts(List missingProducts, List<bool> selectedForDelete) async {
    int deletedCount = 0;
    int errorCount = 0;

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Удаление товаров...'),
          ],
        ),
      ),
    );

    for (int i = 0; i < missingProducts.length; i++) {
      if (!selectedForDelete[i]) continue;

      final product = missingProducts[i];
      final productId = product['id'] as int?;

      if (productId == null) continue;

      try {
        // Используем существующий метод deleteProduct
        await _apiService.deleteProduct(productId);
        deletedCount++;
      } catch (e) {
        errorCount++;
        if (kDebugMode) print('Ошибка удаления товара $productId: $e');
      }
    }

    // Закрываем индикатор
    if (mounted) Navigator.pop(context);

    // Перезагружаем товары
    await _loadExistingProducts();

    // Показываем результат
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorCount > 0
                ? '✅ Удалено: $deletedCount, ❌ Ошибок: $errorCount'
                : '✅ Удалено товаров: $deletedCount',
          ),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ============== КОНЕЦ: СРАВНЕНИЕ ПРАЙСА С БАЗОЙ ==============

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
        'unit': (item['saleType'] == 'только уп')
            ? item['unit'] // Для упаковок - оставляем как есть
            : (item['baseUnit'] ?? 'шт'), // Для штучных - берём baseUnit
        'description': item['description'] ?? '',
        'categoryId': item['suggestedCategoryId'],
        'saleType': item['saleType'] ?? 'поштучно',
        'minQuantity': 1,
        'basePrice': item['basePrice'], // ✅ ДОБАВИТЬ
        'baseUnit': item['baseUnit'], // ✅ ДОБАВИТЬ
        'inPackage': item['inPackage'], // ✅ ДОБАВИТЬ
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
      if (kDebugMode) print('Ошибка добавления товара: $e');
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
                if (kDebugMode)
                  print(
                      '\n🏷️ Создание категорий перед добавлением товаров...');
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

                if (kDebugMode) print('✅ Категории созданы, товары обновлены');
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
                  if (kDebugMode)
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

  void _searchAndScrollToProduct(String query) {
    if (query.trim().isEmpty) {
      setState(() => _highlightedIndex = null);
      return;
    }

    final foundIndex = _parsedItems.indexWhere((item) => (item['name'] ?? '')
        .toString()
        .toLowerCase()
        .contains(query.toLowerCase()));

    if (foundIndex != -1) {
      setState(() => _highlightedIndex = foundIndex);

      // ✅ ТОЧНАЯ ПРОКРУТКА К ЭЛЕМЕНТУ
      _itemScrollController.scrollTo(
        index: foundIndex,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // 10% от верха экрана
      );

      Future.delayed(Duration(seconds: 3), () {
        if (mounted) setState(() => _highlightedIndex = null);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Товар "$query" не найден'),
            backgroundColor: Colors.orange),
      );
    }
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

    // ✅ ОТКЛЮЧЕНО: Автосоздание категорий из Excel
// Теперь используем ТОЛЬКО существующие категории из маппинга
    int categoriesCreated = 0;
    if (kDebugMode) print('📋 Проверка категорий из маппинга...');

// Проверяем что все нужные категории из маппинга уже существуют в БД
    final Set<int> requiredCategoryIds = {};
    for (var mapping in _categoryMappings.values) {
      final categoryId = mapping['categoryId'] as int?;
      if (categoryId != null) {
        requiredCategoryIds.add(categoryId);
      }
    }

    final missingCategories = requiredCategoryIds
        .where((id) => !_categories.any((cat) => cat['id'] == id))
        .toList();

    if (missingCategories.isNotEmpty) {
      if (kDebugMode)
        print('⚠️ ВНИМАНИЕ: Отсутствуют категории с ID: $missingCategories');
      if (kDebugMode)
        print('💡 Добавьте эти категории вручную или обновите маппинг');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Внимание: Некоторые категории из маппинга не найдены в БД.\n'
                'ID отсутствующих категорий: ${missingCategories.join(", ")}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else {
      if (kDebugMode) print('✅ Все категории из маппинга присутствуют в БД');
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
        if (kDebugMode) print('=== ITEM DEBUG ===');
        if (kDebugMode) print('name: ${item['name']}');
        if (kDebugMode) print('basePrice: ${item['basePrice']}');
        if (kDebugMode) print('baseUnit: ${item['baseUnit']}');
        if (kDebugMode) print('inPackage: ${item['inPackage']}');
        if (kDebugMode) print('==================');

        productsToAdd.add({
          'name': item['name'],
          'price': item['price'],
          'unit': (item['saleType'] == 'только уп')
              ? item['unit'] // Для упаковок оставляем "уп (X шт)"
              : (item['baseUnit'] ?? 'шт'), // Для штучных - "шт"
          'basePrice': item['basePrice'], // ✅ ДОБАВИТЬ
          'baseUnit': item['baseUnit'], // ✅ ДОБАВИТЬ
          'inPackage': item['inPackage'], // ✅ ДОБАВИТЬ
          'saleType': item['saleType'] ?? 'поштучно',
          'description': item['description'] ?? '',
          'categoryId': categoryExists ? item['suggestedCategoryId'] : null,
          'minQuantity': 1,
          'maxQuantity': item['maxQuantity'],
        });
      }

      // ✨ МАССОВОЕ ДОБАВЛЕНИЕ ОДНИМ ЗАПРОСОМ!
      if (kDebugMode)
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
      if (kDebugMode) print('❌ Ошибка массового добавления: $e');

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
      if (kDebugMode) print('📊 Парсим Excel файл локально...');

      // ✅ ДОБАВЬ ЭТИ СТРОКИ:
      if (_categoryMappings.isEmpty) {
        if (kDebugMode) print('⏳ Маппинги ещё не загружены, загружаем...');
        await _loadMappings();
        if (kDebugMode)
          print('✅ Маппинги загружены: ${_categoryMappings.length}');
      } else {
        if (kDebugMode)
          print('✅ Маппинги уже загружены: ${_categoryMappings.length}');
      }

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

      if (kDebugMode)
        print('Excel парсинг: найдено ${products.length} товаров');
      if (kDebugMode)
        print('Excel парсинг: найдено ${excelCategories.length} категорий');

// ✅ DEBUG: Логируем ПЕРЕД применением наценки
      for (var product in products) {
        if (product['name'].toString().contains('Колосок')) {
          if (kDebugMode) print('🔍 DEBUG Колосок ПЕРЕД наценкой:');
          if (kDebugMode) print('   name: ${product['name']}');
          if (kDebugMode) print('   price: ${product['price']}');
          if (kDebugMode) print('   unit: ${product['unit']}');
          if (kDebugMode) print('   basePrice: ${product['basePrice']}');
          if (kDebugMode) print('   baseUnit: ${product['baseUnit']}');
          if (kDebugMode) print('   inPackage: ${product['inPackage']}');
          if (kDebugMode) print('   packagePrice: ${product['packagePrice']}');
        }
      }

      final productsWithMarkup = products.map((product) {
        // ✅ Для весовых товаров (isFixedWeight) игнорируем packagePrice —
        // там уже правильная цена за кусок (цена_за_кг × вес_куска)
        final isFixedWeight = product['isFixedWeight'] == true;
        final packagePriceFromExcel = isFixedWeight
            ? null
            : product['packagePrice'] as double?;
        final priceToMarkup =
            (packagePriceFromExcel ?? product['price']) as double;

        // Применяем наценку к цене упаковки
        final priceWithMarkup = (priceToMarkup * 1.15).roundToDouble();

        // Цена за штуку с наценкой
        final basePrice = (product['basePrice'] ?? product['price']) as double;
        final basePriceWithMarkup = (basePrice * 1.15).roundToDouble();

        return {
          ...product,
          'price': priceWithMarkup, // 1872 * 1.15 = 2153
          'basePrice': basePriceWithMarkup, // 58.5 * 1.15 = 67
          'originalPrice': priceToMarkup,
          'originalBasePrice': basePrice,
        };
      }).toList();

      // ✅ DEBUG: Логируем ПОСЛЕ применения наценки
      for (var product in productsWithMarkup) {
        if (product['name'].toString().contains('Колосок')) {
          if (kDebugMode) print('🔍 DEBUG Колосок ПОСЛЕ наценки:');
          if (kDebugMode) print('   name: ${product['name']}');
          if (kDebugMode) print('   price: ${product['price']}');
          if (kDebugMode) print('   unit: ${product['unit']}');
          if (kDebugMode) print('   basePrice: ${product['basePrice']}');
          if (kDebugMode) print('   baseUnit: ${product['baseUnit']}');
          if (kDebugMode) print('   inPackage: ${product['inPackage']}');
        }
      }

      if (kDebugMode)
        print(
            '💰 Применена наценка 15% к ${productsWithMarkup.length} товарам');

      // ✨ Сохраняем категории из Excel
      _excelCategories = excelCategories;

      // ✨ СОЗДАЁМ категории из Excel в БД ПЕРЕД обогащением товаров
      if (kDebugMode) print('🏷️ Создаём категории из Excel в БД...');
      final createdCount = await _autoCreateCategoriesFromExcel(
        excelCategories,
      );
      if (createdCount > 0) {
        if (kDebugMode) print('✅ Создано новых категорий: $createdCount');
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
      if (kDebugMode) print('\n📊 ДИАГНОСТИКА ТОВАРОВ:');
      if (kDebugMode) print('   После парсинга: ${productsWithMarkup.length}');
      if (kDebugMode) print('   После обогащения: ${enrichedProducts.length}');

      final uniqueNamesBefore =
          productsWithMarkup.map((p) => p['name']).toSet();
      final uniqueNamesAfter = enrichedProducts.map((p) => p['name']).toSet();

      if (kDebugMode)
        print('   Уникальных названий ДО: ${uniqueNamesBefore.length}');
      if (kDebugMode)
        print('   Уникальных названий ПОСЛЕ: ${uniqueNamesAfter.length}');
      if (kDebugMode)
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

        if (kDebugMode) print('\n   📋 Примеры дубликатов:');
        for (var dup in duplicates) {
          if (kDebugMode)
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
      if (kDebugMode) print('Ошибка парсинга Excel: $e');
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

  /// ✨ Автосоздание ТОЛЬКО целевых категорий из маппинга
  Future<int> _autoCreateCategoriesFromExcel(
      List<Map<String, dynamic>> excelCategories) async {
    if (kDebugMode)
      print('\n🏷️ Автосоздание целевых категорий из маппинга...');

    // ✅ Собираем ТОЛЬКО уникальные целевые категории из маппинга
    final Set<int> targetCategoryIds = {};

    for (var mapping in _categoryMappings.values) {
      final categoryId = mapping['categoryId'] as int?;
      if (categoryId != null) {
        targetCategoryIds.add(categoryId);
      }
    }

    if (kDebugMode)
      print(
          '   📊 Найдено ${targetCategoryIds.length} уникальных целевых категорий в маппинге');

    int created = 0;
    int skipped = 0;

    // ✅ Проверяем какие из них уже есть в БД
    for (var categoryId in targetCategoryIds) {
      try {
        final exists = _categories.any((c) => c['id'] == categoryId);

        if (exists) {
          skipped++;
          final existingCat =
              _categories.firstWhere((c) => c['id'] == categoryId);
          if (kDebugMode)
            print('   ⏭️ Уже есть: ID $categoryId - "${existingCat['name']}"');
        } else {
          // Категория из маппинга отсутствует в БД - это ошибка!
          if (kDebugMode)
            print(
                '   ⚠️ ПРОБЛЕМА: Категория ID $categoryId из маппинга НЕ НАЙДЕНА в БД!');
          if (kDebugMode)
            print('   💡 Нужно либо создать её вручную, либо обновить маппинг');
        }
      } catch (e) {
        if (kDebugMode)
          print('   ⚠️ Ошибка проверки категории ID $categoryId: $e');
      }
    }

    if (kDebugMode)
      print(
          '📊 ИТОГО: Проверено: ${targetCategoryIds.length}, Существует: $skipped, Отсутствует: ${targetCategoryIds.length - skipped}');

    // ✅ Не создаём никаких новых категорий - только используем существующие!
    return 0;
  }

  /// ✨ НОВЫЙ МЕТОД: Обогащение товаров категориями из БД
  Future<List<Map<String, dynamic>>> _enrichProductsWithCategories(
    List<Map<String, dynamic>> products, {
    bool useMappings = true, // ← ДОБАВЬ ЭТИ
    Map<String, Map<String, dynamic>>? mappings, // ← ТРИ СТРОКИ
  }) async {
    if (kDebugMode) print('\n🔗 Обогащение товаров категориями с маппингом...');

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
        if (kDebugMode) print('🧪 ТЕСТ для "- Пирожные, десерты, пончики":');
        if (kDebugMode) print('   useMappings = $useMappings');
        if (kDebugMode) print('   mappings != null = ${mappings != null}');
        if (kDebugMode) print('   mappings.length = ${mappings?.length}');
        if (kDebugMode) print('   excelCategory = "$excelCategory"');
      }

      // 1. Сначала пытаемся использовать маппинг
      // 1. Сначала пытаемся использовать маппинг
      String? saleType;
      if (useMappings && mappings != null && excelCategory != null) {
        final mapping = CategoryMappingService.findMapping(
          excelCategory,
          mappings,
        );

        if (mapping != null) {
          categoryId = mapping['categoryId'] as int?;
          saleType = mapping['saleType'] as String?;
          mappedCount++;
          if (kDebugMode)
            print(
                '   ✅ Маппинг: "$excelCategory" → категория #$categoryId, saleType=$saleType');
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
          if (kDebugMode) print('   ⚠️ НЕ СМАППИЛОСЬ: "$excelCategory"');
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
        'suggestedCategoryName': categoryName,
        'originalCategory': excelCategory,
        'saleType': saleType ?? 'поштучно', // ← ДОБАВИТЬ ЭТУ СТРОКУ
      });
    }

    if (kDebugMode) print('   ✅ Смаппировано: $mappedCount');
    if (kDebugMode) print('   🎯 Точное совпадение: $exactMatchCount');
    if (kDebugMode) print('   ⚠️ Без категории: $unmappedCount');

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

  /// Переключает тип продажи товара (поштучно / только уп)
  Future<void> _toggleProductSaleType(Map<String, dynamic> product, bool isPackage) async {
    final productId = product['id'] as int;
    final newSaleType = isPackage ? 'только уп' : 'поштучно';

    try {
      await _apiService.updateProduct(productId, {
        'saleType': newSaleType,
      });

      // Обновляем локально
      setState(() {
        final index = _existingProducts.indexWhere((p) => p['id'] == productId);
        if (index != -1) {
          _existingProducts[index]['saleType'] = newSaleType;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Товар "${product['name']}" → ${isPackage ? "упаковками" : "поштучно"}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        if (kDebugMode) print('Начинаем удаление товара ID: ${product['id']}');

        // Вызываем API для удаления
        await _apiService.deleteProduct(product['id']);

        if (kDebugMode) print('Товар успешно удален с сервера');

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
        if (kDebugMode) print('Ошибка удаления товара: $e');

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
      if (kDebugMode) print('Начинаем удаление ВСЕХ товаров');

      final response = await _apiService.deleteAllProducts();

      // Закрываем индикатор загрузки
      Navigator.pop(context);

      if (kDebugMode) print('Результат: ${response}');

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

      if (kDebugMode) print('Ошибка удаления всех товаров: $e');

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
                          // Индикатор немаппированных категорий
                          if (_getUnmappedCategoriesCount() > 0) ...[
                            SizedBox(height: 8),
                            InkWell(
                              onTap: _showUnmappedCategoriesDialog,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber, size: 18, color: Colors.orange[800]),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Без категории: ${_getUnmappedProductsCount()} товаров (${_getUnmappedCategoriesCount()} категорий)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[900],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange[700]),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // ✅ ДОБАВИТЬ: Поле поиска
                  if (_parsedItems.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _parsedSearchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск товара по названию...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: _parsedSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    _parsedSearchController.clear();
                                    _searchAndScrollToProduct('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: _searchAndScrollToProduct,
                        onChanged: (value) {
                          // Отменяем предыдущий таймер
                          _searchDebounce?.cancel();

                          // Запускаем новый с задержкой 300мс
                          _searchDebounce =
                              Timer(Duration(milliseconds: 300), () {
                            if (value.length >= 3) {
                              _searchAndScrollToProduct(value);
                            } else if (value.isEmpty) {
                              setState(() => _highlightedIndex = null);
                            }
                          });
                        },
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
                            : ScrollablePositionedList.builder(
                                itemScrollController: _itemScrollController,
                                itemPositionsListener: _itemPositionsListener,
                                itemCount: _parsedItems.length,
                                addAutomaticKeepAlives: false,
                                itemBuilder: (context, index) {
                                  final item = _parsedItems[index];
                                  // Проверяем, есть ли товар в базе
                                  final itemName = _normalizeProductName(item['name'] ?? '');
                                  final isNewProduct = !_existingProducts.any((p) =>
                                      _normalizeProductName(p['name'] ?? '') == itemName);
                                  return ParsedProductTile(
                                    item: item,
                                    index: index,
                                    isSelected:
                                        _selectedIndices.contains(index),
                                    isHighlighted: _highlightedIndex == index,
                                    isNew: isNewProduct,
                                    onToggleSelect: () {
                                      setState(() {
                                        if (_selectedIndices.contains(index)) {
                                          _selectedIndices.remove(index);
                                        } else {
                                          _selectedIndices.add(index);
                                        }
                                      });
                                    },
                                    onEdit: () => _editItem(index),
                                    onRemove: () =>
                                        _removeFromParsedList(index),
                                    onAdd: () => _addToDatabase(item),
                                    onToggleSaleType: () {
                                      setState(() {
                                        item['saleType'] =
                                            (item['saleType'] ?? 'поштучно') ==
                                                    'поштучно'
                                                ? 'только уп'
                                                : 'поштучно';
                                      });
                                    },
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
                          SizedBox(width: 8),
                          // Новая кнопка "Сравнить с базой"
                          ElevatedButton.icon(
                            onPressed: _parsedItems.isEmpty
                                ? null
                                : _showCompareWithDatabaseDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            icon: Icon(Icons.compare_arrows),
                            label: Text('Сравнить с базой'),
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
                                // DEBUG: посмотреть что приходит
                                if (kDebugMode && index < 3) {
                                  print('Product ${product['id']}: saleType = "${product['saleType']}"');
                                }
                                final isPackage = product['saleType'] == 'только уп';
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  color: Colors.green[50],
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        // ID товара
                                        SizedBox(
                                          width: 50,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.green[200],
                                            radius: 16,
                                            child: Text(
                                              '${product['id']}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Название и цена
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['name'] ?? '',
                                                style: TextStyle(fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${product['price']} ₽ / ${product['unit'] ?? 'шт'}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                              ),
                                              if (product['category'] != null)
                                                Text(
                                                  product['category']['name'],
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.green[700],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Бейдж типа продажи (кликабельный)
                                        GestureDetector(
                                          onTap: () => _toggleProductSaleType(product, !isPackage),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isPackage ? Colors.orange[100] : Colors.blue[100],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isPackage ? Colors.orange[300]! : Colors.blue[300]!,
                                              ),
                                            ),
                                            child: Text(
                                              isPackage ? 'Только уп' : 'Поштучно',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isPackage ? Colors.orange[800] : Colors.blue[800],
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        // Кнопка удаления
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red[400],
                                            size: 20,
                                          ),
                                          onPressed: () => _deleteProduct(product),
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                        SizedBox(width: 8),
                                      ],
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
