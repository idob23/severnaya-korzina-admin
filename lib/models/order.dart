import 'package:flutter/material.dart';

class AdminOrder {
  final String id;
  final String orderNumber;
  final String userId;
  final String batchId;
  final String status;
  final double totalAmount;
  final double prepaidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final DateTime createdAt;
  final String userName;
  final String userPhone;
  final String batchTitle;
  final int itemsCount;

  AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.batchId,
    this.status = 'pending',
    required this.totalAmount,
    required this.prepaidAmount,
    required this.remainingAmount,
    this.paymentStatus = 'pending',
    required this.createdAt,
    this.userName = '',
    this.userPhone = '',
    this.batchTitle = '',
    this.itemsCount = 0,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['id'],
      orderNumber: json['order_number'],
      userId: json['user_id'],
      batchId: json['batch_id'],
      status: json['status'] ?? 'pending',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      prepaidAmount: (json['prepaid_amount'] ?? 0.0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0.0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      batchTitle: json['batch_title'] ?? '',
      itemsCount: json['items_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'user_id': userId,
      'batch_id': batchId,
      'status': status,
      'total_amount': totalAmount,
      'prepaid_amount': prepaidAmount,
      'remaining_amount': remainingAmount,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'user_phone': userPhone,
      'batch_title': batchTitle,
      'items_count': itemsCount,
    };
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Ожидает';
      case 'paid':
        return 'Оплачен';
      case 'confirmed':
        return 'Подтвержден';
      case 'shipped':
        return 'Отправлен';
      case 'ready_pickup':
        return 'Готов к выдаче';
      case 'completed':
        return 'Завершен';
      case 'cancelled':
        return 'Отменен';
      case 'refunded':
        return 'Возврат';
      default:
        return 'Неизвестно';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'ready_pickup':
        return Colors.teal;
      case 'completed':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case 'pending':
        return 'Ожидает оплаты';
      case 'partial':
        return 'Частично оплачен';
      case 'paid':
        return 'Полностью оплачен';
      case 'refunded':
        return 'Возврат';
      default:
        return 'Неизвестно';
    }
  }
}
