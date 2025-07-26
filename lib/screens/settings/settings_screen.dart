// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:severnaya_korzina_admin/providers/admin_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                'Настройки системы',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              ElevatedButton.icon(
                onPressed: _saveAllSettings,
                icon: Icon(Icons.save),
                label: Text('Сохранить все'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Вкладки
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[800],
            tabs: [
              Tab(text: 'Общие'),
              Tab(text: 'Платежи'),
              Tab(text: 'Уведомления'),
              Tab(text: 'Система'),
            ],
          ),
          SizedBox(height: 16),

          // Содержимое вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralSettings(),
                _buildPaymentSettings(),
                _buildNotificationSettings(),
                _buildSystemSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSettingsSection(
            'Информация о магазине',
            [
              _buildTextSetting(
                  'Название магазина', 'Северная корзина', 'Основное название'),
              _buildTextSetting('Описание', 'Коллективные закупки в Усть-Нере',
                  'Краткое описание'),
              _buildTextSetting(
                  'Адрес', 'г. Усть-Нера, ул. Ленина, 15', 'Физический адрес'),
              _buildTextSetting(
                  'Телефон', '+7 (914) 123-45-67', 'Контактный телефон'),
              _buildTextSetting(
                  'Email', 'info@severnaya-korzina.ru', 'Email для связи'),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingsSection(
            'Параметры закупок',
            [
              _buildNumberSetting('Минимальное количество участников', 5,
                  'Для запуска закупки'),
              _buildNumberSetting('Максимальное количество участников', 100,
                  'Лимит участников'),
              _buildNumberSetting(
                  'Процент предоплаты', 90, 'Размер предоплаты (%)'),
              _buildNumberSetting(
                  'Срок действия закупки (дни)', 14, 'По умолчанию'),
              _buildSwitchSetting(
                  'Автоматическое закрытие', true, 'При достижении лимита'),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingsSection(
            'Пункты выдачи',
            [
              _buildTextSetting(
                  'Основной пункт',
                  'ул. Ленина, 15, магазин "Северянка"',
                  'Главный пункт выдачи'),
              _buildTextSetting('Режим работы',
                  'Пн-Пт: 9:00-19:00, Сб: 10:00-16:00', 'График работы'),
              _buildTextSetting(
                  'Контакт', '+7 (914) 123-45-67', 'Телефон пункта выдачи'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSettings() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSettingsSection(
            'ЮKassa настройки',
            [
              _buildTextSetting('Shop ID', '123456', 'Идентификатор магазина'),
              _buildPasswordSetting(
                  'Secret Key', 'test_***...***', 'Секретный ключ'),
              _buildDropdownSetting(
                  'Режим работы', 'Тестовый', ['Тестовый', 'Продакшн']),
              _buildSwitchSetting('Автоматическое подтверждение', true,
                  'Авто-подтверждение платежей'),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingsSection(
            'Способы оплаты',
            [
              _buildSwitchSetting('Карты МИР', true, 'Принимать карты МИР'),
              _buildSwitchSetting('СБП', true, 'Система быстрых платежей'),
              _buildSwitchSetting(
                  'Наличные при получении', false, 'Оплата при выдаче'),
              _buildNumberSetting(
                  'Комиссия СБП (%)', 0, 'Дополнительная комиссия'),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingsSection(
            'Возвраты и отмены',
            [
              _buildNumberSetting('Срок для отмены (часы)', 24,
                  'До автоматического подтверждения'),
              _buildSwitchSetting(
                  'Автоматические возвраты', true, 'При отмене заказа'),
              _buildNumberSetting(
                  'Срок обработки возврата (дни)', 7, 'Время обработки'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSettingsSection(
            'SMS уведомления',
            [
              _buildTextSetting('SMS провайдер', 'SMSC.ru', 'Поставщик SMS'),
              _buildPasswordSetting('API ключ', '***...***', 'Ключ доступа'),
              _buildSwitchSetting(
                  'SMS при регистрации', true, 'Отправлять код подтверждения'),
              _buildSwitchSetting(
                  'SMS о статусе заказа', true, 'Уведомления о изменениях'),
              _buildSwitchSetting(
                  'SMS о готовности к выдаче', true, 'Когда заказ готов'),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingsSection(
            'Push уведомления',
            [
              _buildSwitchSetting(
                  'Push уведомления', true, 'Включить push-уведомления'),
              _buildSwitchSetting(
                  'О новых закупках', true, 'Уведомлять о новых предложениях'),
              _buildSwitchSetting(
                  'О статусе заказов', true, 'Изменения в заказах'),
              _buildSwitchSetting(
                  'Маркетинговые', false, 'Акции и предложения'),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingsSection(
            'Email уведомления',
            [
              _buildTextSetting(
                  'SMTP сервер', 'smtp.yandex.ru', 'Сервер для отправки'),
              _buildTextSetting('Порт', '587', 'Порт подключения'),
              _buildTextSetting(
                  'Логин', 'noreply@severnaya-korzina.ru', 'Email отправителя'),
              _buildPasswordSetting('Пароль', '***...***', 'Пароль от email'),
              _buildSwitchSetting(
                  'Email чеки', true, 'Отправлять чеки на email'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSettingsSection(
            'Безопасность',
            [
              _buildNumberSetting(
                  'Время сессии (минуты)', 60, 'Автовыход из админки'),
              _buildSwitchSetting(
                  'Двухфакторная аутентификация', false, 'Для администраторов'),
              _buildNumberSetting(
                  'Макс. попыток входа', 5, 'Блокировка после превышения'),
              _buildSwitchSetting(
                  'Логирование действий', true, 'Сохранять лог операций'),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingsSection(
            'Резервные копии',
            [
              _buildSwitchSetting(
                  'Автоматические бэкапы', true, 'Ежедневное сохранение'),
              _buildDropdownSetting('Время бэкапа', '03:00',
                  ['02:00', '03:00', '04:00', '05:00']),
              _buildNumberSetting('Хранить копий (дни)', 30, 'Срок хранения'),
              _buildActionSetting('Создать бэкап сейчас',
                  'Немедленное создание копии', _createBackup),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingsSection(
            'Техническое обслуживание',
            [
              _buildActionSetting(
                  'Очистить кеш', 'Удалить временные файлы', _clearCache),
              _buildActionSetting('Проверить соединения',
                  'Тест подключений к сервисам', _testConnections),
              _buildActionSetting(
                  'Экспорт данных', 'Выгрузить все данные', _exportData),
              _buildActionSetting(
                  'Импорт данных', 'Загрузить данные из файла', _importData),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingsSection(
            'О системе',
            [
              _buildInfoSetting('Версия приложения', '1.0.0'),
              _buildInfoSetting('Версия базы данных', '2024.12.01'),
              _buildInfoSetting('Последнее обновление', '15.01.2025'),
              _buildInfoSetting('Разработчик', 'Северная корзина Team'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextSetting(String label, String value, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: value,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSetting(String label, String value, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: value,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: Icon(Icons.visibility_off),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberSetting(String label, int value, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(String label, bool value, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Switch(
                  value: value,
                  onChanged: (newValue) {
                    setState(() {
                      // Здесь будет логика сохранения
                    });
                  },
                ),
                SizedBox(width: 12),
                Text(
                  value ? 'Включено' : 'Выключено',
                  style: TextStyle(
                    color: value ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
      String label, String value, List<String> options) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  // Здесь будет логика сохранения
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting(
      String label, String description, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text('Выполнить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSetting(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _saveAllSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Настройки сохранены'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _createBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Создание резервной копии'),
        content: Text('Создать резервную копию всех данных?'),
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
                  content: Text('Резервная копия создана'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Кеш очищен'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _testConnections() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Проверка соединений'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConnectionStatus('ЮKassa API', true),
            _buildConnectionStatus('SMS сервис', true),
            _buildConnectionStatus('Email SMTP', false),
            _buildConnectionStatus('База данных', true),
          ],
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

  Widget _buildConnectionStatus(String service, bool isConnected) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.error,
            color: isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(service),
          Spacer(),
          Text(
            isConnected ? 'OK' : 'Ошибка',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Экспорт данных начат'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Выберите файл для импорта'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
