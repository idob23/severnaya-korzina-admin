// lib/models/purchase_batch.dart - ОБНОВЛЕННАЯ ВЕРСИЯ
import 'package:flutter/material.dart';

class AdminPurchaseBatch {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? deliveryDate;
  final int minParticipants;
  final int? maxParticipants;
  final int currentParticipants;
  final String status;
  final String? pickupAddress;
  final String? pickupInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int productsCount;
  final double totalAmount;

  AdminPurchaseBatch({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.deliveryDate,
    required this.minParticipants,
    this.maxParticipants,
    this.currentParticipants = 0,
    this.status = 'draft',
    this.pickupAddress,
    this.pickupInstructions,
    required this.createdAt,
    DateTime? updatedAt,
    this.productsCount = 0,
    this.totalAmount = 0.0,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory AdminPurchaseBatch.fromJson(Map<String, dynamic> json) {
    return AdminPurchaseBatch(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
      minParticipants: json['min_participants'],
      maxParticipants: json['max_participants'],
      currentParticipants: json['current_participants'] ?? 0,
      status: json['status'] ?? 'draft',
      pickupAddress: json['pickup_address'],
      pickupInstructions: json['pickup_instructions'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      productsCount: json['products_count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'min_participants': minParticipants,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'status': status,
      'pickup_address': pickupAddress,
      'pickup_instructions': pickupInstructions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'products_count': productsCount,
      'total_amount': totalAmount,
    };
  }

  String get statusText {
    switch (status) {
      case 'draft':
        return 'Черновик';
      case 'active':
        return 'Активна';
      case 'closed':
        return 'Закрыта';
      case 'processing':
        return 'Обработка';
      case 'shipped':
        return 'Отправлена';
      case 'completed':
        return 'Завершена';
      case 'cancelled':
        return 'Отменена';
      default:
        return 'Неизвестно';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'active':
        return Colors.green;
      case 'closed':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get isActive => status == 'active';
  bool get canEdit => ['draft', 'active'].contains(status);
  bool get canDelete => status == 'draft';
}
