class AdminProduct {
  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final double basePrice;
  final double? weight;
  final String? sku;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String categoryName;
  final int ordersCount;

  AdminProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    required this.basePrice,
    this.weight,
    this.sku,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName = '',
    this.ordersCount = 0,
  });

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    return AdminProduct(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      imageUrl: json['image_url'],
      basePrice: (json['base_price'] ?? 0.0).toDouble(),
      weight: json['weight']?.toDouble(),
      sku: json['sku'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      categoryName: json['category_name'] ?? '',
      ordersCount: json['orders_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'slug': slug,
      'description': description,
      'image_url': imageUrl,
      'base_price': basePrice,
      'weight': weight,
      'sku': sku,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category_name': categoryName,
      'orders_count': ordersCount,
    };
  }

  String get formattedPrice => '${basePrice.toStringAsFixed(0)} ₽';
  String get status => isActive ? 'Активен' : 'Скрыт';
}
