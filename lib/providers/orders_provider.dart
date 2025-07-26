// providers/orders_provider.dart
import 'package:flutter/material.dart';
import 'package:severnaya_korzina_admin/models/order.dart';
import 'package:severnaya_korzina_admin/models/purchase_batch.dart';
import 'package:severnaya_korzina_admin/services/data_service.dart';

class OrdersProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  List<AdminOrder> _orders = [];
  List<AdminPurchaseBatch> _batches = [];
  bool _isLoading = false;
  String? _error;

  List<AdminOrder> get orders => _orders;
  List<AdminPurchaseBatch> get batches => _batches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadOrders(),
        loadBatches(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    try {
      _orders = await _dataService.getOrders();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> loadBatches() async {
    try {
      _batches = await _dataService.getBatches();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Методы для работы с заказами
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      final updatedOrder = AdminOrder(
        id: order.id,
        orderNumber: order.orderNumber,
        userId: order.userId,
        batchId: order.batchId,
        status: newStatus,
        totalAmount: order.totalAmount,
        prepaidAmount: order.prepaidAmount,
        remainingAmount: order.remainingAmount,
        paymentStatus: order.paymentStatus,
        createdAt: order.createdAt,
        userName: order.userName,
        userPhone: order.userPhone,
        batchTitle: order.batchTitle,
        itemsCount: order.itemsCount,
      );

      await _dataService.updateOrder(updatedOrder);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(
      String orderId, String newPaymentStatus) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      final updatedOrder = AdminOrder(
        id: order.id,
        orderNumber: order.orderNumber,
        userId: order.userId,
        batchId: order.batchId,
        status: order.status,
        totalAmount: order.totalAmount,
        prepaidAmount: order.prepaidAmount,
        remainingAmount: order.remainingAmount,
        paymentStatus: newPaymentStatus,
        createdAt: order.createdAt,
        userName: order.userName,
        userPhone: order.userPhone,
        batchTitle: order.batchTitle,
        itemsCount: order.itemsCount,
      );

      await _dataService.updateOrder(updatedOrder);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Методы для работы с коллективными закупками
  Future<void> addBatch(AdminPurchaseBatch batch) async {
    try {
      await _dataService.saveBatch(batch);
      _batches.add(batch);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBatch(AdminPurchaseBatch batch) async {
    try {
      await _dataService.updateBatch(batch);
      final index = _batches.indexWhere((b) => b.id == batch.id);
      if (index != -1) {
        _batches[index] = batch;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBatchStatus(String batchId, String newStatus) async {
    try {
      final batch = _batches.firstWhere((b) => b.id == batchId);
      final updatedBatch = AdminPurchaseBatch(
        id: batch.id,
        title: batch.title,
        description: batch.description,
        startDate: batch.startDate,
        endDate: batch.endDate,
        deliveryDate: batch.deliveryDate,
        minParticipants: batch.minParticipants,
        maxParticipants: batch.maxParticipants,
        currentParticipants: batch.currentParticipants,
        status: newStatus,
        pickupAddress: batch.pickupAddress,
        createdAt: batch.createdAt,
        productsCount: batch.productsCount,
        totalAmount: batch.totalAmount,
      );

      await updateBatch(updatedBatch);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBatch(String batchId) async {
    try {
      // Проверяем есть ли заказы в этой закупке
      final ordersInBatch = _orders.where((o) => o.batchId == batchId).length;
      if (ordersInBatch > 0) {
        throw Exception('Нельзя удалить закупку с заказами');
      }

      await _dataService.deleteBatch(batchId);
      _batches.removeWhere((batch) => batch.id == batchId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Поиск и фильтрация
  List<AdminOrder> searchOrders(String query) {
    if (query.isEmpty) return _orders;

    return _orders.where((order) {
      return order.orderNumber.toLowerCase().contains(query.toLowerCase()) ||
          order.userName.toLowerCase().contains(query.toLowerCase()) ||
          order.userPhone.contains(query);
    }).toList();
  }

  List<AdminOrder> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<AdminOrder> getOrdersByBatch(String batchId) {
    return _orders.where((order) => order.batchId == batchId).toList();
  }

  List<AdminPurchaseBatch> getActiveBatches() {
    return _batches.where((batch) => batch.status == 'active').toList();
  }

  Map<String, dynamic> getOrdersStats() {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));

    return {
      'total': _orders.length,
      'pending': _orders.where((o) => o.status == 'pending').length,
      'paid': _orders.where((o) => o.paymentStatus == 'paid').length,
      'today': _orders
          .where((o) =>
              o.createdAt.year == today.year &&
              o.createdAt.month == today.month &&
              o.createdAt.day == today.day)
          .length,
      'total_revenue': _orders
          .where((o) => o.paymentStatus == 'paid')
          .fold(0.0, (sum, order) => sum + order.totalAmount),
    };
  }

  Map<String, dynamic> getBatchesStats() {
    return {
      'total': _batches.length,
      'active': _batches.where((b) => b.status == 'active').length,
      'completed': _batches.where((b) => b.status == 'completed').length,
      'draft': _batches.where((b) => b.status == 'draft').length,
    };
  }
}
