// lib/screens/add_product_screen.dart - НОВЫЙ ЭКРАН ДОБАВЛЕНИЯ ТОВАРОВ
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/admin_api_service.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final AdminApiService _apiService = AdminApiService();

  // Состояние экрана
  bool _isLoading = false;
  String? _error;

  // Данные загруженного файла
  PlatformFile? _selectedFile;
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

  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Имитируем обработку файла
      await Future.delayed(Duration(seconds: 2));

      // Генерируем тестовые данные
      final mockItems = _generateMockParsedItems();

      setState(() {
        _parsedItems = mockItems;
        _isFileProcessed = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка обработки файла: $e';
        _isLoading = false;
      });
    }
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
      },
      {
        'name': 'Хлеб "Дарницкий"',
        'price': 45.00,
        'unit': 'шт',
        'description': 'Ржано-пшеничный хлеб',
        'suggestedCategory': 'Хлебобулочные изделия',
        'categoryConfidence': 0.92,
        'isApproved': false,
      },
      {
        'name': 'Яблоки "Гала"',
        'price': 150.00,
        'unit': 'кг',
        'description': 'Импортные яблоки первого сорта',
        'suggestedCategory': 'Овощи и фрукты',
        'categoryConfidence': 0.98,
        'isApproved': false,
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
                      '1. Выберите файл от поставщика (Excel, CSV или PDF)\n'
                      '2. Система автоматически обработает и распознает товары\n'
                      '3. Проверьте и одобрите предложенные категории\n'
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

            if (_selectedFile != null && !_isFileProcessed) ...[
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
              'Шаг 1: Выбор файла',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Colors.blue[600],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Выберите файл от поставщика',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Поддерживаемые форматы: Excel (.xlsx, .xls), CSV, PDF',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildProcessButton() {
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
                  Text('Обработка файла...'),
                ],
              )
            : Text(
                'Обработать файл',
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
