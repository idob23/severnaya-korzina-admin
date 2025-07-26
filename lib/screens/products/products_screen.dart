// screens/products/products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:severnaya_korzina_admin/providers/products_provider.dart';
import 'package:severnaya_korzina_admin/models/product.dart';
import 'package:severnaya_korzina_admin/models/category.dart';
import 'package:uuid/uuid.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и поиск
          Row(
            children: [
              Text(
                'Управление товарами',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск товаров...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog('product'),
                icon: Icon(Icons.add),
                label: Text('Добавить товар'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Вкладки
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[800],
            tabs: [
              Tab(text: 'Товары'),
              Tab(text: 'Категории'),
            ],
          ),
          SizedBox(height: 16),

          // Содержимое вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // Фильтры и статистика для товаров
        Row(
          children: [
            _buildFilterChip('Все', 'all'),
            SizedBox(width: 8),
            _buildFilterChip('Активные', 'active'),
            SizedBox(width: 8),
            _buildFilterChip('Скрытые', 'hidden'),
            Spacer(),
            Consumer<ProductsProvider>(
              builder: (context, productsProvider, child) {
                final stats = productsProvider.getProductsStats();
                return Row(
                  children: [
                    _buildStatChip('Всего: ${stats['total']}', Colors.blue),
                    SizedBox(width: 8),
                    _buildStatChip(
                        'Активных: ${stats['active']}', Colors.green),
                    SizedBox(width: 8),
                    _buildStatChip(
                        'Категорий: ${stats['categories']}', Colors.purple),
                  ],
                );
              },
            ),
          ],
        ),
        SizedBox(height: 16),

        // Таблица товаров
        Expanded(
          child: Card(
            elevation: 2,
            child: Consumer<ProductsProvider>(
              builder: (context, productsProvider, child) {
                if (productsProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                final products = _getFilteredProducts(productsProvider);

                return DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 1000,
                  columns: [
                    DataColumn2(
                      label: Text('Товар',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text('Категория',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text('Цена',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('SKU',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Статус',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Заказы',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Действия',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                      fixedWidth: 120,
                    ),
                  ],
                  rows: products
                      .map((product) =>
                          _buildProductRow(product, productsProvider))
                      .toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Row(
          children: [
            Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog('category'),
              icon: Icon(Icons.add),
              label: Text('Добавить категорию'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: Card(
            elevation: 2,
            child: Consumer<ProductsProvider>(
              builder: (context, productsProvider, child) {
                if (productsProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = productsProvider.categories;

                return DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 800,
                  columns: [
                    DataColumn2(
                      label: Text('Категория',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text('Описание',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text('Товаров',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Статус',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('Действия',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      size: ColumnSize.S,
                      fixedWidth: 120,
                    ),
                  ],
                  rows: categories
                      .map((category) =>
                          _buildCategoryRow(category, productsProvider))
                      .toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[800],
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  DataRow _buildProductRow(
      AdminProduct product, ProductsProvider productsProvider) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Icon(Icons.image, color: Colors.grey[400]),
                      )
                    : Icon(Icons.inventory, color: Colors.grey[400]),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description?.isNotEmpty == true)
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(product.categoryName),
        ),
        DataCell(
          Text(product.formattedPrice),
        ),
        DataCell(
          Text(product.sku ?? '-'),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: product.isActive ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: product.isActive ? Colors.green[200]! : Colors.red[200]!,
              ),
            ),
            child: Text(
              product.status,
              style: TextStyle(
                color: product.isActive ? Colors.green[800] : Colors.red[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Text(product.ordersCount.toString()),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 18),
                onPressed: () => _showEditProductDialog(product),
                tooltip: 'Редактировать',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () => _deleteProduct(product, productsProvider),
                tooltip: 'Удалить',
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildCategoryRow(
      AdminCategory category, ProductsProvider productsProvider) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category, color: Colors.blue[800]),
              ),
              SizedBox(width: 12),
              Text(
                category.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            category.description ?? 'Нет описания',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          Text(category.productsCount.toString()),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: category.isActive ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    category.isActive ? Colors.green[200]! : Colors.red[200]!,
              ),
            ),
            child: Text(
              category.isActive ? 'Активна' : 'Скрыта',
              style: TextStyle(
                color: category.isActive ? Colors.green[800] : Colors.red[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 18),
                onPressed: () => _showEditCategoryDialog(category),
                tooltip: 'Редактировать',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () => _deleteCategory(category, productsProvider),
                tooltip: 'Удалить',
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<AdminProduct> _getFilteredProducts(ProductsProvider productsProvider) {
    List<AdminProduct> products = productsProvider.searchProducts(_searchQuery);

    switch (_selectedFilter) {
      case 'active':
        products = products.where((product) => product.isActive).toList();
        break;
      case 'hidden':
        products = products.where((product) => !product.isActive).toList();
        break;
    }

    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  void _showAddDialog(String type) {
    if (type == 'product') {
      _showEditProductDialog(null);
    } else {
      _showEditCategoryDialog(null);
    }
  }

  void _showEditProductDialog(AdminProduct? product) {
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(product: product),
    );
  }

  void _showEditCategoryDialog(AdminCategory? category) {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(category: category),
    );
  }

  Future<void> _deleteProduct(
      AdminProduct product, ProductsProvider productsProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить товар'),
        content:
            Text('Вы уверены, что хотите удалить товар "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await productsProvider.deleteProduct(product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Товар "${product.name}" удален'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(
      AdminCategory category, ProductsProvider productsProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить категорию'),
        content: Text(
            'Вы уверены, что хотите удалить категорию "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await productsProvider.deleteCategory(category.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Категория "${category.name}" удалена'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Диалог редактирования товара
class ProductEditDialog extends StatefulWidget {
  final AdminProduct? product;

  ProductEditDialog({this.product});

  @override
  _ProductEditDialogState createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _skuController;
  late TextEditingController _weightController;
  String? _selectedCategoryId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _priceController =
        TextEditingController(text: widget.product?.basePrice.toString() ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _weightController =
        TextEditingController(text: widget.product?.weight?.toString() ?? '');
    _selectedCategoryId = widget.product?.categoryId;
    _isActive = widget.product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.product == null ? 'Добавить товар' : 'Редактировать товар'),
      content: Container(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<ProductsProvider>(
                  builder: (context, productsProvider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Категория',
                        border: OutlineInputBorder(),
                      ),
                      items: productsProvider.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Выберите категорию';
                        }
                        return null;
                      },
                    );
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Название товара',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите название товара';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Цена (₽)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите цену';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Неверный формат цены';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: 'Вес (кг)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _skuController,
                  decoration: InputDecoration(
                    labelText: 'SKU (артикул)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                CheckboxListTile(
                  title: Text('Активный товар'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.product == null ? 'Добавить' : 'Сохранить'),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final productsProvider =
          Provider.of<ProductsProvider>(context, listen: false);
      final uuid = Uuid();
      final slug = _nameController.text
          .toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^\w\-]'), '');

      final category = productsProvider.getCategoryById(_selectedCategoryId!);

      final product = AdminProduct(
        id: widget.product?.id ?? uuid.v4(),
        categoryId: _selectedCategoryId!,
        name: _nameController.text.trim(),
        slug: widget.product?.slug ?? slug,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: widget.product?.imageUrl,
        basePrice: double.parse(_priceController.text),
        weight: _weightController.text.isEmpty
            ? null
            : double.tryParse(_weightController.text),
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        isActive: _isActive,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        categoryName: category?.name ?? '',
        ordersCount: widget.product?.ordersCount ?? 0,
      );

      if (widget.product == null) {
        await productsProvider.addProduct(product);
      } else {
        await productsProvider.updateProduct(product);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null ? 'Товар добавлен' : 'Товар обновлен',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Диалог редактирования категории
class CategoryEditDialog extends StatefulWidget {
  final AdminCategory? category;

  CategoryEditDialog({this.category});

  @override
  _CategoryEditDialogState createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _sortOrderController;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.category?.description ?? '');
    _sortOrderController = TextEditingController(
        text: widget.category?.sortOrder.toString() ?? '0');
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null
          ? 'Добавить категорию'
          : 'Редактировать категорию'),
      content: Container(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название категории',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название категории';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _sortOrderController,
                decoration: InputDecoration(
                  labelText: 'Порядок сортировки',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              CheckboxListTile(
                title: Text('Активная категория'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.category == null ? 'Добавить' : 'Сохранить'),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final productsProvider =
          Provider.of<ProductsProvider>(context, listen: false);
      final uuid = Uuid();
      final slug = _nameController.text
          .toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^\w\-]'), '');

      final category = AdminCategory(
        id: widget.category?.id ?? uuid.v4(),
        name: _nameController.text.trim(),
        slug: widget.category?.slug ?? slug,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: widget.category?.imageUrl,
        sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
        isActive: _isActive,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
        productsCount: widget.category?.productsCount ?? 0,
      );

      if (widget.category == null) {
        await productsProvider.addCategory(category);
      } else {
        await productsProvider.updateCategory(category);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.category == null
                ? 'Категория добавлена'
                : 'Категория обновлена',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
