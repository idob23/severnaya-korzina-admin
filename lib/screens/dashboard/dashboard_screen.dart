// lib/screens/dashboard/dashboard_screen.dart - ИСПРАВЛЕННАЯ ВЕРСИЯ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:severnaya_korzina_admin/providers/admin_provider.dart';
import 'package:severnaya_korzina_admin/providers/users_provider.dart';
import 'package:severnaya_korzina_admin/providers/products_provider.dart';
import 'package:severnaya_korzina_admin/providers/orders_provider.dart';
import 'package:severnaya_korzina_admin/services/data_service.dart';
import 'package:severnaya_korzina_admin/screens/users/users_screen.dart';
import 'package:severnaya_korzina_admin/screens/products/products_screen.dart';
import 'package:severnaya_korzina_admin/screens/orders/orders_screen.dart';
import 'package:severnaya_korzina_admin/screens/batches/batches_screen.dart';
import 'package:severnaya_korzina_admin/screens/payments/payments_screen.dart';
import 'package:severnaya_korzina_admin/screens/settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  final List<Widget> _pages = [
    DashboardContent(), // 0 - Dashboard
    UsersScreen(), // 1 - Пользователи
    ProductsScreen(), // 2 - Товары
    OrdersScreen(), // 3 - Заказы
    BatchesScreen(), // 4 - Закупки
    PaymentsScreen(), // 5 - Платежи
    SettingsScreen(), // 6 - Настройки
  ];

  final List<MenuItemData> _menuItems = [
    MenuItemData(0, Icons.dashboard, 'Dashboard', false),
    MenuItemData(1, Icons.people, 'Пользователи', false),
    MenuItemData(2, Icons.inventory, 'Товары', false),
    MenuItemData(3, Icons.shopping_bag, 'Заказы', false),
    MenuItemData(4, Icons.group_work, 'Закупки', true),
    MenuItemData(5, Icons.payment, 'Платежи', true),
    MenuItemData(6, Icons.settings, 'Настройки', true),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final dataService = DataService();
      await dataService.initializeTestData();

      final usersProvider = Provider.of<UsersProvider>(context, listen: false);
      final productsProvider =
          Provider.of<ProductsProvider>(context, listen: false);
      final ordersProvider =
          Provider.of<OrdersProvider>(context, listen: false);

      await Future.wait([
        usersProvider.loadUsers(),
        productsProvider.loadData(),
        ordersProvider.loadData(),
      ]);
    } catch (e) {
      print('Ошибка инициализации данных: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка данных...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Боковая панель
          Container(
            width: 250,
            color: Colors.blue[800],
            child: Column(
              children: [
                // Заголовок
                Container(
                  height: 80,
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Северная\nкорзина',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.blue[600], height: 1),

                // Меню
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // Основные пункты
                        ..._menuItems.where((item) => !item.isManagement).map(
                            (item) => _buildMenuItem(
                                item.index, item.icon, item.title)),

                        SizedBox(height: 16),
                        _buildMenuHeader('Управление'),

                        // Пункты управления
                        ..._menuItems.where((item) => item.isManagement).map(
                            (item) => _buildMenuItem(
                                item.index, item.icon, item.title)),
                      ],
                    ),
                  ),
                ),

                // Пользователь
                Container(
                  padding: EdgeInsets.all(16),
                  child: Consumer<AdminProvider>(
                    builder: (context, adminProvider, child) {
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[600],
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminProvider.currentAdminName ?? 'Admin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Администратор',
                                  style: TextStyle(
                                    color: Colors.blue[200],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.logout, color: Colors.white),
                            onPressed: () {
                              adminProvider.logout();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Основной контент
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blue[200],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.blue[800] : Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.blue[800] : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Класс для данных меню
class MenuItemData {
  final int index;
  final IconData icon;
  final String title;
  final bool isManagement;

  MenuItemData(this.index, this.icon, this.title, this.isManagement);
}

// DashboardContent остается без изменений
class DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              Text(
                'Обновлено: ${DateTime.now().toString().substring(0, 16)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Статистические карточки
          Row(
            children: [
              Expanded(child: _buildStatsCard()),
            ],
          ),
          SizedBox(height: 24),

          // Графики и таблицы
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildOrdersChart(),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildRecentActivity(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Consumer3<UsersProvider, ProductsProvider, OrdersProvider>(
      builder:
          (context, usersProvider, productsProvider, ordersProvider, child) {
        final usersStats = usersProvider.getUsersStats();
        final productsStats = productsProvider.getProductsStats();
        final ordersStats = ordersProvider.getOrdersStats();

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Пользователи',
                usersStats['total'].toString(),
                'Активных: ${usersStats['active']}',
                Icons.people,
                Colors.blue,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Товары',
                productsStats['total'].toString(),
                'Активных: ${productsStats['active']}',
                Icons.inventory,
                Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Заказы',
                ordersStats['total'].toString(),
                'Сегодня: ${ordersStats['today']}',
                Icons.shopping_bag,
                Colors.orange,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Выручка',
                '${(ordersStats['total_revenue'] as double).toStringAsFixed(0)} ₽',
                'Оплаченные заказы',
                Icons.attach_money,
                Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, IconData icon, Color color) {
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
                    '+12%',
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
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
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

  Widget _buildOrdersChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Заказы за последние 7 дней',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Пн',
                            'Вт',
                            'Ср',
                            'Чт',
                            'Пт',
                            'Сб',
                            'Вс'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return Text(days[value.toInt()]);
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
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
                        FlSpot(0, 3),
                        FlSpot(1, 7),
                        FlSpot(2, 5),
                        FlSpot(3, 12),
                        FlSpot(4, 8),
                        FlSpot(5, 15),
                        FlSpot(6, 10),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Последняя активность',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildActivityItem(
                    'Новый заказ #SK-2025-0021',
                    'Анна Иванова',
                    '5 минут назад',
                    Icons.shopping_bag,
                    Colors.green,
                  ),
                  _buildActivityItem(
                    'Регистрация пользователя',
                    'Петр Сидоров',
                    '12 минут назад',
                    Icons.person_add,
                    Colors.blue,
                  ),
                  _buildActivityItem(
                    'Оплачен заказ #SK-2025-0019',
                    'Мария Петрова',
                    '25 минут назад',
                    Icons.payment,
                    Colors.purple,
                  ),
                  _buildActivityItem(
                    'Добавлен товар',
                    'Хлеб белый',
                    '1 час назад',
                    Icons.add_box,
                    Colors.orange,
                  ),
                  _buildActivityItem(
                    'Закрыта закупка',
                    'Мясо и рыба',
                    '2 часа назад',
                    Icons.check_circle,
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
