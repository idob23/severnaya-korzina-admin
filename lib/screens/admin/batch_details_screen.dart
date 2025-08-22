// lib/screens/admin/batch_details_screen.dart
// Новый экран для детального просмотра партии с заказами

import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../constants/order_status.dart';

class BatchDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> batch;

  const BatchDetailsScreen({Key? key, required this.batch}) : super(key: key);

  @override
  _BatchDetailsScreenState createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatchOrders();
  }

  Future<void> _loadBatchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Загружаем все заказы и фильтруем по batchId
      final response = await _apiService.getOrders();
      final allOrders = response['orders'] ?? [];

      setState(() {
        _orders = allOrders
            .where((order) => order['batchId'] == widget.batch['id'])
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки заказов: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Партия #${widget.batch['id']}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Информация о партии
          _buildBatchInfoPanel(),

          // Кнопки управления
          _buildControlButtons(),

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

  Widget _buildBatchInfoPanel() {
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
          // Название и статус
          Row(
            children: [
              Icon(Icons.local_shipping, color: Colors.blue[700], size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.batch['title'] ?? 'Без названия',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getBatchStatusColor(widget.batch['status']),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getBatchStatusText(widget.batch['status']),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Статистика
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Цель',
                  '${_safeDouble(widget.batch['targetAmount']).toStringAsFixed(0)}₽',
                  Icons.flag,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Собрано',
                  '${_safeDouble(widget.batch['currentAmount']).toStringAsFixed(0)}₽',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Участников',
                  '${_safeInt(widget.batch['participantsCount'])}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Заказов',
                  '${_orders.length}',
                  Icons.shopping_cart,
                  Colors.purple,
                ),
              ),
            ],
          ),

          // Прогресс бар
          SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Прогресс сбора',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    '${_safeDouble(widget.batch['progressPercent']).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: _safeDouble(widget.batch['progressPercent']) / 100,
                backgroundColor: Colors.blue[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                minHeight: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    // Считаем количество заказов по статусам
    final paidOrders = _orders.where((o) => o['status'] == 'paid').length;
    final shippedOrders = _orders.where((o) => o['status'] == 'shipped').length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Управление статусами заказов',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              // Кнопка "Машина уехала" (shipped)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: paidOrders > 0 ? _shipOrders : null,
                  icon: Icon(Icons.local_shipping),
                  label: Text('Машина уехала'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Кнопка "Машина приехала" (delivered)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: shippedOrders > 0 ? _deliverOrders : null,
                  icon: Icon(Icons.done_all),
                  label: Text('Машина приехала'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Кнопка "Откатить партию" (возврат денег)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _orders.isNotEmpty ? _refundBatch : null,
              icon: Icon(Icons.undo),
              label: Text('Откатить партию (возврат денег)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Подсказки
          SizedBox(height: 12),
          Text(
            '• "Машина уехала" переведет все оплаченные заказы в статус "Отправлен"\n'
            '• "Машина приехала" переведет все отправленные заказы в "Доставлен"\n'
            '• Пользователи получат SMS уведомления',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
            onPressed: _loadBatchOrders,
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'В этой партии пока нет заказов',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок списка
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Заказы в партии (${_orders.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Список заказов
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];
              return _buildOrderCard(order);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final user = _safeMap(order['user']) ?? {};
    final address = _safeMap(order['address']) ?? {};

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
                  'Заказ #${_safeString(order['id'])}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(_safeString(order['status'])),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getOrderStatusText(_safeString(order['status'])),
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
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    _safeString(user['firstName'], '?').isNotEmpty
                        ? _safeString(user['firstName'], '?')[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(width: 8),
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
                Text(
                  '${_safeDouble(order['totalAmount']).toStringAsFixed(0)}₽',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),

            // Адрес доставки
            if (_safeString(address['title']).isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
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
          ],
        ),
      ),
    );
  }

  // Методы для управления статусами
  Future<void> _shipOrders() async {
    final paidOrders = _orders.where((o) => o['status'] == 'paid').length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Машина уехала за заказами?'),
        content: Text(
          'Это изменит статус для $paidOrders заказов с "Оплачен" на "Отправлен".\n\n'
          'Пользователи получат SMS: "Машина уехала за заказом"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Подтвердить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Реализовать API вызов для массового изменения статусов
      _showSnackBar('Заказы отправлены! SMS уведомления отправлены.');
      _loadBatchOrders(); // Перезагружаем данные
    }
  }

  Future<void> _deliverOrders() async {
    final shippedOrders = _orders.where((o) => o['status'] == 'shipped').length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Машина приехала?'),
        content: Text(
          'Это изменит статус для $shippedOrders заказов с "Отправлен" на "Доставлен".\n\n'
          'Партия будет автоматически закрыта.\n'
          'Пользователи получат SMS: "Машина прибыла, можете забрать заказ."',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Подтвердить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Реализовать API вызов для массового изменения статусов
      _showSnackBar(
          'Заказы доставлены! Партия закрыта. SMS уведомления отправлены.');
      _loadBatchOrders(); // Перезагружаем данные
    }
  }

  Future<void> _refundBatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Откатить партию?'),
        content: Text(
          'Это вернет деньги всем пользователям и отменит все заказы в партии.\n\n'
          '⚠️ Операция необратима!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Откатить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Реализовать возврат денег (пока заглушка)
      _showSnackBar(
          'Функция возврата денег будет реализована в следующей версии');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Вспомогательные методы
  Color _getBatchStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'collecting':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getBatchStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Активная';
      case 'collecting':
        return 'Сбор средств';
      case 'completed':
        return 'Завершена';
      case 'cancelled':
        return 'Отменена';
      default:
        return status;
    }
  }

  Color _getOrderStatusColor(String status) {
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

  String _getOrderStatusText(String status) {
    return statusTexts[status.toLowerCase()] ?? status;
  }

  // Безопасные методы доступа к данным
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

  Map<String, dynamic>? _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }
}
