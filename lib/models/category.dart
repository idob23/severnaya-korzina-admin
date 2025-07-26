class AdminCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final int productsCount;

  AdminCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    this.productsCount = 0,
  });

  factory AdminCategory.fromJson(Map<String, dynamic> json) {
    return AdminCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      imageUrl: json['image_url'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      productsCount: json['products_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image_url': imageUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'products_count': productsCount,
    };
  }
}
