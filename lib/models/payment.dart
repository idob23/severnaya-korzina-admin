// lib/models/payment.dart
import 'package:flutter/material.dart';

class AdminPayment {
  final String id;
  final String orderId;
  final String? yookassaPaymentId;
  final String paymentType;
  final double amount;
  final String currency;
  final String? paymentMethod;
  final String status;
  final String? confirmationUrl;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminPayment({
    required this.id,
    required this.orderId,
    this.yookassaPaymentId,
    required this.paymentType,
    required this.amount,
    this.currency = 'RUB',
    this.paymentMethod,
    this.status = 'pending',
    this.confirmationUrl,
    this.description,
    this.metadata,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    return AdminPayment(
      id: json['id'],
      orderId: json['order_id'],
      yookassaPaymentId: json['yookassa_payment_id'],
      paymentType: json['payment_type'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'RUB',
      paymentMethod: json['payment_method'],
      status: json['status'] ?? 'pending',
      confirmationUrl: json['confirmation_url'],
      description: json['description'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'yookassa_payment_id': yookassaPaymentId,
      'payment_type': paymentType,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'status': status,
      'confirmation_url': confirmationUrl,
      'description': description,
      'metadata': metadata,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Ожидает';
      case 'succeeded':
        return 'Успешно';
      case 'canceled':
        return 'Отменен';
      case 'failed':
        return 'Ошибка';
      default:
        return 'Неизвестно';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'succeeded':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      case 'failed':
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }
}
