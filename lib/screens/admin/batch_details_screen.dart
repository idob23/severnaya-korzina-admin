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
  Map<String, dynamic>? _totalOrder;

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

  // Заменить метод _buildControlButtons на этот обновленный:
  Widget _buildControlButtons() {
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
            'Управление партией',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),

          // Кнопки для общих заказов
          Row(
            children: [
              // Кнопка "Общий заказ"
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _orders.isNotEmpty ? _showTotalOrder : null,
                  icon: Icon(Icons.list_alt, size: 20),
                  label: Text(
                    'Общий заказ',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Новая кнопка "По пользователям"
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _orders.isNotEmpty ? _showOrdersByUsers : null,
                  icon: Icon(Icons.people, size: 20),
                  label: Text(
                    'По пользователям',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
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

          Row(
            children: [
              // Кнопка "Машина уехала"
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

              // Кнопка "Машина приехала"
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

          // Подсказки
          SizedBox(height: 12),
          Text(
            '• "Общий заказ" - сводка всех товаров для закупки у поставщика\n'
            '• "По пользователям" - группировка товаров по клиентам для раздачи\n'
            '• "Машина уехала/приехала" - управление статусами доставки',
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

  // Полностью заменить метод _buildOrderCard:
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final user = _safeMap(order['user']) ?? {};
    final address = _safeMap(order['address']) ?? {};
    // ИСПРАВЛЕНИЕ: используем 'items' вместо 'orderItems'
    final orderItems = _safeList(order['items'] ?? order['orderItems']);
    final totalAmount = _safeDouble(order['totalAmount']);
    final status = order['status'] ?? 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(status).withOpacity(0.2),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '${user['firstName'] ?? user['name'] ?? 'Без имени'} ${user['lastName'] ?? ''}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${totalAmount.toStringAsFixed(0)} ₽',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Телефон: ${user['phone'] ?? 'Не указан'}',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                'Статус: ${_getStatusText(status)} | Товаров: ${orderItems.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (address['address'] != null)
                Text(
                  'Адрес: ${address['address']}',
                  style: TextStyle(fontSize: 12),
                ),
            ],
          ),
          children: orderItems.isEmpty
              ? [
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Нет товаров в заказе',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ]
              : [
                  // Детали заказа
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Товары в заказе (${orderItems.length}):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...orderItems.map((item) {
                          // Поддержка разных структур данных
                          final productName = item['productName'] ??
                              item['product']?['name'] ??
                              'Товар';
                          final quantity = _safeInt(item['quantity']);
                          final price = _safeDouble(item['price']);
                          final itemTotal = quantity * price;
                          final unit =
                              item['unit'] ?? item['product']?['unit'] ?? 'шт';

                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    productName,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '$quantity $unit × ${price.toStringAsFixed(0)} ₽',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    '${itemTotal.toStringAsFixed(0)} ₽',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        Divider(height: 16),
                        Row(
                          children: [
                            Spacer(),
                            Text(
                              'Итого: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${totalAmount.toStringAsFixed(0)} ₽',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
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
  }

// Добавить новый метод для показа общего заказа:
  Future<void> _showTotalOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getTotalOrder(widget.batch['id']);
      final totalOrder = response['totalOrder'];

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.purple[600], size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Общий заказ партии',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Статистика
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Заказов',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '${totalOrder['ordersCount']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Участников',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '${totalOrder['uniqueUsersCount']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Общая сумма',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '${_safeDouble(totalOrder['totalAmount']).toStringAsFixed(0)} ₽',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Список товаров
                Expanded(
                  child: ListView.builder(
                    itemCount: (totalOrder['items'] as List).length,
                    itemBuilder: (context, index) {
                      final item = totalOrder['items'][index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            item['productName'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Категория: ${item['category']}',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item['quantity']} ${item['unit']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${_safeDouble(item['totalSum']).toStringAsFixed(0)} ₽',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
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
        ),
      );
    } catch (e) {
      _showSnackBar('Ошибка загрузки общего заказа: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Добавить новый метод _showOrdersByUsers после метода _showTotalOrder:
  Future<void> _showOrdersByUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getOrdersByUsers(widget.batch['id']);
      final userOrders = response['userOrders'] as List;
      final totalUsers = response['totalUsers'];
      final totalAmount = _safeDouble(response['totalAmount']);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Заголовок
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.indigo[600], size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Заказы по пользователям',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Статистика
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Пользователей',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '$totalUsers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[700],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Общая сумма',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '${totalAmount.toStringAsFixed(0)} ₽',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Средний чек',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '${totalUsers > 0 ? (totalAmount / totalUsers).toStringAsFixed(0) : 0} ₽',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Список пользователей с их заказами
                Expanded(
                  child: ListView.builder(
                    itemCount: userOrders.length,
                    itemBuilder: (context, index) {
                      final userOrder = userOrders[index];
                      final items = _safeList(userOrder['items']);
                      final userTotal = _safeDouble(userOrder['totalAmount']);
                      final ordersCount = _safeInt(userOrder['ordersCount']);

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            childrenPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo[100],
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.indigo[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userOrder['userName'] ?? 'Без имени',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        userOrder['phone'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${userTotal.toStringAsFixed(0)} ₽',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    Text(
                                      'Заказов: $ordersCount',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Адрес: ${userOrder['address'] ?? 'Не указан'}',
                              style: TextStyle(fontSize: 12),
                            ),
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Товары (${items.length} позиций):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ...items.map((item) {
                                      final quantity =
                                          _safeInt(item['quantity']);
                                      final totalSum =
                                          _safeDouble(item['totalSum']);

                                      return Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 3),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                '• ${item['productName']}',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            Text(
                                              '$quantity ${item['unit'] ?? 'шт'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Text(
                                              '${totalSum.toStringAsFixed(0)} ₽',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
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
        ),
      );
    } catch (e) {
      _showSnackBar('Ошибка загрузки заказов по пользователям: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Методы для управления статусами

  Future<void> _shipOrders() async {
    final paidOrders = _orders.where((o) => o['status'] == 'paid').length;

    if (paidOrders == 0) {
      _showSnackBar('Нет заказов для отправки');
      return;
    }

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
      setState(() {
        _isLoading = true;
      });

      try {
        // Вызываем реальный API
        final response = await _apiService.shipOrders(widget.batch['id']);

        if (response['success'] == true) {
          _showSnackBar(response['message'] ??
              'Заказы отправлены! SMS уведомления отправлены.');
          await _loadBatchOrders(); // Перезагружаем данные
        } else {
          _showSnackBar(response['message'] ?? 'Ошибка отправки заказов');
        }
      } catch (e) {
        _showSnackBar('Ошибка: $e');
        print('❌ Ошибка отправки заказов: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Заменить функцию _deliverOrders() в lib/screens/admin/batch_details_screen.dart

  Future<void> _deliverOrders() async {
    final shippedOrders = _orders.where((o) => o['status'] == 'shipped').length;

    if (shippedOrders == 0) {
      _showSnackBar('Нет заказов для доставки');
      return;
    }

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
      setState(() {
        _isLoading = true;
      });

      try {
        // Вызываем реальный API
        final response = await _apiService.deliverOrders(widget.batch['id']);

        if (response['success'] == true) {
          _showSnackBar(response['message'] ??
              'Заказы доставлены! Партия закрыта. SMS уведомления отправлены.');
          await _loadBatchOrders(); // Перезагружаем данные
        } else {
          _showSnackBar(response['message'] ?? 'Ошибка доставки заказов');
        }
      } catch (e) {
        _showSnackBar('Ошибка: $e');
        print('❌ Ошибка доставки заказов: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'paid':
        return Icons.payment;
      case 'confirmed':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Ожидает оплаты';
      case 'paid':
        return 'Оплачен';
      case 'confirmed':
        return 'Подтвержден';
      case 'shipped':
        return 'Отправлен';
      case 'delivered':
        return 'Доставлен';
      case 'cancelled':
        return 'Отменен';
      default:
        return status ?? 'Неизвестен';
    }
  }

  Color _getBatchStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'collecting':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getBatchStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Активна';
      case 'collecting':
        return 'Сбор средств';
      case 'completed':
        return 'Завершена';
      case 'delivered':
        return 'Доставлена';
      case 'cancelled':
        return 'Отменена';
      default:
        return status ?? 'Неизвестен';
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

  List<dynamic> _safeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    return [];
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
