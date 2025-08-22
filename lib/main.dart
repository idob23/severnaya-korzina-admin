// lib/main.dart - ПОЛНОСТЬЮ НОВАЯ ВЕРСИЯ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/admin_api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin/orders_management_screen.dart';

void main() {
  runApp(SevernyaKorzinaAdminApp());
}

class SevernyaKorzinaAdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Северная корзина - Админ панель',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Кастомная тема для админки
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Показываем загрузку во время проверки токена
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Проверка авторизации...'),
                ],
              ),
            ),
          );
        }

        // Если пользователь авторизован, показываем dashboard
        if (authProvider.isAuthenticated) {
          return DashboardScreen();
        }

        // Иначе показываем экран логина
        return LoginScreen();
      },
    );
  }
}
