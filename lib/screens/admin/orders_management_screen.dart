// lib/screens/admin/orders_management_screen.dart - ПОЛНАЯ ВЕРСИЯ

import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';

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

      setState(() {
        _orders = _safeList(results[0]['orders']);
        _activeBatch = _safeMap(results[1]['batch']);
        _isLoading = false;
      });

      print('✅ Данные загружены. Заказов: ${_orders.length}');
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
      appBar: AppBar(
        title: Text('Управление заказами'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Информационная панель о текущей закупке
          if (_activeBatch != null) _buildBatchInfoCard(),

          // Фильтры заказов
          _buildFiltersBar(),

          // Список заказов
          Expanded(child: _buildOrdersList()),
        ],
      ),
    );
  }

  Widget _buildBatchInfoCard() {
    if (_activeBatch == null) return SizedBox.shrink();

    final batch = _activeBatch!;
    final currentBatchOrders =
        _orders.where((order) => order['batchId'] == batch['id']).length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.green[700]),
              SizedBox(width: 8),
              Expanded(
                child: _isEditingTitle
                    ? _buildTitleEditor()
                    : _buildTitleDisplay(),
              ),
              // Кнопка редактирования
              IconButton(
                icon: Icon(
                  _isEditingTitle ? Icons.check : Icons.edit,
                  color: Colors.green[700],
                  size: 20,
                ),
                onPressed:
                    _isEditingTitle ? _saveBatchTitle : _startEditingTitle,
                tooltip: _isEditingTitle ? 'Сохранить' : 'Изменить название',
              ),
              if (_isEditingTitle)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red[700], size: 20),
                  onPressed: _cancelEditingTitle,
                  tooltip: 'Отмена',
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Заказов в текущей закупке: $currentBatchOrders',
                style: TextStyle(color: Colors.green[700]),
              ),
              Text(
                'Статус: ${_getStatusText(_safeString(batch['status'], 'unknown'))}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Цель: ${_safeDouble(batch['targetAmount']).toStringAsFixed(0)}₽ | '
            'Текущее: ${_safeDouble(batch['currentAmount']).toStringAsFixed(0)}₽ | '
            'Прогресс: ${_safeInt(batch['progressPercent'])}%',
            style: TextStyle(color: Colors.green[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleDisplay() {
    return Text(
      'Текущая закупка: ${_safeString(_activeBatch!['title'], 'Без названия')}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.green[800],
      ),
    );
  }

  Widget _buildTitleEditor() {
    return TextField(
      controller: _titleController,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.green[800],
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green[700]!, width: 2),
        ),
      ),
      maxLines: 1,
      autofocus: true,
    );
  }

  void _startEditingTitle() {
    setState(() {
      _isEditingTitle = true;
      _titleController.text = _safeString(_activeBatch!['title'], '');
    });
  }

  void _cancelEditingTitle() {
    setState(() {
      _isEditingTitle = false;
      _titleController.clear();
    });
  }

  Future<void> _saveBatchTitle() async {
    final newTitle = _titleController.text.trim();

    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Название не может быть пустым'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Вызов API для обновления названия
      final response =
          await _apiService.updateBatchTitle(_activeBatch!['id'], newTitle);

      if (response['success'] == true) {
        setState(() {
          _activeBatch!['title'] = newTitle;
          _isEditingTitle = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Название закупки обновлено'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response['error'] ?? 'Неизвестная ошибка');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFiltersBar() {
    final activeBatchId = _activeBatch?['id'];
    final currentBatchCount = activeBatchId != null
        ? _orders.where((o) => o['batchId'] == activeBatchId).length
        : 0;
    final noBatchCount = _orders.where((o) => o['batchId'] == null).length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Фильтр: ', style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Все заказы', _orders.length),
                  SizedBox(width: 8),
                  if (_activeBatch != null)
                    _buildFilterChip(
                        'current_batch', 'Текущая закупка', currentBatchCount),
                  SizedBox(width: 8),
                  _buildFilterChip('no_batch', 'Без закупки', noBatchCount),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.blue[100],
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загружаем заказы...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Ошибка загрузки', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
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
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_safeString(user['firstName'], 'Без имени')} ${_safeString(user['lastName'], '')}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Телефон: ${_safeString(user['phone'], 'Не указан')}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Информация о принадлежности к закупке
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Ожидает';
      case 'confirmed':
        return 'Подтвержден';
      case 'paid':
        return 'Оплачен';
      case 'shipped':
        return 'Отправлен';
      case 'delivered':
        return 'Доставлен';
      case 'cancelled':
        return 'Отменен';
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
}
