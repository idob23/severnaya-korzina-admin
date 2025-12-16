// lib/screens/analytics_screen.dart
// Экран аналитики для панели администратора

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/admin_api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  // Данные дашборда
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _trends = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topCategories = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _orderStatuses = [];
  Map<String, dynamic>? _retention;
  Map<String, dynamic>? _savings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Загружаем все данные параллельно
      final results = await Future.wait([
        _apiService.getAnalyticsDashboard(),
        _apiService.getAnalyticsTrends(days: 30),
        _apiService.getTopProducts(limit: 20),
        _apiService.getTopCategories(),
        _apiService.getTopCustomers(limit: 20),
        _apiService.getOrderStatuses(),
        _apiService.getRetention(),
        _apiService.getSavings(),
      ]);

      setState(() {
        _dashboard = results[0]['dashboard'];
        _trends = List<Map<String, dynamic>>.from(results[1]['trends'] ?? []);
        _topProducts =
            List<Map<String, dynamic>>.from(results[2]['topProducts'] ?? []);
        _topCategories =
            List<Map<String, dynamic>>.from(results[3]['topCategories'] ?? []);
        _topCustomers =
            List<Map<String, dynamic>>.from(results[4]['topCustomers'] ?? []);
        _orderStatuses =
            List<Map<String, dynamic>>.from(results[5]['orderStatuses'] ?? []);
        _retention = results[6]['retention'];
        _savings = results[7]['savings'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки данных: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Аналитика'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportData,
            tooltip: 'Экспорт',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Дашборд'),
            Tab(icon: Icon(Icons.show_chart), text: 'Графики'),
            Tab(icon: Icon(Icons.inventory), text: 'Товары'),
            Tab(icon: Icon(Icons.people), text: 'Клиенты'),
            Tab(icon: Icon(Icons.savings), text: 'Экономия'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(),
                    _buildChartsTab(),
                    _buildProductsTab(),
                    _buildCustomersTab(),
                    _buildSavingsTab(),
                  ],
                ),
    );
  }

  // ==========================================
  // TAB 1: ДАШБОРД
  // ==========================================
  Widget _buildDashboardTab() {
    if (_dashboard == null) {
      return const Center(child: Text('Нет данных'));
    }

    final summary = _dashboard!['summary'] ?? {};
    final users = _dashboard!['users'] ?? {};
    final orders = _dashboard!['orders'] ?? {};
    final finance = _dashboard!['finance'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Главные метрики
            const Text(
              '💰 Ключевые показатели',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMetricsGrid([
              _MetricCard(
                title: 'GMV (Оборот)',
                value: _formatMoney(summary['gmv'] ?? 0),
                icon: Icons.monetization_on,
                color: Colors.green,
              ),
              _MetricCard(
                title: 'Комиссия (10%)',
                value: _formatMoney(summary['commission'] ?? 0),
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
              ),
              _MetricCard(
                title: 'Заказов',
                value: '${summary['totalOrders'] ?? 0}',
                icon: Icons.shopping_cart,
                color: Colors.orange,
              ),
              _MetricCard(
                title: 'Средний чек',
                value: _formatMoney(summary['avgOrderAmount'] ?? 0),
                icon: Icons.receipt,
                color: Colors.purple,
              ),
              _MetricCard(
                title: 'Пользователей',
                value: '${summary['totalUsers'] ?? 0}',
                icon: Icons.people,
                color: Colors.teal,
              ),
              _MetricCard(
                title: 'Уникальных покупателей',
                value: '${summary['uniqueCustomers'] ?? 0}',
                icon: Icons.shopping_bag,
                color: Colors.deepOrange,
              ),
              _MetricCard(
                title: 'ARPU',
                value: _formatMoney(summary['arpu'] ?? 0),
                icon: Icons.person,
                color: Colors.indigo,
              ),
            ]),

            const SizedBox(height: 24),

            // Рост
            const Text(
              '📈 Динамика (месяц к месяцу)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildGrowthCards(users, orders, finance),

            const SizedBox(height: 24),

            // Статусы заказов
            const Text(
              '📦 Распределение заказов',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildOrderStatusesCard(),

            const SizedBox(height: 24),

            // Retention
            if (_retention != null) ...[
              const Text(
                '🔄 Возвращаемость клиентов',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildRetentionCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(List<_MetricCard> cards) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards.map((card) => _buildMetricCardWidget(card)).toList(),
    );
  }

  Widget _buildMetricCardWidget(_MetricCard card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: card.color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(card.icon, color: card.color, size: 28),
          const SizedBox(height: 8),
          Text(
            card.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: card.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthCards(
    Map<String, dynamic> users,
    Map<String, dynamic> orders,
    Map<String, dynamic> finance,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildGrowthCard(
            'Пользователи',
            users['newThisMonth'] ?? 0,
            users['newLastMonth'] ?? 0,
            (users['growth'] ?? 0).toDouble(),
            Colors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGrowthCard(
            'Заказы',
            orders['thisMonth'] ?? 0,
            orders['lastMonth'] ?? 0,
            (orders['growth'] ?? 0).toDouble(),
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGrowthCard(
            'Выручка',
            finance['gmvThisMonth'] ?? 0,
            finance['gmvLastMonth'] ?? 0,
            (finance['growth'] ?? 0).toDouble(),
            Colors.green,
            isMoney: true,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthCard(
    String title,
    dynamic thisMonth,
    dynamic lastMonth,
    double growth,
    Color color, {
    bool isMoney = false,
  }) {
    final isPositive = growth >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            isMoney ? _formatMoney(thisMonth) : '$thisMonth',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isPositive ? Colors.green : Colors.red,
              ),
              Text(
                '${growth.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            'vs прошлый месяц: ${isMoney ? _formatMoney(lastMonth) : lastMonth}',
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusesCard() {
    if (_orderStatuses.isEmpty) {
      return const Card(
          child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Нет данных'),
      ));
    }

    final total = _orderStatuses.fold<int>(
      0,
      (sum, s) => sum + ((s['count'] as int?) ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _orderStatuses.map((status) {
            final count = status['count'] ?? 0;
            final percent = total > 0 ? (count / total * 100) : 0.0;
            final color = _getStatusColor(status['status']);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(status['label'] ?? status['status'])),
                  Text(
                    '$count (${percent.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRetentionCard() {
    final retentionRate = _retention?['retentionRate'] ?? 0;
    final distribution = _retention?['distribution'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${retentionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'клиентов\nвозвращаются',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildRetentionRow('1 заказ', distribution['oneOrder']),
            _buildRetentionRow('2 заказа', distribution['twoOrders']),
            _buildRetentionRow('3 заказа', distribution['threeOrders']),
            _buildRetentionRow('4+ заказа', distribution['fourPlusOrders']),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionRow(String label, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();

    final count = data['count'] ?? 0;
    final percent = double.tryParse(data['percent']?.toString() ?? '0') ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text('${percent.toStringAsFixed(1)}%'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: ГРАФИКИ
  // ==========================================
  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Динамика за 30 дней',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // График выручки
          const Text('Выручка (GMV)'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildRevenueChart(),
          ),

          const SizedBox(height: 24),

          // График заказов
          const Text('Количество заказов'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildOrdersChart(),
          ),

          const SizedBox(height: 24),

          // График пользователей
          const Text('Новые пользователи'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildUsersChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_trends.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < _trends.length; i++) {
      final revenue = (_trends[i]['revenue'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), revenue));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCompactMoney(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _trends.length) {
                  final date = _trends[index]['date'];
                  return Text(
                    date.substring(5), // MM-DD
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersChart() {
    if (_trends.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < _trends.length; i++) {
      final orders = (_trends[i]['orders'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), orders));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _trends.length) {
                  final date = _trends[index]['date'];
                  return Text(date.substring(5),
                      style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersChart() {
    if (_trends.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < _trends.length; i++) {
      final users = (_trends[i]['users'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), users));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _trends.length) {
                  final date = _trends[index]['date'];
                  return Text(date.substring(5),
                      style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: ТОВАРЫ
  // ==========================================
  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Топ категорий
          const Text(
            '📂 Топ категорий',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTopCategoriesTable(),

          const SizedBox(height: 24),

          // Топ товаров
          const Text(
            '🏆 Топ товаров',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTopProductsTable(),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesTable() {
    if (_topCategories.isEmpty) {
      return const Card(
          child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Нет данных'),
      ));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Категория')),
            DataColumn(label: Text('Выручка'), numeric: true),
            DataColumn(label: Text('Продано'), numeric: true),
          ],
          rows: _topCategories.take(10).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            return DataRow(cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(cat['name'] ?? '')),
              DataCell(Text(_formatMoney(cat['totalRevenue'] ?? 0))),
              DataCell(Text('${cat['totalQuantity'] ?? 0}')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopProductsTable() {
    if (_topProducts.isEmpty) {
      return const Card(
          child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Нет данных'),
      ));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Товар')),
            DataColumn(label: Text('Категория')),
            DataColumn(label: Text('Выручка'), numeric: true),
            DataColumn(label: Text('Продано'), numeric: true),
          ],
          rows: _topProducts.take(20).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return DataRow(cells: [
              DataCell(Text('${index + 1}')),
              DataCell(
                SizedBox(
                  width: 200,
                  child: Text(
                    product['name'] ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(product['category'] ?? '')),
              DataCell(Text(_formatMoney(product['totalRevenue'] ?? 0))),
              DataCell(Text('${product['totalSold'] ?? 0}')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: КЛИЕНТЫ
  // ==========================================
  Widget _buildCustomersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👑 Топ клиентов',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTopCustomersTable(),
        ],
      ),
    );
  }

  Widget _buildTopCustomersTable() {
    if (_topCustomers.isEmpty) {
      return const Card(
          child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Нет данных'),
      ));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Клиент')),
            DataColumn(label: Text('Телефон')),
            DataColumn(label: Text('Потрачено'), numeric: true),
            DataColumn(label: Text('Заказов'), numeric: true),
            DataColumn(label: Text('Ср. чек'), numeric: true),
          ],
          rows: _topCustomers.take(20).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final customer = entry.value;
            return DataRow(cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(customer['name'] ?? '')),
              DataCell(Text(customer['phone'] ?? '')),
              DataCell(Text(_formatMoney(customer['totalSpent'] ?? 0))),
              DataCell(Text('${customer['ordersCount'] ?? 0}')),
              DataCell(Text(_formatMoney(customer['avgOrderAmount'] ?? 0))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 5: ЭКОНОМИЯ
  // ==========================================
  Widget _buildSavingsTab() {
    if (_savings == null) {
      return const Center(child: Text('Нет данных'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Главная карточка экономии
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.savings, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Общая минимальная экономия клиентов',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoney(_savings!['totalSavings'] ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'от ${(_savings!['savingsPercent'] ?? 0).toStringAsFixed(0)}% экономии по сравнению с магазинами',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Детали
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSavingsRow(
                    'Общий оборот (GMV)',
                    _formatMoney(_savings!['totalGMV'] ?? 0),
                  ),
                  const Divider(),
                  _buildSavingsRow(
                    'Цена в местных магазинах (оценка)',
                    _formatMoney(_savings!['estimatedLocalPrice'] ?? 0),
                  ),
                  const Divider(),
                  _buildSavingsRow(
                    'Экономия на заказ (в среднем)',
                    _formatMoney(_savings!['avgSavingsPerOrder'] ?? 0),
                  ),
                  const Divider(),
                  _buildSavingsRow(
                    'Количество заказов',
                    '${_savings!['ordersCount'] ?? 0}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Оценка экономии рассчитана исходя из средней наценки местных магазинов от 30%',
                      style: TextStyle(fontSize: 12),
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

  Widget _buildSavingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ЭКСПОРТ
  // ==========================================
  void _exportData() async {
    try {
      final result = await _apiService.exportAnalytics();
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные готовы к экспорту'),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: Сохранить в файл или отправить на email
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка экспорта: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================
  String _formatMoney(dynamic value) {
    final numValue = (value is num) ? value.toDouble() : 0.0;
    final formatter = NumberFormat('#,##0', 'ru_RU');
    return '${formatter.format(numValue)} ₽';
  }

  String _formatCompactMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _MetricCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
