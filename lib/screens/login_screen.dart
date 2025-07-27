// lib/screens/login_screen.dart - ПРОСТОЙ ВХОД ПО ЛОГИНУ/ПАРОЛЮ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController =
      TextEditingController(text: 'admin'); // Предзаполненный логин
  final _passwordController =
      TextEditingController(text: 'admin'); // Предзаполненный пароль
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithPassword(
      _loginController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      // Навигация произойдет автоматически через AuthWrapper
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[800]!,
              Colors.blue[600]!,
              Colors.blue[400]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Логотип
                        Icon(
                          Icons.admin_panel_settings,
                          size: 80,
                          color: Colors.blue[600],
                        ),
                        SizedBox(height: 24),

                        // Заголовок
                        Text(
                          'Админ панель',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                        ),
                        Text(
                          'Северная корзина',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        SizedBox(height: 32),

                        // Поле логина
                        TextFormField(
                          controller: _loginController,
                          decoration: InputDecoration(
                            labelText: 'Логин',
                            hintText: 'Введите логин',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Введите логин';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),

                        SizedBox(height: 16),

                        // Поле пароля
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            hintText: 'Введите пароль',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите пароль';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                        ),

                        SizedBox(height: 24),

                        // Кнопка входа
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    authProvider.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Войти',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            );
                          },
                        ),

                        // Отображение ошибок
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            if (authProvider.error == null)
                              return SizedBox.shrink();

                            return Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  border: Border.all(color: Colors.red[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error,
                                        color: Colors.red[600], size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authProvider.error!,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 24),

                        // Информация для тестирования
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(color: Colors.green[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info,
                                      color: Colors.green[600], size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Тестовые данные для входа',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Логин: admin\nПароль: admin',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        // Статус сервера
                        _ServerStatusIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Виджет для отображения статуса сервера
class _ServerStatusIndicator extends StatefulWidget {
  @override
  _ServerStatusIndicatorState createState() => _ServerStatusIndicatorState();
}

class _ServerStatusIndicatorState extends State<_ServerStatusIndicator> {
  bool _isServerOnline = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isOnline = await authProvider.checkServerConnection();

      setState(() {
        _isServerOnline = isOnline;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isServerOnline = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _checkServerStatus,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isChecking)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _isServerOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isServerOnline ? Colors.green : Colors.red,
              size: 16,
            ),
          SizedBox(width: 8),
          Text(
            _isChecking
                ? 'Проверка сервера...'
                : _isServerOnline
                    ? 'Сервер доступен'
                    : 'Сервер недоступен (работает оффлайн)',
            style: TextStyle(
              color: _isChecking
                  ? Colors.grey[600]
                  : _isServerOnline
                      ? Colors.green[700]
                      : Colors.red[700], // Красный для недоступного сервера
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
