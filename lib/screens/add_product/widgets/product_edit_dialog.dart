import 'package:flutter/material.dart';
import '../../../services/admin_api_service.dart';

class ProductEditDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> categories;
  final Function(Map<String, dynamic>) onSave;
  final Future<void> Function() onCategoriesUpdated;

  const ProductEditDialog({
    super.key,
    required this.product,
    required this.categories,
    required this.onSave,
    required this.onCategoriesUpdated,
  });

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final AdminApiService _apiService = AdminApiService();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;
  int? _selectedCategoryId;
  bool _isCreatingCategory = false;
  final _formKey = GlobalKey<FormState>();
  String _selectedSaleType = 'поштучно';
  late List<Map<String, dynamic>> _localCategories;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _priceController = TextEditingController(
      text: widget.product['price'].toString(),
    );
    _unitController = TextEditingController(text: widget.product['unit']);
    _descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );
    _selectedCategoryId = widget.product['suggestedCategoryId'];
    _selectedSaleType = widget.product['saleType'] ?? 'поштучно';
    _localCategories = List.from(widget.categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showCreateCategoryDialog() {
    final categoryNameController = TextEditingController();
    // Сохраняем ScaffoldMessenger до async операций
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Создать новую категорию'),
        content: TextField(
          controller: categoryNameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название категории',
            border: OutlineInputBorder(),
            hintText: 'Например: Замороженные продукты',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final categoryName = categoryNameController.text.trim();
              if (categoryName.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Введите название категории')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              setState(() => _isCreatingCategory = true);

              try {
                final response = await _apiService.createCategory(categoryName);
                final newCategory = response['category'];

                // Обновляем список категорий в родительском виджете
                await widget.onCategoriesUpdated();

                // Добавляем новую категорию в локальный список
                setState(() {
                  _localCategories.add(newCategory);
                  _selectedCategoryId = newCategory['id'];
                  _isCreatingCategory = false;
                });

                // Безопасно показываем SnackBar
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Категория "$categoryName" создана'),
                  ),
                );
              } catch (e) {
                setState(() => _isCreatingCategory = false);
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Ошибка создания категории'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактирование товара'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Название обязательно';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Цена',
                  border: OutlineInputBorder(),
                  suffixText: '₽',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Цена обязательна';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Единица измерения',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Единица измерения обязательна';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Тип продажи
              DropdownButtonFormField<String>(
                initialValue: _selectedSaleType,
                decoration: const InputDecoration(
                  labelText: 'Тип продажи',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'поштучно', child: Text('Поштучно')),
                  DropdownMenuItem(
                      value: 'только уп', child: Text('Только упаковками')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSaleType = value ?? 'поштучно';
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Категория *',
                        border: OutlineInputBorder(),
                      ),
                      items: _localCategories
                          .map<DropdownMenuItem<int>>(
                            (cat) => DropdownMenuItem<int>(
                              value: cat['id'] as int,
                              child: Text(cat['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Выберите категорию';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        _isCreatingCategory ? null : _showCreateCategoryDialog,
                    icon: _isCreatingCategory
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle),
                    tooltip: 'Создать категорию',
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            final updatedProduct = {
              ...widget.product,
              'name': _nameController.text.trim(),
              'price': double.tryParse(_priceController.text) ?? 0,
              'unit': _unitController.text.trim(),
              'description': _descriptionController.text.trim(),
              'suggestedCategoryId': _selectedCategoryId,
              'saleType': _selectedSaleType,
              'basePrice': double.tryParse(_priceController.text) ?? 0,
              'baseUnit': _unitController.text.trim(),
              'inPackage': _selectedSaleType == 'только уп'
                  ? widget.product['inPackage']
                  : 1,
            };
            widget.onSave(updatedProduct);
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
