// lib/screens/add_product_screen.dart - ПОЛНЫЙ ФАЙЛ

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/admin_api_service.dart';

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
  List<Map<String, dynamic>> _existingProducts = [];
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
    await _loadExistingProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.getCategories();
      setState(() {
        _categories =
            List<Map<String, dynamic>>.from(response['categories'] ?? []);
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
        _existingProducts =
            List<Map<String, dynamic>>.from(response['products'] ?? []);
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
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _isLoading = true;
          _error = null;
        });

        print('Файл выбран: ${_selectedFile!.name}');
        print('Путь к файлу: ${_selectedFile!.path}');

        // Отправляем файл на сервер для парсинга
        try {
          final response =
              await _apiService.parseProductFile(_selectedFile!.path!);
          print('Ответ сервера: $response');

          setState(() {
            _parsedItems =
                List<Map<String, dynamic>>.from(response['items'] ?? []);
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
        content: Text('Будет добавлено ${_parsedItems.length} товаров'),
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

              for (var item in [..._parsedItems]) {
                try {
                  // Проверяем что categoryId существует
                  final categoryExists = _categories
                      .any((cat) => cat['id'] == item['suggestedCategoryId']);

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
                });
              }

              if (mounted) {
                // Проверяем что виджет еще существует
                String message = successCount > 0
                    ? 'Добавлено товаров: $successCount'
                    : 'Не удалось добавить товары';

                if (errorCount > 0) {
                  message += ', ошибок: $errorCount';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor:
                        errorCount > 0 ? Colors.orange : Colors.green,
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

  void _deleteProduct(Map<String, dynamic> product) {
    showDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _apiService.deleteProduct(product['id']);

                // Обновляем список товаров
                await _loadExistingProducts();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Товар "${product['name']}" удален'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Ошибка удаления товара: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка удаления товара'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
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
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!),
                ),
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
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickAndProcessFile,
                          icon: Icon(Icons.upload_file),
                          label: Text('Загрузить файл (CSV/TXT)'),
                        ),
                        if (_selectedFile != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Файл: ${_selectedFile!.name}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
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
                                    child: ListTile(
                                      title: Text(item['name'] ?? ''),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Цена: ${item['price']} ₽ / ${item['unit']}'),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item['suggestedCategoryName'] ??
                                                  'Без категории',
                                              style: TextStyle(fontSize: 12),
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
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _addToDatabase(item),
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
                          Text('Товаров: ${_parsedItems.length}'),
                          Spacer(),
                          ElevatedButton(
                            onPressed: _addAllToDatabase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: Text('Добавить все'),
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
                                  )),
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
                                            'Цена: ${product['price']} ₽ / ${product['unit'] ?? 'шт'}'),
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
                                      icon: Icon(Icons.delete,
                                          color: Colors.red[400]),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 16, color: Colors.green[700]),
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
    _priceController =
        TextEditingController(text: widget.product['price'].toString());
    _unitController = TextEditingController(text: widget.product['unit']);
    _descriptionController =
        TextEditingController(text: widget.product['description'] ?? '');
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
                          content: Text('Категория "$categoryName" создана')),
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
                                  ))
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
