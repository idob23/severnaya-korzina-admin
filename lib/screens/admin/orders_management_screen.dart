// lib/screens/admin/orders_management_screen.dart - ИСПРАВЛЕННАЯ ВЕРСИЯ
// Убираем confirmed, импортируем константы

import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../constants/order_status.dart'; // ← ИМПОРТИРУЕМ КОНСТАНТЫ

class OrdersManagementScreen extends StatefulWidget {
  @override
  _OrdersManagementScreenState createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _orders = [];
  Map<String, dynamic>? _activeBatch;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  // Для редактирования названия закупки
  bool _isEditingTitle = false;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 Загружаем данные...');

      // Загружаем заказы и активную закупку параллельно
      final results = await Future.wait([
        _apiService.getOrders(),
        _apiService.getActiveBatch(),
      ]);

      print('📦 Заказы получены: ${results[0]}');
      print('🛒 Активная закупка: ${results[1]}');

      final batchData = results[1]['batch'];
      print('🔍 Детали активной партии: $batchData');

      setState(() {
        _orders = _safeList(results[0]['orders']);
        _activeBatch = _safeMap(batchData); // Используем batchData напрямую
        _isLoading = false;
      });

      print('✅ Данные загружены. Заказов: ${_orders.length}');
      print(
          '✅ Активная партия: ${_activeBatch != null ? "есть (${_activeBatch!['title']})" : "нет"}');
    } catch (e) {
      print('❌ Ошибка загрузки: $e');
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  // Безопасные методы для работы с данными
  List<dynamic> _safeList(dynamic value) {
    if (value is List) return value;
    return [];
  }

  Map<String, dynamic>? _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  String _safeString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  int _safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return defaultValue;
  }

  double _safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return defaultValue;
  }

  List<dynamic> get _filteredOrders {
    switch (_selectedFilter) {
      case 'current_batch':
        if (_activeBatch == null) return [];
        final batchId = _activeBatch!['id'];
        return _orders.where((order) => order['batchId'] == batchId).toList();
      case 'no_batch':
        return _orders.where((order) => order['batchId'] == null).toList();
      default:
        return _orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Информационная панель
          if (_activeBatch != null) _buildActiveBatchPanel(),

          // Фильтры
          _buildFilters(),

          // Список заказов
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBatchPanel() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.blue[700]),
              SizedBox(width: 8),
              Expanded(
                child: _isEditingTitle
                    ? TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onSubmitted: _saveTitle,
                      )
                    : GestureDetector(
                        onTap: _startEditingTitle,
                        child: Text(
                          '${_safeString(_activeBatch!['title'])}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
              ),
              if (_isEditingTitle) ...[
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () => _saveTitle(_titleController.text),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: _cancelEditing,
                ),
              ] else
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue[700]),
                  onPressed: _startEditingTitle,
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Собрано: ${_safeDouble(_activeBatch!['currentAmount']).toStringAsFixed(0)}₽ из ${_safeDouble(_activeBatch!['targetAmount']).toStringAsFixed(0)}₽',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ),
              Text(
                '${_safeDouble(_activeBatch!['progressPercent']).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: _safeDouble(_activeBatch!['progressPercent']) / 100,
            backgroundColor: Colors.blue[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Фильтр:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Все заказы'),
                  SizedBox(width: 8),
                  _buildFilterChip('current_batch', 'Текущая закупка'),
                  SizedBox(width: 8),
                  _buildFilterChip('no_batch', 'Без закупки'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: isSelected ? Colors.blue[100] : null,
      selectedColor: Colors.blue[200],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(_error!),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _selectedFilter == 'current_batch'
                  ? 'Нет заказов в текущей закупке'
                  : _selectedFilter == 'no_batch'
                      ? 'Нет заказов без закупки'
                      : 'Нет заказов',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final user = _safeMap(order['user']) ?? {};
    final address = _safeMap(order['address']) ?? {};
    final batchId = order['batchId'];
    final isInCurrentBatch =
        _activeBatch != null && batchId == _activeBatch!['id'];

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок заказа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ #${_safeString(order['id'], '?')}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                        _safeString(order['status'], 'unknown')),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(_safeString(order['status'], 'unknown')),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Информация о пользователе
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    _safeString(user['firstName'], '?').isNotEmpty
                        ? _safeString(user['firstName'], '?')[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_safeString(user['firstName'], 'Имя')} ${_safeString(user['lastName'], '')}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _safeString(user['phone'], 'Телефон не указан'),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Принадлежность к закупке
            if (batchId != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isInCurrentBatch ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInCurrentBatch ? Icons.check_circle : Icons.history,
                      size: 16,
                      color: isInCurrentBatch
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                    SizedBox(width: 4),
                    Text(
                      isInCurrentBatch
                          ? 'Текущая закупка'
                          : 'Закупка #$batchId',
                      style: TextStyle(
                        fontSize: 12,
                        color: isInCurrentBatch
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ] else ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_circle_outline,
                        size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Без закупки',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],

            // Детали заказа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Сумма: ${_safeDouble(order['totalAmount']).toStringAsFixed(0)}₽',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  'Товаров: ${_safeInt(order['itemsCount'])}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            if (_safeString(address['title']).isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_safeString(address['title'])}: ${_safeString(address['address'])}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 8),
            Text(
              'Создан: ${_formatDate(_safeString(order['createdAt']))}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ИСПРАВЛЕНО: Используем константы вместо дублирования
  Color _getStatusColor(String status) {
    // Конвертируем строковые цвета в Color объекты
    final colorName = statusColors[status.toLowerCase()] ?? 'grey';
    switch (colorName) {
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ✅ ИСПРАВЛЕНО: Используем константы вместо дублирования
  String _getStatusText(String status) {
    // Сначала пробуем найти в константах заказов
    final orderStatus = statusTexts[status.toLowerCase()];
    if (orderStatus != null) {
      return orderStatus;
    }

    // Дополнительные статусы для партий (не заказов)
    switch (status.toLowerCase()) {
      case 'active':
        return 'Активная';
      case 'collecting':
        return 'Сбор средств';
      case 'ready':
        return 'Готова';
      case 'completed':
        return 'Завершена';
      default:
        return status;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Неизвестно';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  // Методы для редактирования названия закупки
  void _startEditingTitle() {
    setState(() {
      _isEditingTitle = true;
      _titleController.text = _safeString(_activeBatch!['title']);
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditingTitle = false;
      _titleController.clear();
    });
  }

  Future<void> _saveTitle(String newTitle) async {
    if (newTitle.trim().isEmpty) return;

    try {
      await _apiService.updateBatchTitle(
        _activeBatch!['id'],
        newTitle.trim(),
      );

      setState(() {
        _activeBatch!['title'] = newTitle.trim();
        _isEditingTitle = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Название закупки обновлено')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
