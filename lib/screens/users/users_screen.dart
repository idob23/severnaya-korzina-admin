// screens/users/users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:severnaya_korzina_admin/providers/users_provider.dart';
import 'package:severnaya_korzina_admin/models/user.dart';

class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

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
                'Управление пользователями',
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
                    hintText: 'Поиск пользователей...',
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
                onPressed: _showAddUserDialog,
                icon: Icon(Icons.add),
                label: Text('Добавить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Фильтры и статистика
          Row(
            children: [
              _buildFilterChip('Все', 'all'),
              SizedBox(width: 8),
              _buildFilterChip('Активные', 'active'),
              SizedBox(width: 8),
              _buildFilterChip('Заблокированные', 'blocked'),
              SizedBox(width: 8),
              _buildFilterChip('Не верифицированные', 'unverified'),
              Spacer(),
              Consumer<UsersProvider>(
                builder: (context, usersProvider, child) {
                  final stats = usersProvider.getUsersStats();
                  return Row(
                    children: [
                      _buildStatChip('Всего: ${stats['total']}', Colors.blue),
                      SizedBox(width: 8),
                      _buildStatChip(
                          'Активных: ${stats['active']}', Colors.green),
                      SizedBox(width: 8),
                      _buildStatChip('Новых сегодня: ${stats['new_today']}',
                          Colors.orange),
                    ],
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 16),

          // Таблица пользователей
          Expanded(
            child: Card(
              elevation: 2,
              child: Consumer<UsersProvider>(
                builder: (context, usersProvider, child) {
                  if (usersProvider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final users = _getFilteredUsers(usersProvider);

                  return DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 800,
                    columns: [
                      DataColumn2(
                        label: Text('Пользователь',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('Телефон',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Статус',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Text('Заказы',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Text('Потрачено',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Text('Дата регистрации',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Действия',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        size: ColumnSize.S,
                        fixedWidth: 120,
                      ),
                    ],
                    rows: users
                        .map((user) => _buildUserRow(user, usersProvider))
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
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

  DataRow _buildUserRow(AdminUser user, UsersProvider usersProvider) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    user.isActive ? Colors.green[100] : Colors.red[100],
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(
                    color: user.isActive ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (user.isVerified)
                      Row(
                        children: [
                          Icon(Icons.verified, size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Верифицирован',
                            style: TextStyle(
                              fontSize: 10,
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
        DataCell(
          Text(user.phone),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: user.isActive ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.isActive ? Colors.green[200]! : Colors.red[200]!,
              ),
            ),
            child: Text(
              user.status,
              style: TextStyle(
                color: user.isActive ? Colors.green[800] : Colors.red[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Text(user.totalOrders.toString()),
        ),
        DataCell(
          Text('${user.totalSpent.toStringAsFixed(0)} ₽'),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDate(user.createdAt),
                style: TextStyle(fontSize: 12),
              ),
              if (user.lastLoginAt != null)
                Text(
                  'Был: ${_formatDate(user.lastLoginAt!)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 18),
                onPressed: () => _showEditUserDialog(user),
                tooltip: 'Редактировать',
              ),
              IconButton(
                icon: Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  size: 18,
                  color: user.isActive ? Colors.red : Colors.green,
                ),
                onPressed: () => _toggleUserStatus(user, usersProvider),
                tooltip: user.isActive ? 'Заблокировать' : 'Активировать',
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<AdminUser> _getFilteredUsers(UsersProvider usersProvider) {
    List<AdminUser> users = usersProvider.searchUsers(_searchQuery);

    switch (_selectedFilter) {
      case 'active':
        users = users.where((user) => user.isActive).toList();
        break;
      case 'blocked':
        users = users.where((user) => !user.isActive).toList();
        break;
      case 'unverified':
        users = users.where((user) => !user.isVerified).toList();
        break;
    }

    // Сортировка по дате создания (новые сверху)
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return users;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  Future<void> _toggleUserStatus(
      AdminUser user, UsersProvider usersProvider) async {
    try {
      await usersProvider.toggleUserStatus(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isActive
                ? 'Пользователь ${user.fullName} заблокирован'
                : 'Пользователь ${user.fullName} активирован',
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
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => UserEditDialog(),
    );
  }

  void _showEditUserDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => UserEditDialog(user: user),
    );
  }
}

class UserEditDialog extends StatefulWidget {
  final AdminUser? user;

  UserEditDialog({this.user});

  @override
  _UserEditDialogState createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  bool _isActive = true;
  bool _isVerified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _lastNameController =
        TextEditingController(text: widget.user?.lastName ?? '');
    _isActive = widget.user?.isActive ?? true;
    _isVerified = widget.user?.isVerified ?? false;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null
          ? 'Добавить пользователя'
          : 'Редактировать пользователя'),
      content: Container(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  prefixText: '+7',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер телефона';
                  }
                  if (value.length != 10) {
                    return 'Номер должен содержать 10 цифр';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              CheckboxListTile(
                title: Text('Активный пользователь'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Верифицированный'),
                value: _isVerified,
                onChanged: (value) {
                  setState(() {
                    _isVerified = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUser,
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.user == null ? 'Добавить' : 'Сохранить'),
        ),
      ],
    );
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final usersProvider = Provider.of<UsersProvider>(context, listen: false);
      final user = AdminUser(
        id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        phone: '+7${_phoneController.text}',
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
        isActive: _isActive,
        isVerified: _isVerified,
        lastLoginAt: widget.user?.lastLoginAt,
        createdAt: widget.user?.createdAt ?? DateTime.now(),
        totalOrders: widget.user?.totalOrders ?? 0,
        totalSpent: widget.user?.totalSpent ?? 0,
      );

      if (widget.user == null) {
        await usersProvider.addUser(user);
      } else {
        await usersProvider.updateUser(user);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.user == null
                ? 'Пользователь добавлен'
                : 'Пользователь обновлен',
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
