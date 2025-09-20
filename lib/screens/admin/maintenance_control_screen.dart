// lib/screens/admin/maintenance_control_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';

class MaintenanceControlScreen extends StatefulWidget {
  @override
  _MaintenanceControlScreenState createState() =>
      _MaintenanceControlScreenState();
}

class _MaintenanceControlScreenState extends State<MaintenanceControlScreen> {
  final AdminApiService _apiService = AdminApiService();
  final _messageController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _maintenanceEnabled = false;
  List<String> _allowedPhones = [];

  @override
  void initState() {
    super.initState();
    _loadMaintenanceStatus();
  }

  Future<void> _loadMaintenanceStatus() async {
    try {
      final response = await _apiService.getMaintenanceStatus();

      setState(() {
        final maintenance = response['maintenance'];
        _maintenanceEnabled = maintenance['enabled'] ?? false;
        _messageController.text = maintenance['message'] ??
            'Проводятся технические работы. Приложение временно недоступно.';
        _endTimeController.text = maintenance['end_time'] ?? '';
        _allowedPhones = List<String>.from(maintenance['allowed_phones'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  Future<void> _toggleMaintenance(bool value) async {
    setState(() => _maintenanceEnabled = value);

    try {
      await _apiService.updateMaintenanceMode(
        enabled: value,
        message: _messageController.text,
        endTime: _endTimeController.text,
        allowedPhones: _allowedPhones,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? '⛔ Режим обслуживания ВКЛЮЧЕН'
              : '✅ Режим обслуживания ВЫКЛЮЧЕН'),
          backgroundColor: value ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _maintenanceEnabled = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _addPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    try {
      await _apiService.addAllowedPhone(phone);

      setState(() {
        if (!_allowedPhones.contains(phone)) {
          _allowedPhones.add(phone);
        }
      });

      _phoneController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Телефон добавлен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _removePhone(String phone) async {
    try {
      await _apiService.removeAllowedPhone(phone);

      setState(() {
        _allowedPhones.remove(phone);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Телефон удален')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Режим обслуживания'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Режим обслуживания'),
        backgroundColor: _maintenanceEnabled ? Colors.orange : Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Главный переключатель
            Card(
              color: _maintenanceEnabled
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
              child: SwitchListTile(
                title: Text(
                  'Режим обслуживания',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _maintenanceEnabled
                      ? 'Приложение недоступно для пользователей'
                      : 'Приложение работает в штатном режиме',
                ),
                value: _maintenanceEnabled,
                onChanged: _toggleMaintenance,
                activeColor: Colors.orange,
              ),
            ),

            SizedBox(height: 20),

            // Сообщение для пользователей
            Text(
              'Сообщение для пользователей',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Введите сообщение...',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            // Время окончания
            Text(
              'Ориентировочное время окончания',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _endTimeController,
              decoration: InputDecoration(
                hintText: 'Например: 2 часа',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
            ),

            SizedBox(height: 20),

            // Белый список телефонов
            Text(
              'Белый список телефонов',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Эти пользователи смогут работать во время обслуживания',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      hintText: '+79001234567',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addPhone,
                  child: Icon(Icons.add),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(56, 56),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Список разрешенных телефонов
            ..._allowedPhones
                .map((phone) => Card(
                      child: ListTile(
                        leading: Icon(Icons.phone, color: Colors.green),
                        title: Text(phone),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removePhone(phone),
                        ),
                      ),
                    ))
                .toList(),

            if (_allowedPhones.isEmpty)
              Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('Белый список пуст'),
                  subtitle: Text('Только вы (+79142667582) сможете войти'),
                ),
              ),

            SizedBox(height: 20),

            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _toggleMaintenance(_maintenanceEnabled),
                child: Text('Сохранить изменения'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _endTimeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
