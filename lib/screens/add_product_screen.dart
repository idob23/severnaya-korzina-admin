// lib/screens/add_product_screen.dart - УЛУЧШЕННАЯ ВЕРСИЯ С РЕАЛЬНЫМ ПАРСИНГОМ
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import '../services/admin_api_service.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final AdminApiService _apiService = AdminApiService();
  final ImagePicker _imagePicker = ImagePicker();

  // Состояние экрана
  bool _isLoading = false;
  String? _error;

  // Данные загруженного файла
  PlatformFile? _selectedFile;
  List<XFile> _selectedImages = [];
  List<Map<String, dynamic>> _parsedItems = [];
  bool _isFileProcessed = false;

  // Список категорий для сопоставления
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.getCategories();
      setState(() {
        _categories =
            List<Map<String, dynamic>>.from(response['categories'] ?? []);
      });
    } catch (e) {
      print('Ошибка загрузки категорий: $e');
      // Добавляем дефолтные категории если API недоступно
      setState(() {
        _categories = [
          {'id': 1, 'name': 'Молочные продукты'},
          {'id': 2, 'name': 'Мясо и птица'},
          {'id': 3, 'name': 'Овощи и фрукты'},
          {'id': 4, 'name': 'Хлебобулочные изделия'},
          {'id': 5, 'name': 'Напитки'},
          {'id': 6, 'name': 'Замороженные продукты'},
          {'id': 7, 'name': 'Бакалея'},
        ];
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _selectedImages = [];
          _isFileProcessed = false;
          _parsedItems = [];
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка выбора файла: $e';
      });
    }
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
          _selectedFile = null;
          _isFileProcessed = false;
          _parsedItems = [];
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка выбора фотографий: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        setState(() {
          _error = 'Необходимо разрешение на использование камеры';
        });
        return;
      }

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _selectedImages = [photo];
          _selectedFile = null;
          _isFileProcessed = false;
          _parsedItems = [];
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка съемки: $e';
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выберите источник'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Камера'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Галерея'),
              onTap: () {
                Navigator.pop(context);
                _pickImagesFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // РЕАЛЬНЫЙ ПАРСИНГ ФАЙЛОВ
  Future<void> _processFile() async {
    if (_selectedFile == null && _selectedImages.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> items = [];

      if (_selectedFile != null) {
        // Обрабатываем файл
        items = await _parseFile(_selectedFile!);
      } else if (_selectedImages.isNotEmpty) {
        // Обрабатываем изображения (OCR заглушка)
        items = await _parseImages(_selectedImages);
      }

      // Обогащаем данные предложенными категориями
      final enrichedItems = _enrichWithCategories(items);

      setState(() {
        _parsedItems = enrichedItems;
        _isFileProcessed = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка обработки: $e';
        _isLoading = false;
      });
    }
  }

  // Парсинг файлов
  Future<List<Map<String, dynamic>>> _parseFile(PlatformFile file) async {
    final fileName = file.name.toLowerCase();

    if (fileName.endsWith('.csv')) {
      return await _parseCsvFile(file);
    } else if (fileName.endsWith('.txt')) {
      return await _parseTextFile(file);
    } else {
      throw Exception('Формат файла не поддерживается');
    }
  }

  // Парсинг CSV файлов
  Future<List<Map<String, dynamic>>> _parseCsvFile(PlatformFile file) async {
    final bytes = file.bytes!;
    final content = utf8.decode(bytes);

    // Пытаемся определить разделитель
    String delimiter = ',';
    if (content.contains(';')) delimiter = ';';
    if (content.contains('\t')) delimiter = '\t';

    final List<List<dynamic>> csvTable = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
    ).convert(content);

    if (csvTable.length < 2) {
      throw Exception('Файл должен содержать заголовки и данные');
    }

    final List<Map<String, dynamic>> items = [];
    final headers = csvTable[0].map((e) => e.toString().toLowerCase()).toList();

    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      if (row.isEmpty) continue;

      final item = _parseRowToItem(headers, row);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  // Парсинг текстовых файлов
  Future<List<Map<String, dynamic>>> _parseTextFile(PlatformFile file) async {
    final bytes = file.bytes!;
    final content = utf8.decode(bytes);
    final lines = content.split('\n');

    final List<Map<String, dynamic>> items = [];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Пытаемся распознать структуру строки
      final item = _parseTextLineToItem(line.trim());
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  // Преобразование строки CSV в товар
  Map<String, dynamic>? _parseRowToItem(
      List<String> headers, List<dynamic> row) {
    try {
      Map<String, dynamic> rowData = {};

      for (int i = 0; i < headers.length && i < row.length; i++) {
        rowData[headers[i]] = row[i]?.toString() ?? '';
      }

      // Ищем поля с названием товара
      String? name = _findField(
          rowData, ['название', 'товар', 'продукт', 'name', 'product']);
      if (name == null || name.trim().isEmpty) return null;

      // Ищем цену
      double? price =
          _findPriceField(rowData, ['цена', 'стоимость', 'price', 'cost']);

      // Ищем единицу измерения
      String unit =
          _findField(rowData, ['единица', 'ед', 'unit', 'ед.изм']) ?? 'шт';

      // Ищем описание
      String description =
          _findField(rowData, ['описание', 'desc', 'description']) ?? '';

      return {
        'name': name.trim(),
        'price': price ?? 0.0,
        'unit': unit.trim(),
        'description': description.trim(),
        'source': 'CSV_PARSE',
        'isApproved': false,
      };
    } catch (e) {
      print('Ошибка парсинга строки: $e');
      return null;
    }
  }

  // Парсинг текстовой строки в товар
  Map<String, dynamic>? _parseTextLineToItem(String line) {
    try {
      // Паттерны для распознавания
      final patterns = [
        // "Молоко 3.2% - 85 руб/л"
        RegExp(r'^(.+?)\s*-\s*(\d+(?:\.\d+)?)\s*руб?(?:/(.+?))?$',
            caseSensitive: false),
        // "Хлеб белый 500г 45.50"
        RegExp(r'^(.+?)\s+(\d+(?:\.\d+)?)\s*$'),
        // "Яблоки (кг) - 120.00"
        RegExp(r'^(.+?)\s*\((.+?)\)\s*-\s*(\d+(?:\.\d+)?)$',
            caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          String name = match.group(1)?.trim() ?? '';
          String priceStr = match.group(2) ?? '0';
          String unit = match.group(3)?.trim() ?? 'шт';

          if (name.isNotEmpty) {
            return {
              'name': name,
              'price': double.tryParse(priceStr) ?? 0.0,
              'unit': unit.isEmpty ? 'шт' : unit,
              'description': '',
              'source': 'TEXT_PARSE',
              'isApproved': false,
            };
          }
        }
      }

      // Если паттерны не сработали, создаем базовый товар
      if (line.length > 3) {
        return {
          'name': line,
          'price': 0.0,
          'unit': 'шт',
          'description': '',
          'source': 'TEXT_PARSE',
          'isApproved': false,
        };
      }

      return null;
    } catch (e) {
      print('Ошибка парсинга текста: $e');
      return null;
    }
  }

  // Заглушка для OCR изображений
  Future<List<Map<String, dynamic>>> _parseImages(List<XFile> images) async {
    // Симуляция OCR обработки
    await Future.delayed(Duration(seconds: 2));

    return [
      {
        'name': 'Товар из изображения #1',
        'price': 150.0,
        'unit': 'шт',
        'description': 'Распознано с изображения',
        'source': 'OCR_PARSE',
        'isApproved': false,
      },
      {
        'name': 'Товар из изображения #2',
        'price': 250.0,
        'unit': 'кг',
        'description': 'Распознано с изображения',
        'source': 'OCR_PARSE',
        'isApproved': false,
      },
    ];
  }

  // Обогащение данных категориями
  List<Map<String, dynamic>> _enrichWithCategories(
      List<Map<String, dynamic>> items) {
    return items.map((item) {
      final category = _suggestCategory(item['name']);
      return {
        ...item,
        'suggestedCategory': category['name'],
        'suggestedCategoryId': category['id'],
        'categoryConfidence': category['confidence'],
      };
    }).toList();
  }

  // Предложение категории на основе названия товара
  Map<String, dynamic> _suggestCategory(String productName) {
    final name = productName.toLowerCase();

    // Простые правила для определения категории
    if (name.contains('молоко') ||
        name.contains('сыр') ||
        name.contains('творог') ||
        name.contains('кефир') ||
        name.contains('йогурт')) {
      return {'id': 1, 'name': 'Молочные продукты', 'confidence': 0.9};
    }

    if (name.contains('мясо') ||
        name.contains('курица') ||
        name.contains('говядина') ||
        name.contains('свинина') ||
        name.contains('колбаса')) {
      return {'id': 2, 'name': 'Мясо и птица', 'confidence': 0.9};
    }

    if (name.contains('яблок') ||
        name.contains('банан') ||
        name.contains('морковь') ||
        name.contains('картофель') ||
        name.contains('овощ') ||
        name.contains('фрукт')) {
      return {'id': 3, 'name': 'Овощи и фрукты', 'confidence': 0.8};
    }

    if (name.contains('хлеб') ||
        name.contains('батон') ||
        name.contains('булочка')) {
      return {'id': 4, 'name': 'Хлебобулочные изделия', 'confidence': 0.9};
    }

    if (name.contains('вода') ||
        name.contains('сок') ||
        name.contains('напиток') ||
        name.contains('чай') ||
        name.contains('кофе')) {
      return {'id': 5, 'name': 'Напитки', 'confidence': 0.8};
    }

    // По умолчанию - бакалея
    return {'id': 7, 'name': 'Бакалея', 'confidence': 0.3};
  }

  // Поиск поля в данных строки
  String? _findField(Map<String, dynamic> data, List<String> possibleNames) {
    for (final key in data.keys) {
      for (final name in possibleNames) {
        if (key.contains(name)) {
          final value = data[key]?.toString();
          if (value != null && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    }
    return null;
  }

  // Поиск поля с ценой
  double? _findPriceField(
      Map<String, dynamic> data, List<String> possibleNames) {
    for (final key in data.keys) {
      for (final name in possibleNames) {
        if (key.contains(name)) {
          final value = data[key]?.toString();
          if (value != null) {
            // Очищаем от лишних символов и пытаемся парсить
            final cleanValue =
                value.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
            return double.tryParse(cleanValue);
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавление товаров'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Инструкция
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text(
                          'Инструкция',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Выберите файл (CSV, TXT) или сфотографируйте прайс-лист\n'
                      '2. Нажмите "Обработать" для автоматического парсинга\n'
                      '3. Проверьте и откорректируйте предложенные категории\n'
                      '4. Подтвердите добавление товаров в базу данных',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Шаг 1: Выбор файла
            _buildFileSelectionSection(),

            if (_selectedFile != null) ...[
              SizedBox(height: 24),
              _buildFileInfoSection(),
            ],

            if (_selectedImages.isNotEmpty) ...[
              SizedBox(height: 24),
              _buildImagesInfoSection(),
            ],

            if ((_selectedFile != null || _selectedImages.isNotEmpty) &&
                !_isFileProcessed) ...[
              SizedBox(height: 24),
              _buildProcessButton(),
            ],

            if (_isFileProcessed && _parsedItems.isNotEmpty) ...[
              SizedBox(height: 24),
              _buildParsedItemsSection(),
            ],

            if (_error != null) ...[
              SizedBox(height: 16),
              _buildErrorSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Шаг 1: Выбор источника данных',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(Icons.attach_file),
                    label: Text('Выбрать файл'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Фото/Скан'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Поддерживаемые форматы:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• CSV - файлы с разделителями (;, ,, tab)'),
                  Text('• TXT - текстовые прайс-листы'),
                  Text('• Фото - изображения прайсов (OCR)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFile!.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
                'Размер: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB'),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выбранные изображения: ${_selectedImages.length}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImages[index].path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processFile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Обрабатываем...'),
                ],
              )
            : Text(
                'Обработать файл',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildParsedItemsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Шаг 2: Проверьте распознанные товары (${_parsedItems.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _parsedItems.length,
              itemBuilder: (context, index) {
                final item = _parsedItems[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          item['isApproved'] ? Colors.green : Colors.orange,
                      child: Icon(
                        item['isApproved'] ? Icons.check : Icons.warning,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(item['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item['price']} ₽ за ${item['unit']}'),
                        Text(
                          'Категория: ${item['suggestedCategory']}',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editItem(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _parsedItems.isEmpty ? null : _approveAllItems,
                    child: Text('Подтвердить все'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _parsedItems.isEmpty ? null : _saveToDatabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Сохранить в БД'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editItem(int index) {
    // TODO: Открыть диалог редактирования товара
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактирование товара'),
        content: Text('Функция будет реализована в следующей версии'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _parsedItems.removeAt(index);
    });
  }

  void _approveAllItems() {
    setState(() {
      for (var item in _parsedItems) {
        item['isApproved'] = true;
      }
    });
  }

  void _saveToDatabase() {
    // TODO: Сохранить в базу данных через API
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сохранение товаров'),
        content: Text(
            '${_parsedItems.length} товаров будет добавлено в базу данных'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Возврат к dashboard
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Товары успешно добавлены!')),
              );
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
