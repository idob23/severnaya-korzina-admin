import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:severnaya_korzina_admin/models/user.dart';
import 'package:severnaya_korzina_admin/models/product.dart';
import 'package:severnaya_korzina_admin/models/category.dart';
import 'package:severnaya_korzina_admin/models/order.dart';
import 'package:severnaya_korzina_admin/models/purchase_batch.dart';

class DataService {
  static const String _usersKey = 'admin_users';
  static const String _productsKey = 'admin_products';
  static const String _categoriesKey = 'admin_categories';
  static const String _ordersKey = 'admin_orders';
  static const String _batchesKey = 'admin_batches';

  // Генерация тестовых данных при первом запуске
  Future<void> initializeTestData() async {
    final prefs = await SharedPreferences.getInstance();

    // Проверяем, были ли уже инициализированы данные
    if (!prefs.containsKey('data_initialized')) {
      await _generateTestUsers();
      await _generateTestCategories();
      await _generateTestProducts();
      await _generateTestBatches();
      await _generateTestOrders();

      await prefs.setBool('data_initialized', true);
    }
  }

  // ПОЛЬЗОВАТЕЛИ
  Future<List<AdminUser>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) {
      await _generateTestUsers();
      return getUsers();
    }

    final List<dynamic> usersList = jsonDecode(usersJson);
    return usersList.map((json) => AdminUser.fromJson(json)).toList();
  }

  Future<void> saveUser(AdminUser user) async {
    final users = await getUsers();
    users.add(user);
    await _saveUsers(users);
  }

  Future<void> updateUser(AdminUser user) async {
    final users = await getUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = user;
      await _saveUsers(users);
    }
  }

  Future<void> deleteUser(String userId) async {
    final users = await getUsers();
    users.removeWhere((user) => user.id == userId);
    await _saveUsers(users);
  }

  Future<void> _saveUsers(List<AdminUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(users.map((user) => user.toJson()).toList());
    await prefs.setString(_usersKey, usersJson);
  }

  // КАТЕГОРИИ
  Future<List<AdminCategory>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString(_categoriesKey);

    if (categoriesJson == null) {
      await _generateTestCategories();
      return getCategories();
    }

    final List<dynamic> categoriesList = jsonDecode(categoriesJson);
    return categoriesList.map((json) => AdminCategory.fromJson(json)).toList();
  }

  Future<void> saveCategory(AdminCategory category) async {
    final categories = await getCategories();
    categories.add(category);
    await _saveCategories(categories);
  }

  Future<void> updateCategory(AdminCategory category) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      await _saveCategories(categories);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final categories = await getCategories();
    categories.removeWhere((category) => category.id == categoryId);
    await _saveCategories(categories);
  }

  Future<void> _saveCategories(List<AdminCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson =
        jsonEncode(categories.map((cat) => cat.toJson()).toList());
    await prefs.setString(_categoriesKey, categoriesJson);
  }

  // ТОВАРЫ
  Future<List<AdminProduct>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    if (productsJson == null) {
      await _generateTestProducts();
      return getProducts();
    }

    final List<dynamic> productsList = jsonDecode(productsJson);
    return productsList.map((json) => AdminProduct.fromJson(json)).toList();
  }

  Future<void> saveProduct(AdminProduct product) async {
    final products = await getProducts();
    products.add(product);
    await _saveProducts(products);
  }

  Future<void> updateProduct(AdminProduct product) async {
    final products = await getProducts();
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      await _saveProducts(products);
    }
  }

  Future<void> deleteProduct(String productId) async {
    final products = await getProducts();
    products.removeWhere((product) => product.id == productId);
    await _saveProducts(products);
  }

  Future<void> _saveProducts(List<AdminProduct> products) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson =
        jsonEncode(products.map((prod) => prod.toJson()).toList());
    await prefs.setString(_productsKey, productsJson);
  }

  // ЗАКАЗЫ
  Future<List<AdminOrder>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString(_ordersKey);

    if (ordersJson == null) {
      await _generateTestOrders();
      return getOrders();
    }

    final List<dynamic> ordersList = jsonDecode(ordersJson);
    return ordersList.map((json) => AdminOrder.fromJson(json)).toList();
  }

  Future<void> updateOrder(AdminOrder order) async {
    final orders = await getOrders();
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      orders[index] = order;
      await _saveOrders(orders);
    }
  }

  Future<void> _saveOrders(List<AdminOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson =
        jsonEncode(orders.map((order) => order.toJson()).toList());
    await prefs.setString(_ordersKey, ordersJson);
  }

  // КОЛЛЕКТИВНЫЕ ЗАКУПКИ
  Future<List<AdminPurchaseBatch>> getBatches() async {
    final prefs = await SharedPreferences.getInstance();
    final batchesJson = prefs.getString(_batchesKey);

    if (batchesJson == null) {
      await _generateTestBatches();
      return getBatches();
    }

    final List<dynamic> batchesList = jsonDecode(batchesJson);
    return batchesList
        .map((json) => AdminPurchaseBatch.fromJson(json))
        .toList();
  }

  Future<void> saveBatch(AdminPurchaseBatch batch) async {
    final batches = await getBatches();
    batches.add(batch);
    await _saveBatches(batches);
  }

  Future<void> updateBatch(AdminPurchaseBatch batch) async {
    final batches = await getBatches();
    final index = batches.indexWhere((b) => b.id == batch.id);
    if (index != -1) {
      batches[index] = batch;
      await _saveBatches(batches);
    }
  }

  Future<void> deleteBatch(String batchId) async {
    final batches = await getBatches();
    batches.removeWhere((batch) => batch.id == batchId);
    await _saveBatches(batches);
  }

  Future<void> _saveBatches(List<AdminPurchaseBatch> batches) async {
    final prefs = await SharedPreferences.getInstance();
    final batchesJson =
        jsonEncode(batches.map((batch) => batch.toJson()).toList());
    await prefs.setString(_batchesKey, batchesJson);
  }

  // ГЕНЕРАЦИЯ ТЕСТОВЫХ ДАННЫХ
  Future<void> _generateTestUsers() async {
    final users = <AdminUser>[
      AdminUser(
        id: 'user-001',
        phone: '+79141234567',
        name: 'Анна',
        lastName: 'Иванова',
        isActive: true,
        isVerified: true,
        lastLoginAt: DateTime.now().subtract(Duration(hours: 2)),
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        totalOrders: 5,
        totalSpent: 25000,
      ),
      AdminUser(
        id: 'user-002',
        phone: '+79149876543',
        name: 'Петр',
        lastName: 'Сидоров',
        isActive: true,
        isVerified: true,
        lastLoginAt: DateTime.now().subtract(Duration(days: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 45)),
        totalOrders: 3,
        totalSpent: 18500,
      ),
      AdminUser(
        id: 'user-003',
        phone: '+79145555555',
        name: 'Мария',
        lastName: 'Петрова',
        isActive: false,
        isVerified: false,
        lastLoginAt: null,
        createdAt: DateTime.now().subtract(Duration(days: 7)),
        totalOrders: 0,
        totalSpent: 0,
      ),
      AdminUser(
        id: 'user-004',
        phone: '+79141111111',
        name: 'Дмитрий',
        lastName: 'Козлов',
        isActive: true,
        isVerified: true,
        lastLoginAt: DateTime.now().subtract(Duration(hours: 12)),
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        totalOrders: 8,
        totalSpent: 42300,
      ),
      AdminUser(
        id: 'user-005',
        phone: '+79142222222',
        name: 'Елена',
        lastName: 'Васильева',
        isActive: true,
        isVerified: true,
        lastLoginAt: DateTime.now().subtract(Duration(minutes: 30)),
        createdAt: DateTime.now().subtract(Duration(days: 60)),
        totalOrders: 12,
        totalSpent: 67800,
      ),
    ];

    await _saveUsers(users);
  }

  Future<void> _generateTestCategories() async {
    final categories = <AdminCategory>[
      AdminCategory(
        id: 'cat-001',
        name: 'Продукты питания',
        slug: 'food',
        description: 'Основные продукты питания',
        imageUrl: '/images/categories/food.jpg',
        sortOrder: 1,
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: 90)),
        productsCount: 25,
      ),
      AdminCategory(
        id: 'cat-002',
        name: 'Бытовая химия',
        slug: 'household',
        description: 'Товары для дома и уборки',
        imageUrl: '/images/categories/household.jpg',
        sortOrder: 2,
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: 85)),
        productsCount: 15,
      ),
      AdminCategory(
        id: 'cat-003',
        name: 'Личная гигиена',
        slug: 'hygiene',
        description: 'Средства личной гигиены',
        imageUrl: '/images/categories/hygiene.jpg',
        sortOrder: 3,
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: 80)),
        productsCount: 20,
      ),
      AdminCategory(
        id: 'cat-004',
        name: 'Замороженные продукты',
        slug: 'frozen',
        description: 'Замороженные продукты и полуфабрикаты',
        imageUrl: '/images/categories/frozen.jpg',
        sortOrder: 4,
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: 75)),
        productsCount: 18,
      ),
    ];

    await _saveCategories(categories);
  }

  Future<void> _generateTestProducts() async {
    final random = Random();
    final categories = await getCategories();
    final products = <AdminProduct>[];

    final productNames = [
      'Хлеб белый',
      'Молоко 3.2%',
      'Яйца куриные',
      'Масло сливочное',
      'Сыр российский',
      'Колбаса докторская',
      'Рис круглозерный',
      'Гречка',
      'Макароны',
      'Сахар',
      'Соль',
      'Мука пшеничная',
      'Картофель',
      'Лук репчатый',
      'Морковь',
      'Капуста белокочанная',
      'Яблоки',
      'Бананы',
      'Курица целая',
      'Говядина',
      'Рыба треска',
      'Креветки',
      'Стиральный порошок',
      'Жидкость для мытья посуды',
      'Туалетная бумага',
      'Шампунь',
      'Зубная паста',
      'Мыло',
      'Дезодорант',
      'Пельмени',
    ];

    for (int i = 0; i < productNames.length; i++) {
      final category = categories[random.nextInt(categories.length)];
      products.add(AdminProduct(
        id: 'prod-${(i + 1).toString().padLeft(3, '0')}',
        categoryId: category.id,
        name: productNames[i],
        slug: productNames[i].toLowerCase().replaceAll(' ', '-'),
        description: 'Качественный ${productNames[i].toLowerCase()}',
        imageUrl: '/images/products/product-${i + 1}.jpg',
        basePrice: (random.nextInt(500) + 50).toDouble(),
        weight: random.nextDouble() * 2,
        sku: 'SKU-${(i + 1).toString().padLeft(6, '0')}',
        isActive: random.nextBool() || i < 25, // большинство активных
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(60))),
        updatedAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        categoryName: category.name,
        ordersCount: random.nextInt(50),
      ));
    }

    await _saveProducts(products);
  }

  Future<void> _generateTestBatches() async {
    final batches = <AdminPurchaseBatch>[
      AdminPurchaseBatch(
        id: 'batch-001',
        title: 'Продукты на зиму',
        description: 'Большая закупка основных продуктов питания',
        startDate: DateTime.now().subtract(Duration(days: 10)),
        endDate: DateTime.now().add(Duration(days: 5)),
        deliveryDate: DateTime.now().add(Duration(days: 15)),
        minParticipants: 20,
        maxParticipants: 100,
        currentParticipants: 45,
        status: 'active',
        pickupAddress: 'ул. Ленина, 15, магазин "Северянка"',
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        productsCount: 25,
        totalAmount: 125000,
      ),
      AdminPurchaseBatch(
        id: 'batch-002',
        title: 'Бытовая химия и гигиена',
        description: 'Закупка товаров для дома',
        startDate: DateTime.now().add(Duration(days: 1)),
        endDate: DateTime.now().add(Duration(days: 10)),
        deliveryDate: DateTime.now().add(Duration(days: 20)),
        minParticipants: 15,
        maxParticipants: 50,
        currentParticipants: 8,
        status: 'draft',
        pickupAddress: 'ул. Ленина, 15, магазин "Северянка"',
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        productsCount: 18,
        totalAmount: 0,
      ),
      AdminPurchaseBatch(
        id: 'batch-003',
        title: 'Мясо и рыба',
        description: 'Закупка мясных и рыбных продуктов',
        startDate: DateTime.now().subtract(Duration(days: 20)),
        endDate: DateTime.now().subtract(Duration(days: 10)),
        deliveryDate: DateTime.now().add(Duration(days: 2)),
        minParticipants: 25,
        maxParticipants: 80,
        currentParticipants: 65,
        status: 'shipped',
        pickupAddress: 'ул. Ленина, 15, магазин "Северянка"',
        createdAt: DateTime.now().subtract(Duration(days: 25)),
        productsCount: 12,
        totalAmount: 185000,
      ),
    ];

    await _saveBatches(batches);
  }

  Future<void> _generateTestOrders() async {
    final random = Random();
    final users = await getUsers();
    final batches = await getBatches();
    final orders = <AdminOrder>[];

    final statuses = [
      'pending',
      'paid',
      'confirmed',
      'shipped',
      'ready_pickup',
      'completed'
    ];
    final paymentStatuses = ['pending', 'partial', 'paid'];

    for (int i = 0; i < 20; i++) {
      final user = users[random.nextInt(users.length)];
      final batch = batches[random.nextInt(batches.length)];
      final totalAmount = (random.nextInt(5000) + 1000).toDouble();
      final prepaidAmount = totalAmount * 0.9;

      orders.add(AdminOrder(
        id: 'order-${(i + 1).toString().padLeft(3, '0')}',
        orderNumber:
            'SK-${DateTime.now().year}-${(i + 1).toString().padLeft(4, '0')}',
        userId: user.id,
        batchId: batch.id,
        status: statuses[random.nextInt(statuses.length)],
        totalAmount: totalAmount,
        prepaidAmount: prepaidAmount,
        remainingAmount: totalAmount - prepaidAmount,
        paymentStatus: paymentStatuses[random.nextInt(paymentStatuses.length)],
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        userName: user.fullName,
        userPhone: user.phone,
        batchTitle: batch.title,
        itemsCount: random.nextInt(8) + 1,
      ));
    }

    await _saveOrders(orders);
  }
}
