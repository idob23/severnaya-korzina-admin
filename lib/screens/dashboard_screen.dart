// lib/screens/dashboard_screen.dart - БАЗОВЫЙ DASHBOARD
import 'admin/orders_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:severnaya_korzina_admin/screens/add_product_screen.dart';
import '../providers/auth_provider.dart';
import '../services/admin_api_service.dart';
import '../../constants/order_status.dart';
import 'admin/batch_details_screen.dart';
import 'admin/system_settings_screen.dart';

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
    OrdersManagementScreen(),
    _ProductsManagementScreen(),
    _BatchesManagementScreen(),
    _MoneyCollectionScreen(), // <-- НОВЫЙ ЭКРАН ЗДЕСЬ
    SystemSettingsScreen(), // ДОБАВИТЬ
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

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    // Показываем диалог с выбором действия
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Управление пользователем'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Пользователь: ${user['firstName']} ${user['lastName'] ?? ''}'),
            Text('Телефон: ${user['phone']}'),
            SizedBox(height: 12),
            Text(
              'Выберите действие:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
                '• Деактивировать - пользователь не сможет войти, но данные сохранятся'),
            Text(
                '• Удалить - полное удаление из системы (только если нет заказов)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'deactivate'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text('Деактивировать'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Удалить навсегда'),
          ),
        ],
      ),
    );

    if (action == null) return;

    // Подтверждение действия
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'delete'
            ? 'Удалить пользователя?'
            : 'Деактивировать пользователя?'),
        content: Text(
          action == 'delete'
              ? 'Это действие нельзя отменить! Все данные будут удалены навсегда.'
              : 'Пользователь не сможет войти в систему, но его данные сохранятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: action == 'delete' ? Colors.red : Colors.orange,
            ),
            child: Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (action == 'delete') {
        await _apiService.deleteUser(user['id']);

        setState(() {
          _users.removeWhere((u) => u['id'] == user['id']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Пользователь удален'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _apiService.deactivateUser(user['id']);

        setState(() {
          final index = _users.indexWhere((u) => u['id'] == user['id']);
          if (index != -1) {
            _users[index]['isActive'] = false;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⛔ Пользователь деактивирован'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Обработка специфических ошибок
      if (errorMessage.contains('активными заказами')) {
        errorMessage =
            'У пользователя есть активные заказы. Сначала завершите их.';
      } else if (errorMessage.contains('заказов в истории')) {
        errorMessage =
            'У пользователя есть история заказов. Рекомендуется деактивация.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $errorMessage'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
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
            trailing: Row(
              // ✅ ИЗМЕНИТЬ trailing на Row
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      user['isActive'] == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      color:
                          user['isActive'] == true ? Colors.green : Colors.red,
                    ),
                    Text(
                      user['isActive'] == true ? 'Активен' : 'Заблокирован',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                SizedBox(width: 8), // ✅ ДОБАВИТЬ КНОПКУ УДАЛЕНИЯ
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteUser(user),
                  tooltip: 'Удалить пользователя',
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

/// Управление товарами - С ФУНКЦИЕЙ УПРАВЛЕНИЯ ОСТАТКАМИ
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
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'stock', 'category'

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
        _sortProducts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  void _sortProducts() {
    _products.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
        case 'stock':
          final aStock = a['maxQuantity'] ?? 999999;
          final bStock = b['maxQuantity'] ?? 999999;
          return aStock.compareTo(bStock);
        case 'category':
          final aCat = a['category']?['name'] ?? '';
          final bCat = b['category']?['name'] ?? '';
          return aCat.compareTo(bCat);
        default:
          return 0;
      }
    });
  }

  List<dynamic> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;

    return _products.where((product) {
      final name = (product['name'] ?? '').toLowerCase();
      final category = (product['category']?['name'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return Colors.grey;

    final categoryColors = {
      'Молочные': Colors.blue[300]!,
      'Мясные': Colors.red[300]!,
      'Хлебобулочные': Colors.orange[300]!,
      'Овощи и фрукты': Colors.green[300]!,
      'Напитки': Colors.purple[300]!,
      'Бакалея': Colors.brown[300]!,
      'Заморозка': Colors.cyan[300]!,
    };

    return categoryColors[category] ?? Colors.grey[300]!;
  }

  Color _getStockColor(int? maxQuantity) {
    if (maxQuantity == null) return Colors.grey;
    if (maxQuantity == 0) return Colors.red;
    if (maxQuantity <= 5) return Colors.orange;
    if (maxQuantity <= 20) return Colors.yellow[700]!;
    return Colors.green;
  }

  void _showStockEditDialog(Map<String, dynamic> product) {
    final controller =
        TextEditingController(text: product['maxQuantity']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text('Управление остатками'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информация о товаре
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${product['price']} ₽ / ${product['unit'] ?? 'шт'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (product['category'] != null)
                      Text(
                        'Категория: ${product['category']['name']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Текущий остаток
              Row(
                children: [
                  Text('Текущий остаток: '),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStockColor(product['maxQuantity'])
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _getStockColor(product['maxQuantity'])),
                    ),
                    child: Text(
                      product['maxQuantity']?.toString() ?? 'Неограничено',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStockColor(product['maxQuantity']),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Поле ввода нового остатка
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Новый остаток',
                  hintText: 'Оставьте пустым для снятия ограничения',
                  border: OutlineInputBorder(),
                  suffixText: product['unit'] ?? 'шт',
                  prefixIcon: Icon(Icons.edit),
                ),
              ),

              SizedBox(height: 16),

              // Кнопки быстрого добавления
              Text(
                'Быстрое добавление:',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [10, 20, 50, 100]
                    .map(
                      (amount) => ElevatedButton(
                        onPressed: () {
                          final current = int.tryParse(controller.text) ??
                              product['maxQuantity'] ??
                              0;
                          controller.text = (current + amount).toString();
                        },
                        child: Text('+$amount'),
                        style: ElevatedButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    )
                    .toList(),
              ),

              // Предупреждение о низких остатках
              if (product['maxQuantity'] != null && product['maxQuantity'] <= 5)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product['maxQuantity'] == 0
                              ? 'Товар закончился! Срочно пополните остатки.'
                              : 'Низкий остаток! Рекомендуется пополнить.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _updateProductStock(
                product['id'],
                controller.text.isEmpty ? null : int.tryParse(controller.text),
              );
            },
            icon: Icon(Icons.save),
            label: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProductStock(int productId, int? newStock) async {
    try {
      await _apiService.updateProduct(productId, {
        'maxQuantity': newStock,
      });

      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Остаток обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления остатка'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Подсчет товаров с низкими остатками
    final lowStockCount = _products
        .where((p) => p['maxQuantity'] != null && p['maxQuantity'] <= 5)
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Управление товарами'),
        backgroundColor: Colors.blue[600],
        actions: [
          // Индикатор низких остатков
          if (lowStockCount > 0)
            Container(
              margin: EdgeInsets.only(right: 8, top: 12, bottom: 12),
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '$lowStockCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProductScreen()),
              ).then((_) => _loadProducts());
            },
            tooltip: 'Добавить товар',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель поиска и фильтров
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                // Поиск
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск товара...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                SizedBox(width: 16),
                // Сортировка
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    underline: SizedBox(),
                    items: [
                      DropdownMenuItem(
                          value: 'name', child: Text('По названию')),
                      DropdownMenuItem(
                          value: 'stock', child: Text('По остаткам')),
                      DropdownMenuItem(
                          value: 'category', child: Text('По категории')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                        _sortProducts();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Список товаров
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
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Товары не найдены'),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() => _searchQuery = '');
                },
                child: Text('Сбросить поиск'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final stock = product['maxQuantity'];
        final isLowStock = stock != null && stock <= 5 && stock > 0;
        final isOutOfStock = stock != null && stock == 0;

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          color: isOutOfStock ? Colors.red[50] : null,
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getCategoryColor(product['category']?['name']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                  if (stock != null)
                    Text(
                      stock.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    product['name'] ?? 'Без названия',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Индикатор остатка
                if (stock != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStockColor(stock),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stock == 0 ? 'НЕТ' : stock.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product['price']} ₽/${product['unit'] ?? "шт"} • ${product['category']?['name'] ?? "Без категории"}',
                  style: TextStyle(fontSize: 12),
                ),
                if (isLowStock || isOutOfStock)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 12,
                          color: isOutOfStock ? Colors.red : Colors.orange,
                        ),
                        SizedBox(width: 4),
                        Text(
                          isOutOfStock ? 'Нет в наличии!' : 'Мало остатков!',
                          style: TextStyle(
                            color: isOutOfStock ? Colors.red : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.inventory, color: Colors.blue),
                  onPressed: () => _showStockEditDialog(product),
                  tooltip: 'Управление остатками',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(product),
                  tooltip: 'Удалить товар',
                ),
              ],
            ),
            onTap: () => _showStockEditDialog(product),
          ),
        );
      },
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить товар?'),
        content: Text('Вы действительно хотите удалить "${product['name']}"?'),
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
        await _apiService.deleteProduct(product['id']);
        await _loadProducts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Товар удален'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления товара'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Управление партиями - РЕАЛЬНЫЙ ФУНКЦИОНАЛ С НАВИГАЦИЕЙ
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

  // ✅ ДОБАВИТЬ ЭТИ ПЕРЕМЕННЫЕ:
  int? _editingBatchId;
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose(); // ✅ ДОБАВИТЬ
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  // ✅ ДОБАВИТЬ ЭТИ МЕТОДЫ:
  void _startEditingTitle(Map<String, dynamic> batch) {
    setState(() {
      _editingBatchId = batch['id'];
      _titleController.text = batch['title'] ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingBatchId = null;
      _titleController.clear();
    });
  }

  Future<void> _saveTitle() async {
    if (_editingBatchId == null) return;

    try {
      await _apiService.updateBatchTitle(
          _editingBatchId!, _titleController.text.trim());

      // Обновляем название в списке
      setState(() {
        final batchIndex =
            _batches.indexWhere((b) => b['id'] == _editingBatchId);
        if (batchIndex != -1) {
          _batches[batchIndex]['title'] = _titleController.text.trim();
        }
        _editingBatchId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Название обновлено')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
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

  Future<void> _deleteBatch(Map<String, dynamic> batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить партию?'),
        content: Text(
            'Партия "${batch['title']}" будет удалена навсегда. Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteBatch(batch['id']);

      setState(() {
        _batches.removeWhere((b) => b['id'] == batch['id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Партия удалена')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Активна';
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
        return _buildBatchCard(batch);
      },
    );
  }

  // Замените метод _buildBatchCard в _BatchesManagementScreenState:

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    final targetAmount = _safeDouble(batch['targetAmount']);
    final currentAmount = _safeDouble(batch['currentAmount']);
    final progressPercent = _safeDouble(batch['progressPercent']);
    final participantsCount = _safeInt(batch['participantsCount']);
    final ordersCount = _safeInt(batch['ordersCount']);
    final isEditing = _editingBatchId == batch['id']; // ✅ ДОБАВИТЬ

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: InkWell(
        onTap: isEditing ? null : () => _openBatchDetails(batch), // ✅ ИЗМЕНИТЬ
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ ЗАМЕНИТЬ ЗАГОЛОВОК:
              Row(
                children: [
                  Expanded(
                    child: isEditing
                        ? TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onSubmitted: (_) => _saveTitle(),
                          )
                        : Text(
                            batch['title'] ?? 'Без названия',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  if (isEditing) ...[
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: _saveTitle,
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: _cancelEditing,
                    ),
                  ] else ...[
                    IconButton(
                      icon: Icon(Icons.edit, size: 20),
                      onPressed: () => _startEditingTitle(batch),
                      tooltip: 'Редактировать название',
                    ),
                    IconButton(
                      // ✅ ДОБАВИТЬ ЭТУ КНОПКУ
                      icon: Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteBatch(batch),
                      tooltip: 'Удалить партию',
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                ],
              ),

              // ... остальная часть карточки остается без изменений
              if (batch['description'] != null) ...[
                SizedBox(height: 8),
                Text(
                  batch['description'],
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                            Icons.people, 'Участников: $participantsCount'),
                        _buildInfoRow(
                            Icons.shopping_cart, 'Заказов: $ordersCount'),
                        _buildInfoRow(Icons.account_balance_wallet,
                            'Собрано: ${currentAmount.toStringAsFixed(0)}₽'),
                        _buildInfoRow(Icons.flag,
                            'Цель: ${targetAmount.toStringAsFixed(0)}₽'),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    children: [
                      CircularProgressIndicator(
                        value: progressPercent / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(batch['status'])),
                        strokeWidth: 8,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${progressPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(batch['status']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// ✅ НОВЫЙ МЕТОД: Реальные индикаторы статусов заказов
  Widget _buildRealOrderStatusIndicators(Map<String, dynamic> orderStats) {
    final pending = _safeInt(orderStats['pending']);
    final paid = _safeInt(orderStats['paid']);
    final shipped = _safeInt(orderStats['shipped']);
    final delivered = _safeInt(orderStats['delivered']);
    final cancelled = _safeInt(orderStats['cancelled']);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (pending > 0) _buildStatusBadge(Colors.orange, 'Ожидают', pending),
        if (paid > 0) _buildStatusBadge(Colors.green, 'Оплачены', paid),
        if (shipped > 0) _buildStatusBadge(Colors.blue, 'Отправлены', shipped),
        if (delivered > 0)
          _buildStatusBadge(Colors.green[700]!, 'Доставлены', delivered),
        if (cancelled > 0) _buildStatusBadge(Colors.red, 'Отменены', cancelled),
      ],
    );
  }

// ✅ НОВЫЙ МЕТОД: Бейдж со статусом и количеством
  Widget _buildStatusBadge(Color color, String label, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusIndicator() {
    // Простые индикаторы - будут улучшены после получения данных о заказах
    return Row(
      children: [
        _buildStatusDot(Colors.orange, 'Ожидают'),
        SizedBox(width: 8),
        _buildStatusDot(Colors.green, 'Оплачены'),
        SizedBox(width: 8),
        _buildStatusDot(Colors.blue, 'Отправлены'),
        SizedBox(width: 8),
        _buildStatusDot(Colors.green[700]!, 'Доставлены'),
      ],
    );
  }

  Widget _buildStatusDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 30) return Colors.red;
    if (progress < 70) return Colors.orange;
    if (progress < 90) return Colors.blue;
    return Colors.green;
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

  // ✅ КЛЮЧЕВОЙ МЕТОД - Навигация к детальному экрану
  void _openBatchDetails(Map<String, dynamic> batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchDetailsScreen(batch: batch),
      ),
    );
  }

  // Вспомогательные методы
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
}

/// Экран настроек с управлением оформлением заказов
class _SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  final AdminApiService _apiService = AdminApiService();
  bool _checkoutEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем текущий статус с сервера
      final response = await _apiService.getCheckoutEnabled();
      if (mounted) {
        setState(() {
          _checkoutEnabled = response['checkoutEnabled'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки настроек: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleCheckout(bool value) async {
    // Сразу меняем UI для отзывчивости
    setState(() {
      _checkoutEnabled = value;
    });

    try {
      // Отправляем изменение на сервер
      final response = await _apiService.setCheckoutEnabled(value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '✅ Оформление заказов включено'
                  : '⛔ Оформление заказов выключено',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // При ошибке откатываем изменение
      if (mounted) {
        setState(() {
          _checkoutEnabled = !value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: не удалось изменить настройку'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка настроек...'),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Заголовок
                Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Настройки приложения',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Карточка управления оформлением заказов
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок секции
                        Row(
                          children: [
                            Icon(Icons.shopping_cart,
                                color: Colors.blue[700], size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Управление заказами',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Основной переключатель
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _checkoutEnabled
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _checkoutEnabled
                                  ? Colors.green[400]!
                                  : Colors.red[400]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Иконка статуса
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _checkoutEnabled
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _checkoutEnabled
                                      ? Icons.check_circle_outline
                                      : Icons.block,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),

                              SizedBox(width: 16),

                              // Текст статуса
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Оформление заказов',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _checkoutEnabled
                                          ? 'Пользователи могут оформлять заказы'
                                          : 'Оформление заказов заблокировано',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Переключатель
                              Transform.scale(
                                scale: 1.2,
                                child: Switch(
                                  value: _checkoutEnabled,
                                  onChanged: _toggleCheckout,
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.red,
                                  inactiveTrackColor: Colors.red[200],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        // Информационная панель
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue[700], size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Используйте этот переключатель для временной блокировки оформления новых заказов. Пользователи увидят уведомление в корзине.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Дополнительная информационная карточка
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Когда использовать блокировку:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow('• При подготовке к отправке заказов'),
                        _buildInfoRow('• Во время технических работ'),
                        _buildInfoRow('• При обновлении каталога товаров'),
                        _buildInfoRow('• В период инвентаризации'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
        ),
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

  // ДОБАВИТЬ ЭТИ ПЕРЕМЕННЫЕ:
  Map<String, dynamic>? _activeBatch;
  bool _isLoadingBatch = false;

  @override
  void initState() {
    super.initState();
    // Устанавливаем значение по умолчанию (3 млн рублей)
    _targetAmountController.text = '3000000';
    _loadBatchStatus(); // ДОБАВИТЬ ЭТУ СТРОКУ!
  }

  // ДОБАВИТЬ ЭТОТ МЕТОД:
  Future<void> _loadBatchStatus() async {
    setState(() {
      _isLoadingBatch = true;
    });

    try {
      final response = await _apiService.getActiveBatch();
      if (response['success'] == true) {
        setState(() {
          _activeBatch = response['batch'];
          _isLoadingBatch = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки статуса партии: $e');
      setState(() {
        _isLoadingBatch = false;
      });
    }
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

            // ДОБАВИТЬ БЛОК ОТОБРАЖЕНИЯ ТЕКУЩЕЙ ПАРТИИ:
            if (_activeBatch != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Активная партия',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Название: ${_activeBatch!['title']}'),
                      Text('Цель: ${_activeBatch!['targetAmount']}₽'),
                      Text('Собрано: ${_activeBatch!['currentAmount']}₽'),
                      Text('Прогресс: ${_activeBatch!['progressPercent']}%'),
                      Text('Участников: ${_activeBatch!['participantsCount']}'),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 24),

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
