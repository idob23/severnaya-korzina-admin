// lib/screens/dashboard_screen.dart - БАЗОВЫЙ DASHBOARD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:severnaya_korzina_admin/screens/add_product_screen.dart';
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
    _MoneyCollectionScreen(), // <-- НОВЫЙ ЭКРАН ЗДЕСЬ
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
      // <-- НОВАЯ ВКЛАДКА ЗДЕСЬ
      icon: Icon(Icons.attach_money),
      label: 'Сбор денег',
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
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio:
                0.85, // ДОБАВЛЕНО: соотношение сторон для компактности
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddProductScreen(),
                    ),
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

/// Управление товарами - РЕАЛЬНЫЙ ФУНКЦИОНАЛ
class _ProductsManagementScreen extends StatefulWidget {
  @override
  _ProductsManagementScreenState createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<_ProductsManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getProducts();
      setState(() {
        _products = response['products'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  Color _getCategoryColor(String? categoryName) {
    if (categoryName == null) return Colors.grey;

    switch (categoryName.toLowerCase()) {
      case 'молочные продукты':
        return Colors.blue;
      case 'мясо и птица':
        return Colors.red;
      case 'хлебобулочные изделия':
        return Colors.orange;
      case 'овощи и фрукты':
        return Colors.green;
      case 'крупы и макароны':
        return Colors.purple;
      default:
        return Colors.grey;
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
                Icon(Icons.inventory, size: 24),
                SizedBox(width: 8),
                Text(
                  'Управление товарами',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadProducts,
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
                    : _buildProductsList(),
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
            onPressed: _loadProducts,
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Товары не найдены'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getCategoryColor(product['category']?['name']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_bag,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              product['name'] ?? 'Без названия',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Категория: ${product['category']?['name'] ?? 'Не указана'}'),
                Text('Единица: ${product['unit'] ?? 'шт'}'),
                if (product['description'] != null)
                  Text(
                    product['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product['price']} ₽',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        product['isActive'] == true ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product['isActive'] == true ? 'Активен' : 'Скрыт',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
}

/// Управление партиями - РЕАЛЬНЫЙ ФУНКЦИОНАЛ
class _BatchesManagementScreen extends StatefulWidget {
  @override
  _BatchesManagementScreenState createState() =>
      _BatchesManagementScreenState();
}

class _BatchesManagementScreenState extends State<_BatchesManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _batches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getBatches();
      setState(() {
        _batches = response['batches'] ?? [];
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
      case 'active':
        return Colors.green;
      case 'closed':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Активна';
      case 'closed':
        return 'Закрыта';
      case 'completed':
        return 'Завершена';
      case 'cancelled':
        return 'Отменена';
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
                Icon(Icons.local_shipping, size: 24),
                SizedBox(width: 8),
                Text(
                  'Управление партиями',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadBatches,
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
                    : _buildBatchesList(),
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
            onPressed: _loadBatches,
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesList() {
    if (_batches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Партии не найдены'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _batches.length,
      itemBuilder: (context, index) {
        final batch = _batches[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок партии
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        batch['title'] ?? 'Без названия',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(batch['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(batch['status']),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                if (batch['description'] != null) ...[
                  SizedBox(height: 8),
                  Text(
                    batch['description'],
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: 12),

                // Информация о партии
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.people,
                              'Участников: ${batch['participantsCount']}/${batch['minParticipants']}'),
                          _buildInfoRow(Icons.shopping_bag,
                              'Товаров: ${batch['productsCount']}'),
                          _buildInfoRow(Icons.calendar_today,
                              'Окончание: ${_formatDate(batch['endDate'])}'),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Сумма:',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          '${batch['totalValue']} ₽',
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

                // Прогресс-бар участников
                if (batch['status'] == 'active') ...[
                  SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Прогресс набора участников',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (batch['participantsCount'] /
                                batch['minParticipants'])
                            .clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          batch['participantsCount'] >= batch['minParticipants']
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
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

// lib/screens/dashboard_screen.dart - ШАГ 2: ЗАМЕНЯЕМ ЗАГЛУШКУ НА РЕАЛЬНЫЙ ЭКРАН

// Замените класс _MoneyCollectionScreen на этот код:

/// Экран управления сбором денег - ИСПРАВЛЕННАЯ ВЕРСИЯ
class _MoneyCollectionScreen extends StatefulWidget {
  @override
  _MoneyCollectionScreenState createState() => _MoneyCollectionScreenState();
}

class _MoneyCollectionScreenState extends State<_MoneyCollectionScreen> {
  final AdminApiService _apiService = AdminApiService(); // ДОБАВИЛИ ЭТУ СТРОКУ
  final _targetAmountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Устанавливаем значение по умолчанию (3 млн рублей)
    _targetAmountController.text = '3000000';
  }

  @override
  void dispose() {
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Управление сбором денег',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            SizedBox(height: 32),

            // Поле для целевой суммы
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Целевая сумма для сбора',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _targetAmountController,
                      decoration: InputDecoration(
                        labelText: 'Сумма в рублях',
                        prefixText: '₽ ',
                        border: OutlineInputBorder(),
                        hintText: 'Например: 3000000',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Кнопки управления
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Управление сбором',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 16),

                    // Кнопка "Начать сбор"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _startCollection,
                        icon: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.play_arrow),
                        label: Text('Начать сбор денег'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Кнопка "Завершить сбор"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _stopCollection,
                        icon: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.stop),
                        label: Text('Завершить сбор денег'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Информация
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Как это работает',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Установите целевую сумму для коллективной закупки\n'
                      '• Нажмите "Начать сбор" - откроется прием заказов\n'
                      '• Пользователи смогут делать заказы через приложение\n'
                      '• Когда накопится нужная сумма, нажмите "Завершить сбор"',
                      style: TextStyle(color: Colors.blue[700]),
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

  // РЕАЛЬНЫЙ МЕТОД - Начать сбор денег
  Future<void> _startCollection() async {
    final targetAmount = _targetAmountController.text.trim();

    if (targetAmount.isEmpty) {
      _showSnackBar('Введите целевую сумму', isError: true);
      return;
    }

    final amount = double.tryParse(targetAmount);
    if (amount == null || amount <= 0) {
      _showSnackBar('Введите корректную сумму', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ВЫЗЫВАЕМ РЕАЛЬНЫЙ API
      final response = await _apiService.startMoneyCollection(
        targetAmount: amount,
        title:
            'Коллективная закупка ${DateTime.now().day}.${DateTime.now().month}',
      );

      if (response['success'] == true) {
        _showSnackBar(response['message'] ?? 'Сбор денег начат!');
      } else {
        _showSnackBar(response['error'] ?? 'Ошибка запуска сбора',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Ошибка: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // РЕАЛЬНЫЙ МЕТОД - Завершить сбор денег
  Future<void> _stopCollection() async {
    setState(() => _isLoading = true);

    try {
      // ВЫЗЫВАЕМ РЕАЛЬНЫЙ API
      final response = await _apiService.stopMoneyCollection();

      if (response['success'] == true) {
        _showSnackBar(response['message'] ?? 'Сбор денег завершен!');
      } else {
        _showSnackBar(response['error'] ?? 'Ошибка завершения сбора',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Ошибка: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ДОБАВИЛИ НЕДОСТАЮЩИЙ МЕТОД - Показать уведомление
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
