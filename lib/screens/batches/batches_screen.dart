// lib/screens/batches/batches_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:severnaya_korzina_admin/providers/orders_provider.dart';
import 'package:severnaya_korzina_admin/models/purchase_batch.dart';
import 'package:uuid/uuid.dart';

class BatchesScreen extends StatefulWidget {
  @override
  _BatchesScreenState createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и действия
          Row(
            children: [
              Text(
                'Управление закупками',
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
                    hintText: 'Поиск закупок...',
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
              ElevatedButton.icon(
                onPressed: _showCreateBatchDialog,
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
          SizedBox(height: 24),

          // Статистика и фильтры
          Row(
            children: [
              _buildStatusFilter('Все', 'all'),
              SizedBox(width: 8),
              _buildStatusFilter('Черновики', 'draft'),
              SizedBox(width: 8),
              _buildStatusFilter('Активные', 'active'),
              SizedBox(width: 8),
              _buildStatusFilter('Закрытые', 'closed'),
              SizedBox(width: 8),
              _buildStatusFilter('Завершенные', 'completed'),
              Spacer(),
              Consumer<OrdersProvider>(
                builder: (context, ordersProvider, child) {
                  final stats = ordersProvider.getBatchesStats();
                  return Row(
                    children: [
                      _buildStatChip('Всего: ${stats['total']}', Colors.blue),
                      SizedBox(width: 8),
                      _buildStatChip(
                          'Активных: ${stats['active']}', Colors.green),
                      SizedBox(width: 8),
                      _buildStatChip(
                          'Завершенных: ${stats['completed']}', Colors.purple),
                    ],
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 16),

          // Таблица закупок
          Expanded(
            child: Card(
              elevation: 2,
              child: Consumer<OrdersProvider>(
                builder: (context, ordersProvider, child) {
                  if (ordersProvider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final batches = _getFilteredBatches(ordersProvider);

                  return DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1200,
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
                        label: Text('Прогресс',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        size: ColumnSize.M,
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
      ),
    );
  }

  Widget _buildStatusFilter(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[800],
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

  DataRow _buildBatchRow(
      AdminPurchaseBatch batch, OrdersProvider ordersProvider) {
    final progress = batch.minParticipants > 0
        ? (batch.currentParticipants / batch.minParticipants).clamp(0.0, 1.0)
        : 0.0;

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
                'Начало: ${DateFormat('dd.MM.yyyy').format(batch.startDate)}',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                'Окончание: ${DateFormat('dd.MM.yyyy').format(batch.endDate)}',
                style: TextStyle(fontSize: 12),
              ),
              if (batch.deliveryDate != null)
                Text(
                  'Доставка: ${DateFormat('dd.MM.yyyy').format(batch.deliveryDate!)}',
                  style: TextStyle(
                    fontSize: 10,
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
                '${batch.currentParticipants}/${batch.minParticipants}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              if (batch.maxParticipants != null)
                Text(
                  'Макс: ${batch.maxParticipants}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
            ],
          ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : Colors.orange,
                ),
                minHeight: 6,
              ),
              SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18),
                onSelected: (action) =>
                    _handleBatchAction(batch, action, ordersProvider),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  PopupMenuItem(value: 'activate', child: Text('Активировать')),
                  PopupMenuItem(value: 'close', child: Text('Закрыть')),
                  PopupMenuItem(value: 'complete', child: Text('Завершить')),
                  PopupMenuItem(value: 'cancel', child: Text('Отменить')),
                  PopupMenuItem(value: 'delete', child: Text('Удалить')),
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

  List<AdminPurchaseBatch> _getFilteredBatches(OrdersProvider ordersProvider) {
    List<AdminPurchaseBatch> batches = ordersProvider.batches;

    // Фильтрация по поиску
    if (_searchQuery.isNotEmpty) {
      batches = batches.where((batch) {
        return batch.title.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Фильтрация по статусу
    if (_statusFilter != 'all') {
      batches =
          batches.where((batch) => batch.status == _statusFilter).toList();
    }

    // Сортировка по дате создания
    batches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return batches;
  }

  void _handleBatchAction(
      AdminPurchaseBatch batch, String action, OrdersProvider ordersProvider) {
    switch (action) {
      case 'edit':
        _showEditBatchDialog(batch);
        break;
      case 'activate':
        _updateBatchStatus(batch, 'active', ordersProvider);
        break;
      case 'close':
        _updateBatchStatus(batch, 'closed', ordersProvider);
        break;
      case 'complete':
        _updateBatchStatus(batch, 'completed', ordersProvider);
        break;
      case 'cancel':
        _updateBatchStatus(batch, 'cancelled', ordersProvider);
        break;
      case 'delete':
        _deleteBatch(batch, ordersProvider);
        break;
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

  Future<void> _deleteBatch(
      AdminPurchaseBatch batch, OrdersProvider ordersProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить закупку'),
        content:
            Text('Вы уверены, что хотите удалить закупку "${batch.title}"?'),
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

    if (confirmed == true) {
      try {
        await ordersProvider.deleteBatch(batch.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Закупка "${batch.title}" удалена'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateBatchDialog() {
    showDialog(
      context: context,
      builder: (context) => BatchCreateEditDialog(),
    );
  }

  void _showEditBatchDialog(AdminPurchaseBatch batch) {
    showDialog(
      context: context,
      builder: (context) => BatchCreateEditDialog(batch: batch),
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
}

// Диалог создания/редактирования закупки
class BatchCreateEditDialog extends StatefulWidget {
  final AdminPurchaseBatch? batch;

  BatchCreateEditDialog({this.batch});

  @override
  _BatchCreateEditDialogState createState() => _BatchCreateEditDialogState();
}

class _BatchCreateEditDialogState extends State<BatchCreateEditDialog> {
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
      final uuid = Uuid();

      final batch = AdminPurchaseBatch(
        id: widget.batch?.id ?? uuid.v4(),
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
