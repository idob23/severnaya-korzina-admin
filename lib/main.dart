import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:severnaya_korzina_admin/providers/admin_provider.dart';
import 'package:severnaya_korzina_admin/providers/users_provider.dart';
import 'package:severnaya_korzina_admin/providers/products_provider.dart';
import 'package:severnaya_korzina_admin/providers/orders_provider.dart';
import 'package:severnaya_korzina_admin/screens/auth/login_screen.dart';
import 'package:severnaya_korzina_admin/screens/dashboard/dashboard_screen.dart';

void main() {
  runApp(SevernyaKorzinaAdminApp());
}

class SevernyaKorzinaAdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: MaterialApp(
        title: 'Северная корзина - Админ панель',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isAuthenticated) {
          return DashboardScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
