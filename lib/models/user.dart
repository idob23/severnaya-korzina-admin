class AdminUser {
  final String id;
  final String phone;
  final String name;
  final String? lastName;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final int totalOrders;
  final double totalSpent;

  AdminUser({
    required this.id,
    required this.phone,
    required this.name,
    this.lastName,
    required this.isActive,
    required this.isVerified,
    this.lastLoginAt,
    required this.createdAt,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      lastName: json['last_name'],
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      totalOrders: json['total_orders'] ?? 0,
      totalSpent: (json['total_spent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'last_name': lastName,
      'is_active': isActive,
      'is_verified': isVerified,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'total_orders': totalOrders,
      'total_spent': totalSpent,
    };
  }

  String get fullName => lastName != null ? '$name $lastName' : name;
  String get status => isActive ? 'Активен' : 'Заблокирован';
}
