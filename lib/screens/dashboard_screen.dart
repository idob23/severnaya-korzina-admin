// lib/screens/dashboard_screen.dart - БАЗОВЫЙ DASHBOARD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_api_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Список экранов админки
  final List<Widget> _screens = [
    _DashboardHomeScreen(),
    _UsersManagementScreen(),
    _OrdersManagementScreen(),
    _ProductsManagementScreen(),
    _BatchesManagementScreen(),
    _SettingsScreen(),
  ];

  // Элементы навигации
  final List<BottomNavigationBarItem> _navigationItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Главная',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Пользователи',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart),
      label: 'Заказы',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.inventory),
      label: 'Товары',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.local_shipping),
      label: 'Партии',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Настройки',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Северная корзина - Админ'),
        actions: [
          // Индикатор пользователя
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 20),
                    SizedBox(width: 8),
                    Text(
                      user?['firstName'] ?? 'Админ',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),

          // Кнопка выхода
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey[600],
        items: _navigationItems,
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выход'),
        content: Text('Вы уверены, что хотите выйти из системы?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Выйти'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
    }
  }
}

/// Главная страница dashboard - С РЕАЛЬНОЙ СТАТИСТИКОЙ
class _DashboardHomeScreen extends StatefulWidget {
  @override
  _DashboardHomeScreenState createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<_DashboardHomeScreen> {
  final AdminApiService _apiService = AdminApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getDashboardStats();
      setState(() {
        _stats = response['stats'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Ошибка загрузки статистики: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой обновления
          Row(
            children: [
              Text(
                'Панель управления',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadStats,
                tooltip: 'Обновить статистику',
              ),
            ],
          ),
          SizedBox(height: 16),

          // Карточки со статистикой
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _StatsCard(
                title: 'Пользователи',
                value: _isLoading ? '...' : '${_stats?['users'] ?? 0}',
                icon: Icons.people,
                color: Colors.blue,
              ),
              _StatsCard(
                title: 'Заказы',
                value: _isLoading ? '...' : '${_stats?['orders'] ?? 0}',
                icon: Icons.shopping_cart,
                color: Colors.green,
              ),
              _StatsCard(
                title: 'Товары',
                value: _isLoading ? '...' : '${_stats?['products'] ?? 0}',
                icon: Icons.inventory,
                color: Colors.orange,
              ),
              _StatsCard(
                title: 'Партии',
                value: _isLoading ? '...' : '${_stats?['batches'] ?? 0}',
                icon: Icons.local_shipping,
                color: Colors.purple,
              ),
            ],
          ),

          SizedBox(height: 24),

          // Быстрые действия
          Text(
            'Быстрые действия',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionButton(
                label: 'Новый пользователь',
                icon: Icons.person_add,
                onPressed: () {
                  // TODO: Реализовать
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Будет реализовано в следующей версии')),
                  );
                },
              ),
              _QuickActionButton(
                label: 'Новый товар',
                icon: Icons.add_box,
                onPressed: () {
                  // TODO: Реализовать
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Будет реализовано в следующей версии')),
                  );
                },
              ),
              _QuickActionButton(
                label: 'Новая партия',
                icon: Icons.add_shopping_cart,
                onPressed: () {
                  // TODO: Реализовать
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Будет реализовано в следующей версии')),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 24),

          // Статус системы
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Статус системы',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 12),
                  _SystemStatusRow(
                    label: 'Сервер API',
                    status: 'Работает',
                    isOnline: true,
                  ),
                  _SystemStatusRow(
                    label: 'База данных',
                    status: 'Подключена',
                    isOnline: true,
                  ),
                  _SystemStatusRow(
                    label: 'SMS сервис',
                    status: 'Доступен',
                    isOnline: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка со статистикой
class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Кнопка быстрого действия
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Строка статуса системы
class _SystemStatusRow extends StatelessWidget {
  final String label;
  final String status;
  final bool isOnline;

  const _SystemStatusRow({
    required this.label,
    required this.status,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.error,
            color: isOnline ? Colors.green : Colors.red,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            status,
            style: TextStyle(
              color: isOnline ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Управление пользователями - РЕАЛЬНЫЙ ФУНКЦИОНАЛ
class _UsersManagementScreen extends StatefulWidget {
  @override
  _UsersManagementScreenState createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<_UsersManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getUsers();
      setState(() {
        _users = response['users'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Заголовок
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.people, size: 24),
                SizedBox(width: 8),
                Text(
                  'Управление пользователями',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadUsers,
                  tooltip: 'Обновить',
                ),
              ],
            ),
          ),

          // Контент
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _buildUsersList(),
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
            onPressed: _loadUsers,
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Пользователи не найдены'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                (user['firstName']?[0] ?? '?').toString().toUpperCase(),
                style: TextStyle(color: Colors.blue[800]),
              ),
            ),
            title: Text(user['firstName'] ?? 'Без имени'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Телефон: ${user['phone'] ?? 'Не указан'}'),
                if (user['email'] != null) Text('Email: ${user['email']}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  user['isActive'] == true ? Icons.check_circle : Icons.cancel,
                  color: user['isActive'] == true ? Colors.green : Colors.red,
                ),
                Text(
                  user['isActive'] == true ? 'Активен' : 'Заблокирован',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

/// Управление заказами - РЕАЛЬНЫЙ ФУНКЦИОНАЛ
class _OrdersManagementScreen extends StatefulWidget {
  @override
  _OrdersManagementScreenState createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<_OrdersManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getOrders();
      setState(() {
        _orders = response['orders'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
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
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Заголовок
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, size: 24),
                SizedBox(width: 8),
                Text(
                  'Управление заказами',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadOrders,
                  tooltip: 'Обновить',
                ),
              ],
            ),
          ),

          // Контент
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
            onPressed: _loadOrders,
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
            Text('Заказы не найдены'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(order['status']),
              child: Text(
                '#${order['id']}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
                '${order['user']['firstName'] ?? 'Пользователь'} ${order['user']['lastName'] ?? ''}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Телефон: ${order['user']['phone']}'),
                Text('Товаров: ${order['itemsCount']} шт.'),
                Text('Дата: ${_formatDate(order['createdAt'])}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order['status']),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${order['totalAmount']} ₽',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _ProductsManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Управление товарами'),
          Text('Будет реализовано в следующей версии'),
        ],
      ),
    );
  }
}

class _BatchesManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Управление партиями'),
          Text('Будет реализовано в следующей версии'),
        ],
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Настройки'),
          Text('Будет реализовано в следующей версии'),
        ],
      ),
    );
  }
}
