// lib/screens/payments/payments_screen.dart - ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ ВЕРСИЯ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:severnaya_korzina_admin/providers/orders_provider.dart';

class PaymentsScreen extends StatefulWidget {
  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и фильтры
          Row(
            children: [
              Text(
                'Управление платежами',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск платежей...',
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
                onPressed: _showExportDialog,
                icon: Icon(Icons.file_download),
                label: Text('Экспорт'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Статистика платежей
          _buildPaymentStats(),
          SizedBox(height: 24),

          // Фильтры
          Row(
            children: [
              _buildStatusFilter('Все', 'all'),
              SizedBox(width: 8),
              _buildStatusFilter('Успешные', 'succeeded'),
              SizedBox(width: 8),
              _buildStatusFilter('Ожидающие', 'pending'),
              SizedBox(width: 8),
              _buildStatusFilter('Отклоненные', 'canceled'),
              SizedBox(width: 8),
              _buildStatusFilter('Возвраты', 'refunded'),
              Spacer(),
              _buildDateFilter(),
            ],
          ),
          SizedBox(height: 16),

          // Основной контент
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 2,
                    child: _buildPaymentsTable(),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: _buildPaymentChart(),
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: _buildPaymentMethods(),
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

  Widget _buildPaymentStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Общий оборот',
            '2,450,000 ₽',
            'За последний месяц',
            Icons.trending_up,
            Colors.green,
            '+12.5%',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Успешных платежей',
            '1,847',
            'Из 1,912 попыток',
            Icons.check_circle,
            Colors.blue,
            '96.6%',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Средний чек',
            '1,327 ₽',
            'Предоплата 90%',
            Icons.receipt,
            Colors.purple,
            '+8.2%',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Возвраты',
            '23,400 ₽',
            '12 операций',
            Icons.undo,
            Colors.orange,
            '-2.1%',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle,
      IconData icon, Color color, String trend) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
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
      selectedColor: Colors.purple[100],
      checkmarkColor: Colors.purple[800],
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range, size: 16),
          SizedBox(width: 8),
          Text(
            '${DateFormat('dd.MM').format(_startDate)} - ${DateFormat('dd.MM').format(_endDate)}',
            style: TextStyle(fontSize: 12),
          ),
          SizedBox(width: 8),
          InkWell(
            onTap: _selectDateRange,
            child: Icon(Icons.arrow_drop_down, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTable() {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, child) {
        if (ordersProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        try {
          final payments = _generateMockPayments();
          final filteredPayments = _getFilteredPayments(payments);

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Список платежей',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: filteredPayments.isEmpty
                      ? Center(
                          child: Text(
                            'Платежи не найдены',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = filteredPayments[index];
                            return _buildPaymentCard(payment);
                          },
                        ),
                ),
              ],
            ),
          );
        } catch (e) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Ошибка загрузки данных',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Попробуйте обновить страницу',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildPaymentCard(MockPayment payment) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Основная информация
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Платеж ${payment.paymentId}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Заказ: ${payment.orderNumber}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        payment.customerName,
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        payment.customerPhone,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Сумма
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${payment.amount.toStringAsFixed(0)} ₽',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            payment.method == 'bank_card'
                                ? Icons.credit_card
                                : Icons.qr_code,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            payment.method == 'bank_card' ? 'Карта' : 'СБП',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Статус
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: payment.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: payment.statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          payment.statusText,
                          style: TextStyle(
                            color: payment.statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('dd.MM.yy HH:mm').format(payment.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Действия
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 16),
                  onSelected: (action) => _handlePaymentAction(payment, action),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'details', child: Text('Подробности')),
                    PopupMenuItem(value: 'refund', child: Text('Возврат')),
                    PopupMenuItem(value: 'receipt', child: Text('Чек')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChart() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Динамика платежей',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final labels = ['1', '5', '10', '15', '20', '25', '30'];
                        int index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Text(
                            labels[index],
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 45),
                      FlSpot(1, 52),
                      FlSpot(2, 48),
                      FlSpot(3, 67),
                      FlSpot(4, 71),
                      FlSpot(5, 63),
                      FlSpot(6, 78),
                    ],
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Способы оплаты',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildMethodItem('Карты МИР', '1,672', '68.2%',
                    Icons.credit_card, Colors.blue),
                _buildMethodItem(
                    'СБП', '724', '29.5%', Icons.qr_code, Colors.green),
                _buildMethodItem(
                    'Наличные', '56', '2.3%', Icons.money, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodItem(String name, String count, String percentage,
      IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$count платежей',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<MockPayment> _generateMockPayments() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(15, (index) {
      final amount = 500.0 + (index * 150);
      final statuses = ['succeeded', 'pending', 'canceled', 'refunded'];
      final status = statuses[index % statuses.length];
      final names = [
        'Анна Иванова',
        'Петр Сидоров',
        'Мария Петрова',
        'Дмитрий Козлов'
      ];

      return MockPayment(
        paymentId: 'PAY-${(random + index).toString().substring(8, 13)}',
        yookassaId: '${(random + index).toString().substring(5, 15)}',
        orderNumber: 'SK-2025-${(1000 + index).toString().padLeft(4, '0')}',
        customerName: names[index % names.length],
        customerPhone:
            '+7914${(1000000 + index * 123).toString().substring(1, 8)}',
        amount: amount,
        method: index % 3 == 0 ? 'sbp' : 'bank_card',
        status: status,
        createdAt:
            DateTime.now().subtract(Duration(days: index, hours: index * 2)),
      );
    });
  }

  List<MockPayment> _getFilteredPayments(List<MockPayment> payments) {
    List<MockPayment> filtered = List.from(payments);

    // Фильтр по поиску
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((payment) {
        return payment.paymentId
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            payment.orderNumber
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            payment.customerName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Фильтр по статусу
    if (_statusFilter != 'all') {
      filtered =
          filtered.where((payment) => payment.status == _statusFilter).toList();
    }

    // Фильтр по дате
    filtered = filtered.where((payment) {
      return payment.createdAt
              .isAfter(_startDate.subtract(Duration(days: 1))) &&
          payment.createdAt.isBefore(_endDate.add(Duration(days: 1)));
    }).toList();

    return filtered;
  }

  void _handlePaymentAction(MockPayment payment, String action) {
    switch (action) {
      case 'details':
        _showPaymentDetails(payment);
        break;
      case 'refund':
        _showRefundDialog(payment);
        break;
      case 'receipt':
        _showReceiptDialog(payment);
        break;
    }
  }

  void _showPaymentDetails(MockPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Детали платежа'),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID платежа:', payment.paymentId),
              _buildDetailRow('ЮKassa ID:', payment.yookassaId),
              _buildDetailRow('Заказ:', payment.orderNumber),
              _buildDetailRow('Клиент:', payment.customerName),
              _buildDetailRow('Телефон:', payment.customerPhone),
              _buildDetailRow(
                  'Сумма:', '${payment.amount.toStringAsFixed(0)} ₽'),
              _buildDetailRow('Метод:',
                  payment.method == 'bank_card' ? 'Банковская карта' : 'СБП'),
              _buildDetailRow('Статус:', payment.statusText),
              _buildDetailRow('Дата:',
                  DateFormat('dd.MM.yyyy HH:mm').format(payment.createdAt)),
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

  void _showRefundDialog(MockPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Возврат платежа'),
        content: Text(
            'Вы уверены, что хотите оформить возврат на сумму ${payment.amount.toStringAsFixed(0)} ₽?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Возврат оформлен'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Оформить возврат'),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(MockPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Чек'),
        content: Text(
            'Чек для платежа ${payment.paymentId} будет отправлен на email клиента.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Чек отправлен'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Отправить чек'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Экспорт данных'),
        content: Text('Выберите формат экспорта:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Экспорт в Excel начат'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Excel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Экспорт в CSV начат'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
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

// Модель для демонстрации платежей
class MockPayment {
  final String paymentId;
  final String yookassaId;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final double amount;
  final String method;
  final String status;
  final DateTime createdAt;

  MockPayment({
    required this.paymentId,
    required this.yookassaId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  String get statusText {
    switch (status) {
      case 'succeeded':
        return 'Успешно';
      case 'pending':
        return 'Ожидает';
      case 'canceled':
        return 'Отклонен';
      case 'refunded':
        return 'Возврат';
      default:
        return 'Неизвестно';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'succeeded':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'canceled':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
