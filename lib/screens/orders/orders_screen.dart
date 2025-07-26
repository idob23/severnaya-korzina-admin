// screens/orders/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:severnaya_korzina_admin/providers/orders_provider.dart';
import 'package:severnaya_korzina_admin/models/order.dart';
import 'package:severnaya_korzina_admin/models/purchase_batch.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и поиск
          Row(
            children: [
              Text(
                'Управление заказами',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск заказов...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Consumer<OrdersProvider>(
                builder: (context, ordersProvider, child) {
                  return ElevatedButton.icon(
                    onPressed: () => ordersProvider.loadData(),
                    icon: Icon(Icons.refresh),
                    label: Text('Обновить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 24),

          // Вкладки
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[800],
            tabs: [
              Tab(text: 'Заказы'),
              Tab(text: 'Коллективные закупки'),
            ],
          ),
          SizedBox(height: 16),

          // Содержимое вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(),
                _buildBatchesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        // Фильтры и статистика для заказов
        Row(
          children: [
            _buildStatusFilter('Все', 'all'),
            SizedBox(width: 8),
            _buildStatusFilter('Ожидает', 'pending'),
            SizedBox(width: 8),
            _buildStatusFilter('Оплачен', 'paid'),
            SizedBox(width: 8),
            _buildStatusFilter('Подтвержден', 'confirmed'),
            SizedBox(width: 8),
            _buildStatusFilter('Отправлен', 'shipped'),
            SizedBox(width: 8),
            _buildStatusFilter('Завершен', 'completed'),
            Spacer(),
            Consumer<OrdersProvider>(
              builder: (context, ordersProvider, child) {
                final stats = ordersProvider.getOrdersStats();
                return Row(
                  children: [
                    _buildStatChip('Всего: ${stats['total']}', Colors.blue),
                    SizedBox(width: 8),
                    _buildStatChip('Сегодня: ${stats['today']}', Colors.green),
                    SizedBox(width: 8),
                    _buildStatChip(
                        'Выручка: ${(stats['total_revenue'] as double).toStringAsFixed(0)} ₽',
                        Colors.purple),
                  ],
                );
              },
            ),
          ],
        ),
        SizedBox(height: 16),

        // Таблица заказов
        Expanded(
          child: Card(
            elevation: 2,
            child: Consumer<OrdersProvider>(
              builder: (context, ordersProvider, child) {
                if (ordersProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                final orders = _getFilteredOrders(ordersProvider);

                return DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 1200,
                  columns: [
                    DataColumn2(
                      label: Text('Заказ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text('Клиент',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text('Закупка',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text('Сумма',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Статус',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Оплата',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Дата',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Действия',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                      fixedWidth: 150,
                    ),
                  ],
                  rows: orders
                      .map((order) => _buildOrderRow(order, ordersProvider))
                      .toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchesTab() {
    return Column(
      children: [
        Row(
          children: [
            Spacer(),
            ElevatedButton.icon(
              onPressed: _showAddBatchDialog,
              icon: Icon(Icons.add),
              label: Text('Создать закупку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: Card(
            elevation: 2,
            child: Consumer<OrdersProvider>(
              builder: (context, ordersProvider, child) {
                if (ordersProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                final batches = ordersProvider.batches;

                return DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 1000,
                  columns: [
                    DataColumn2(
                      label: Text('Закупка',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text('Период',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text('Участники',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Статус',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Сумма',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Действия',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                      fixedWidth: 150,
                    ),
                  ],
                  rows: batches
                      .map((batch) => _buildBatchRow(batch, ordersProvider))
                      .toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[800],
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  DataRow _buildOrderRow(AdminOrder order, OrdersProvider ordersProvider) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                order.orderNumber,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                '${order.itemsCount} товаров',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                order.userName,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                order.userPhone,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            order.batchTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${order.totalAmount.toStringAsFixed(0)} ₽',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Предоплата: ${order.prepaidAmount.toStringAsFixed(0)} ₽',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: order.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: order.statusColor.withOpacity(0.3)),
            ),
            child: Text(
              order.statusText,
              style: TextStyle(
                color: order.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: order.paymentStatus == 'paid'
                  ? Colors.green[50]
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: order.paymentStatus == 'paid'
                    ? Colors.green[200]!
                    : Colors.orange[200]!,
              ),
            ),
            child: Text(
              order.paymentStatusText,
              style: TextStyle(
                color: order.paymentStatus == 'paid'
                    ? Colors.green[800]
                    : Colors.orange[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            DateFormat('dd.MM.yy\nHH:mm').format(order.createdAt),
            style: TextStyle(fontSize: 12),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: Icon(Icons.edit, size: 18),
                tooltip: 'Изменить статус',
                onSelected: (status) =>
                    _updateOrderStatus(order, status, ordersProvider),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'pending', child: Text('Ожидает')),
                  PopupMenuItem(value: 'paid', child: Text('Оплачен')),
                  PopupMenuItem(value: 'confirmed', child: Text('Подтвержден')),
                  PopupMenuItem(value: 'shipped', child: Text('Отправлен')),
                  PopupMenuItem(
                      value: 'ready_pickup', child: Text('Готов к выдаче')),
                  PopupMenuItem(value: 'completed', child: Text('Завершен')),
                  PopupMenuItem(value: 'cancelled', child: Text('Отменен')),
                ],
              ),
              IconButton(
                icon: Icon(Icons.visibility, size: 18),
                onPressed: () => _showOrderDetails(order),
                tooltip: 'Подробности',
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildBatchRow(
      AdminPurchaseBatch batch, OrdersProvider ordersProvider) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                batch.title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (batch.description?.isNotEmpty == true)
                Text(
                  batch.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${DateFormat('dd.MM.yy').format(batch.startDate)} - ${DateFormat('dd.MM.yy').format(batch.endDate)}',
                style: TextStyle(fontSize: 12),
              ),
              if (batch.deliveryDate != null)
                Text(
                  'Доставка: ${DateFormat('dd.MM.yy').format(batch.deliveryDate!)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Text('${batch.currentParticipants}/${batch.minParticipants}'),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: batch.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: batch.statusColor.withOpacity(0.3)),
            ),
            child: Text(
              batch.statusText,
              style: TextStyle(
                color: batch.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Text('${batch.totalAmount.toStringAsFixed(0)} ₽'),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: Icon(Icons.edit, size: 18),
                tooltip: 'Изменить статус',
                onSelected: (status) =>
                    _updateBatchStatus(batch, status, ordersProvider),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'draft', child: Text('Черновик')),
                  PopupMenuItem(value: 'active', child: Text('Активна')),
                  PopupMenuItem(value: 'closed', child: Text('Закрыта')),
                  PopupMenuItem(value: 'processing', child: Text('Обработка')),
                  PopupMenuItem(value: 'shipped', child: Text('Отправлена')),
                  PopupMenuItem(value: 'completed', child: Text('Завершена')),
                  PopupMenuItem(value: 'cancelled', child: Text('Отменена')),
                ],
              ),
              IconButton(
                icon: Icon(Icons.visibility, size: 18),
                onPressed: () => _showBatchDetails(batch, ordersProvider),
                tooltip: 'Подробности',
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<AdminOrder> _getFilteredOrders(OrdersProvider ordersProvider) {
    List<AdminOrder> orders = ordersProvider.searchOrders(_searchQuery);

    if (_selectedStatus != 'all') {
      orders =
          orders.where((order) => order.status == _selectedStatus).toList();
    }

    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<void> _updateOrderStatus(
      AdminOrder order, String newStatus, OrdersProvider ordersProvider) async {
    try {
      await ordersProvider.updateOrderStatus(order.id, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус заказа ${order.orderNumber} изменен'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBatchStatus(AdminPurchaseBatch batch, String newStatus,
      OrdersProvider ordersProvider) async {
    try {
      await ordersProvider.updateBatchStatus(batch.id, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус закупки "${batch.title}" изменен'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetails(AdminOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Заказ ${order.orderNumber}'),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Клиент:', order.userName),
              _buildDetailRow('Телефон:', order.userPhone),
              _buildDetailRow('Закупка:', order.batchTitle),
              _buildDetailRow('Статус:', order.statusText),
              _buildDetailRow('Статус оплаты:', order.paymentStatusText),
              _buildDetailRow(
                  'Общая сумма:', '${order.totalAmount.toStringAsFixed(0)} ₽'),
              _buildDetailRow(
                  'Предоплата:', '${order.prepaidAmount.toStringAsFixed(0)} ₽'),
              _buildDetailRow('К доплате:',
                  '${order.remainingAmount.toStringAsFixed(0)} ₽'),
              _buildDetailRow('Товаров:', '${order.itemsCount}'),
              _buildDetailRow('Дата создания:',
                  DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt)),
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

  void _showBatchDetails(
      AdminPurchaseBatch batch, OrdersProvider ordersProvider) {
    final orders = ordersProvider.getOrdersByBatch(batch.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Закупка: ${batch.title}'),
        content: Container(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информация о закупке
              _buildDetailRow('Статус:', batch.statusText),
              _buildDetailRow('Период:',
                  '${DateFormat('dd.MM.yyyy').format(batch.startDate)} - ${DateFormat('dd.MM.yyyy').format(batch.endDate)}'),
              _buildDetailRow('Участники:',
                  '${batch.currentParticipants}/${batch.minParticipants}'),
              _buildDetailRow(
                  'Общая сумма:', '${batch.totalAmount.toStringAsFixed(0)} ₽'),
              if (batch.pickupAddress != null)
                _buildDetailRow('Адрес выдачи:', batch.pickupAddress!),

              SizedBox(height: 16),
              Text('Заказы в этой закупке:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),

              // Список заказов
              Expanded(
                child: orders.isEmpty
                    ? Center(child: Text('Заказов пока нет'))
                    : ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(order.orderNumber),
                              subtitle: Text(
                                  '${order.userName} - ${order.totalAmount.toStringAsFixed(0)} ₽'),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: order.statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order.statusText,
                                  style: TextStyle(
                                    color: order.statusColor,
                                    fontSize: 12,
                                  ),
                                ),
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
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showAddBatchDialog() {
    showDialog(
      context: context,
      builder: (context) => BatchEditDialog(),
    );
  }
}

// Диалог создания/редактирования закупки
class BatchEditDialog extends StatefulWidget {
  final AdminPurchaseBatch? batch;

  BatchEditDialog({this.batch});

  @override
  _BatchEditDialogState createState() => _BatchEditDialogState();
}

class _BatchEditDialogState extends State<BatchEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _minParticipantsController;
  late TextEditingController _maxParticipantsController;
  late TextEditingController _pickupAddressController;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 7));
  DateTime? _deliveryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.batch?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.batch?.description ?? '');
    _minParticipantsController = TextEditingController(
        text: widget.batch?.minParticipants.toString() ?? '10');
    _maxParticipantsController = TextEditingController(
        text: widget.batch?.maxParticipants?.toString() ?? '');
    _pickupAddressController = TextEditingController(
        text: widget.batch?.pickupAddress ??
            'ул. Ленина, 15, магазин "Северянка"');

    if (widget.batch != null) {
      _startDate = widget.batch!.startDate;
      _endDate = widget.batch!.endDate;
      _deliveryDate = widget.batch!.deliveryDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _minParticipantsController.dispose();
    _maxParticipantsController.dispose();
    _pickupAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.batch == null ? 'Создать закупку' : 'Редактировать закупку'),
      content: Container(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Название закупки',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите название закупки';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minParticipantsController,
                        decoration: InputDecoration(
                          labelText: 'Мин. участников',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите количество';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Неверный формат';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxParticipantsController,
                        decoration: InputDecoration(
                          labelText: 'Макс. участников',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _pickupAddressController,
                  decoration: InputDecoration(
                    labelText: 'Адрес выдачи',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                // Даты
                Text('Период закупки:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Дата начала',
                            border: OutlineInputBorder(),
                          ),
                          child:
                              Text(DateFormat('dd.MM.yyyy').format(_startDate)),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Дата окончания',
                            border: OutlineInputBorder(),
                          ),
                          child:
                              Text(DateFormat('dd.MM.yyyy').format(_endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveBatch,
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.batch == null ? 'Создать' : 'Сохранить'),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(Duration(days: 7));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _saveBatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ordersProvider =
          Provider.of<OrdersProvider>(context, listen: false);

      final batch = AdminPurchaseBatch(
        id: widget.batch?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        deliveryDate: _deliveryDate,
        minParticipants: int.parse(_minParticipantsController.text),
        maxParticipants: _maxParticipantsController.text.isEmpty
            ? null
            : int.tryParse(_maxParticipantsController.text),
        currentParticipants: widget.batch?.currentParticipants ?? 0,
        status: widget.batch?.status ?? 'draft',
        pickupAddress: _pickupAddressController.text.trim().isEmpty
            ? null
            : _pickupAddressController.text.trim(),
        createdAt: widget.batch?.createdAt ?? DateTime.now(),
        productsCount: widget.batch?.productsCount ?? 0,
        totalAmount: widget.batch?.totalAmount ?? 0,
      );

      if (widget.batch == null) {
        await ordersProvider.addBatch(batch);
      } else {
        await ordersProvider.updateBatch(batch);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.batch == null ? 'Закупка создана' : 'Закупка обновлена',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
