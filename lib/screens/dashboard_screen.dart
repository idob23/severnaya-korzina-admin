// lib/screens/dashboard_screen.dart - БАЗОВЫЙ DASHBOARD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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

/// Главная страница dashboard
class _DashboardHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Панель управления',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                value: '...',
                icon: Icons.people,
                color: Colors.blue,
              ),
              _StatsCard(
                title: 'Заказы',
                value: '...',
                icon: Icons.shopping_cart,
                color: Colors.green,
              ),
              _StatsCard(
                title: 'Товары',
                value: '...',
                icon: Icons.inventory,
                color: Colors.orange,
              ),
              _StatsCard(
                title: 'Партии',
                value: '...',
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

/// Заглушки для остальных экранов (будем реализовывать по частям)
class _UsersManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Управление пользователями'),
          Text('Будет реализовано в следующей версии'),
        ],
      ),
    );
  }
}

class _OrdersManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Управление заказами'),
          Text('Будет реализовано в следующей версии'),
        ],
      ),
    );
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
