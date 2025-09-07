import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  @override
  _SystemSettingsScreenState createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final AdminApiService _apiService = AdminApiService();
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  // Контроллеры для полей
  final _marginController = TextEditingController();
  String _selectedVatCode = '6';
  String _selectedPaymentMode = 'test';
  bool _enableTestCards = true;
  bool _checkoutEnabled = true;

  final Map<String, String> vatCodes = {
    '1': 'НДС 20%',
    '2': 'НДС 10%',
    '3': 'НДС 20/120',
    '4': 'НДС 10/110',
    '5': 'НДС 0%',
    '6': 'Без НДС (УСН)',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCheckoutStatus(); // <- Добавить эту строку
  }

  Future<void> _loadSettings() async {
    try {
      final response = await _apiService.getSystemSettings();
      setState(() {
        _settings = response['settings'] ?? {};
        _marginController.text =
            _settings['default_margin_percent']?['value'] ?? '20';
        _selectedVatCode = _settings['vat_code']?['value'] ?? '6';
        _selectedPaymentMode = _settings['payment_mode']?['value'] ?? 'test';
        _enableTestCards = _settings['enable_test_cards']?['value'] == 'true';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки настроек: $e')),
      );
    }
  }

  Future<void> _loadCheckoutStatus() async {
    try {
      final response = await _apiService.getCheckoutEnabled();
      if (mounted) {
        setState(() {
          _checkoutEnabled = response['checkoutEnabled'] ?? true;
        });
      }
    } catch (e) {
      print('Ошибка загрузки статуса checkout: $e');
    }
  }

  Future<void> _toggleCheckout(bool value) async {
    setState(() {
      _checkoutEnabled = value;
    });

    try {
      await _apiService.setCheckoutEnabled(value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '✅ Оформление заказов включено'
                  : '⛔ Оформление заказов выключено',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Откат при ошибке
      if (mounted) {
        setState(() {
          _checkoutEnabled = !value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: не удалось изменить настройку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    try {
      await _apiService.updateSystemSetting(key, value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Настройка сохранена'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSettings(); // Перезагружаем настройки
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Настройки системы')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки системы'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Управление заказами',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Переключатель оформления заказов
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _checkoutEnabled ? Colors.green[50] : Colors.red[50],
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
                            color: _checkoutEnabled ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _checkoutEnabled ? Icons.check_circle : Icons.block,
                            color: Colors.white,
                            size: 28,
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
                                    : 'Оформление заказов временно заблокировано',
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
                            inactiveTrackColor: Colors.red[200]!,
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
                            'Используйте этот переключатель для временной блокировки оформления новых заказов во время технических работ или при отсутствии активной закупки.',
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

          SizedBox(height: 16),

          // Секция платежей
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Настройки платежей',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Режим платежей
                  Row(
                    children: [
                      Expanded(
                        child: Text('Режим платежей:'),
                      ),
                      DropdownButton<String>(
                        value: _selectedPaymentMode,
                        items: [
                          DropdownMenuItem(
                            value: 'test',
                            child: Text('Тестовый'),
                          ),
                          DropdownMenuItem(
                            value: 'production',
                            child: Text('Боевой'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedPaymentMode = value!);
                          _saveSetting('payment_mode', value!);
                        },
                      ),
                    ],
                  ),

                  // Тестовые карты
                  SwitchListTile(
                    title: Text('Разрешить тестовые карты'),
                    subtitle: Text('В боевом режиме'),
                    value: _enableTestCards,
                    onChanged: (value) {
                      setState(() => _enableTestCards = value);
                      _saveSetting('enable_test_cards', value.toString());
                    },
                  ),

                  if (_enableTestCards && _selectedPaymentMode == 'production')
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Тестовые карты:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text('✅ Успех: 5555 5555 5555 4444'),
                          Text('❌ Отказ: 5555 5555 5555 4446'),
                          Text('CVV: любые 3 цифры, 3DS: 123456'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Секция налогов и маржи
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Налоги и комиссии',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 20),

                  // НДС
                  Row(
                    children: [
                      Expanded(
                        child: Text('Система НДС:'),
                      ),
                      DropdownButton<String>(
                        value: _selectedVatCode,
                        items: vatCodes.entries.map((e) {
                          return DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedVatCode = value!);
                          _saveSetting('vat_code', value!);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Маржа по умолчанию
                  TextField(
                    controller: _marginController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Маржа по умолчанию (%)',
                      hintText: 'От 0 до 100',
                      suffix: Text('%'),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      final margin = double.tryParse(value);
                      if (margin != null && margin >= 0 && margin <= 100) {
                        _saveSetting('default_margin_percent', value);
                      }
                    },
                  ),

                  SizedBox(height: 8),
                  Text(
                    'Используется для новых партий',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Информационная карточка
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Text(
                        'Как это работает',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Маржа по умолчанию применяется к новым партиям\n'
                    '• Для каждой партии можно установить свою маржу\n'
                    '• В чеке автоматически формируются две позиции:\n'
                    '  - Товары (сумма без маржи)\n'
                    '  - Услуга организации (маржа)\n'
                    '• НДС применяется к обеим позициям',
                    style: TextStyle(fontSize: 13),
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
