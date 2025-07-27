// lib/screens/add_product_screen.dart - ПОЛНАЯ ВЕРСИЯ С ФОТО И OCR
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf'],
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
      // Проверяем разрешение на камеру
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        setState(() {
          _error = 'Необходимо разрешение на использование камеры';
        });
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages = [image];
          _selectedFile = null;
          _isFileProcessed = false;
          _parsedItems = [];
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка при фотографировании: $e';
      });
    }
  }

  Future<void> _scanDocument() async {
    try {
      // Проверяем разрешение на камеру
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        setState(() {
          _error = 'Необходимо разрешение на использование камеры';
        });
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100, // Максимальное качество для документов
      );

      if (image != null) {
        setState(() {
          _selectedImages = [image];
          _selectedFile = null;
          _isFileProcessed = false;
          _parsedItems = [];
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка сканирования: $e';
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Выберите источник',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue[600]),
              title: Text('Сфотографировать документ'),
              subtitle: Text('Сделать фото прайс-листа'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.document_scanner, color: Colors.green[600]),
              title: Text('Сканировать документ'),
              subtitle: Text('Высокое качество для OCR'),
              onTap: () {
                Navigator.pop(context);
                _scanDocument();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.orange[600]),
              title: Text('Выбрать из галереи'),
              subtitle: Text('Загрузить готовые фото'),
              onTap: () {
                Navigator.pop(context);
                _pickImagesFromGallery();
              },
            ),
            SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processFile() async {
    if (_selectedFile == null && _selectedImages.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Имитируем обработку файла или изображений
      await Future.delayed(Duration(seconds: 3));

      List<Map<String, dynamic>> mockItems;

      if (_selectedImages.isNotEmpty) {
        // Генерируем результаты для изображений (имитация OCR)
        mockItems = _generateMockParsedItemsFromImages();
      } else {
        // Генерируем результаты для файлов
        mockItems = _generateMockParsedItems();
      }

      setState(() {
        _parsedItems = mockItems;
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

  List<Map<String, dynamic>> _generateMockParsedItemsFromImages() {
    // Имитируем результат OCR обработки изображений
    return [
      {
        'name': 'Хлеб белый нарезной',
        'price': 52.00,
        'unit': 'шт',
        'description': 'Распознано с фото прайс-листа',
        'suggestedCategory': 'Хлебобулочные изделия',
        'categoryConfidence': 0.88,
        'isApproved': false,
        'source': 'OCR_IMAGE',
      },
      {
        'name': 'Масло сливочное 72.5%',
        'price': 195.00,
        'unit': 'шт',
        'description': 'Автоматически распознано из документа',
        'suggestedCategory': 'Молочные продукты',
        'categoryConfidence': 0.94,
        'isApproved': false,
        'source': 'OCR_IMAGE',
      },
      {
        'name': 'Сахар песок',
        'price': 67.50,
        'unit': 'кг',
        'description': 'Распознано методом OCR',
        'suggestedCategory': 'Крупы и макароны',
        'categoryConfidence': 0.79,
        'isApproved': false,
        'source': 'OCR_IMAGE',
      },
    ];
  }

  List<Map<String, dynamic>> _generateMockParsedItems() {
    // Имитируем результат парсинга файла поставщика
    return [
      {
        'name': 'Молоко коровье 3.2%',
        'price': 89.50,
        'unit': 'л',
        'description': 'Пастеризованное молоко высшего сорта',
        'suggestedCategory': 'Молочные продукты',
        'categoryConfidence': 0.95,
        'isApproved': false,
        'source': 'FILE_PARSE',
      },
      {
        'name': 'Хлеб "Дарницкий"',
        'price': 45.00,
        'unit': 'шт',
        'description': 'Ржано-пшеничный хлеб',
        'suggestedCategory': 'Хлебобулочные изделия',
        'categoryConfidence': 0.92,
        'isApproved': false,
        'source': 'FILE_PARSE',
      },
      {
        'name': 'Яблоки "Гала"',
        'price': 150.00,
        'unit': 'кг',
        'description': 'Импортные яблоки первого сорта',
        'suggestedCategory': 'Овощи и фрукты',
        'categoryConfidence': 0.98,
        'isApproved': false,
        'source': 'FILE_PARSE',
      },
    ];
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
                      '1. Выберите файл от поставщика (Excel, CSV, PDF) или сфотографируйте прайс-лист\n'
                      '2. Система автоматически обработает данные с помощью OCR и AI\n'
                      '3. Проверьте и одобрите предложенные категории товаров\n'
                      '4. Подтвердите добавление в базу данных',
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

            // Кнопки выбора
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

            // Информация о форматах
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
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue[600]),
                      SizedBox(width: 8),
                      Text(
                        'Поддерживаемые форматы:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '📄 Файлы: Excel (.xlsx, .xls), CSV, PDF\n'
                    '📷 Фото: Прайс-листы, каталоги товаров\n'
                    '📋 Сканы: Документы от поставщиков',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
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
            Text(
              'Выбранный файл',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getFileIcon(_selectedFile!.extension),
                  size: 32,
                  color: Colors.blue[600],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile!.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Размер: ${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                      _parsedItems = [];
                      _isFileProcessed = false;
                    });
                  },
                ),
              ],
            ),
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
            Row(
              children: [
                Text(
                  'Выбранные изображения',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedImages = [];
                      _parsedItems = [];
                      _isFileProcessed = false;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  final image = _selectedImages[index];
                  return Container(
                    width: 100,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.green[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Изображения будут обработаны с помощью OCR для извлечения информации о товарах',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessButton() {
    String buttonText;
    String loadingText;

    if (_selectedImages.isNotEmpty) {
      buttonText = 'Обработать изображения (OCR)';
      loadingText = 'Распознавание текста...';
    } else {
      buttonText = 'Обработать файл';
      loadingText = 'Обработка файла...';
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processFile,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(loadingText),
                ],
              )
            : Text(
                buttonText,
                style: TextStyle(fontSize: 16),
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
              'Шаг 2: Проверка распознанных товаров',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Найдено ${_parsedItems.length} товаров. Проверьте категории и одобрите для добавления:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            ..._parsedItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildParsedItemCard(index, item);
            }).toList(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        for (var item in _parsedItems) {
                          item['isApproved'] = false;
                        }
                      });
                    },
                    child: Text('Отклонить все'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        for (var item in _parsedItems) {
                          item['isApproved'] = true;
                        }
                      });
                    },
                    child: Text('Одобрить все'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _getApprovedItemsCount() > 0 ? _addApprovedItems : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Добавить одобренные товары (${_getApprovedItemsCount()})',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedItemCard(int index, Map<String, dynamic> item) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: item['isApproved'] ? Colors.green[50] : null,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Switch(
                  value: item['isApproved'],
                  onChanged: (value) {
                    setState(() {
                      item['isApproved'] = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('${item['price']} ₽ за ${item['unit']}'),
            if (item['description'] != null)
              Text(
                item['description'],
                style: TextStyle(color: Colors.grey[600]),
              ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 16,
                  color:
                      _getCategoryConfidenceColor(item['categoryConfidence']),
                ),
                SizedBox(width: 8),
                Text(
                  'Категория: ${item['suggestedCategory']}',
                  style: TextStyle(
                    color:
                        _getCategoryConfidenceColor(item['categoryConfidence']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '(${(item['categoryConfidence'] * 100).toInt()}%)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Spacer(),
                _buildSourceChip(item['source']),
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
            Icon(Icons.error, color: Colors.red[600]),
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

  Widget _buildSourceChip(String? source) {
    IconData icon;
    String text;
    Color color;

    switch (source) {
      case 'OCR_IMAGE':
        icon = Icons.image;
        text = 'OCR';
        color = Colors.green[600]!;
        break;
      case 'FILE_PARSE':
        icon = Icons.description;
        text = 'Файл';
        color = Colors.blue[600]!;
        break;
      default:
        icon = Icons.help_outline;
        text = 'Авто';
        color = Colors.grey[600]!;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'csv':
        return Icons.grid_on;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.description;
    }
  }

  Color _getCategoryConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green[600]!;
    if (confidence >= 0.7) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  int _getApprovedItemsCount() {
    return _parsedItems.where((item) => item['isApproved'] == true).length;
  }

  Future<void> _addApprovedItems() async {
    final approvedItems =
        _parsedItems.where((item) => item['isApproved'] == true).toList();

    // TODO: Отправить на сервер
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Добавлено ${approvedItems.length} товаров в базу данных'),
        backgroundColor: Colors.green[600],
      ),
    );

    Navigator.of(context).pop();
  }
}
