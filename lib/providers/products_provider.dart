// providers/products_provider.dart
import 'package:flutter/material.dart';
import 'package:severnaya_korzina_admin/models/product.dart';
import 'package:severnaya_korzina_admin/models/category.dart';
import 'package:severnaya_korzina_admin/services/data_service.dart';

class ProductsProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  List<AdminProduct> _products = [];
  List<AdminCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<AdminProduct> get products => _products;
  List<AdminCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadProducts(),
        loadCategories(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    try {
      _products = await _dataService.getProducts();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _dataService.getCategories();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Методы для работы с товарами
  Future<void> addProduct(AdminProduct product) async {
    try {
      await _dataService.saveProduct(product);
      _products.add(product);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProduct(AdminProduct product) async {
    try {
      await _dataService.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _dataService.deleteProduct(productId);
      _products.removeWhere((product) => product.id == productId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Методы для работы с категориями
  Future<void> addCategory(AdminCategory category) async {
    try {
      await _dataService.saveCategory(category);
      _categories.add(category);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategory(AdminCategory category) async {
    try {
      await _dataService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      // Проверяем есть ли товары в этой категории
      final productsInCategory =
          _products.where((p) => p.categoryId == categoryId).length;
      if (productsInCategory > 0) {
        throw Exception('Нельзя удалить категорию с товарами');
      }

      await _dataService.deleteCategory(categoryId);
      _categories.removeWhere((category) => category.id == categoryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Поиск и фильтрация
  List<AdminProduct> searchProducts(String query) {
    if (query.isEmpty) return _products;

    return _products.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.sku?.toLowerCase().contains(query.toLowerCase()) == true;
    }).toList();
  }

  List<AdminProduct> getProductsByCategory(String categoryId) {
    return _products
        .where((product) => product.categoryId == categoryId)
        .toList();
  }

  AdminCategory? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> getProductsStats() {
    return {
      'total': _products.length,
      'active': _products.where((p) => p.isActive).length,
      'categories': _categories.length,
      'out_of_stock': _products.where((p) => !p.isActive).length,
    };
  }
}
