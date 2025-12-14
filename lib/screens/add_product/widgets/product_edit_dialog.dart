import 'package:flutter/material.dart';
import '../../../services/admin_api_service.dart';
import '../../../services/category_mapping_service.dart';

class ProductEditDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> categories;
  final Function(Map<String, dynamic>) onSave;
  final Future<void> Function() onCategoriesUpdated;
  // Новый опциональный callback для применения маппинга ко всем товарам
  final Future<void> Function(String supplierCategory, int categoryId, String saleType)? onMappingCreated;

  const ProductEditDialog({
    super.key,
    required this.product,
    required this.categories,
    required this.onSave,
    required this.onCategoriesUpdated,
    this.onMappingCreated,
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

  // Для сохранения маппинга
  bool _saveMapping = false;
  bool _isSavingMapping = false;
  String? _originalCategory; // Категория из Excel

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
    _originalCategory = widget.product['originalCategory'] as String?;
  }

  // Проверяем, можно ли показать опцию сохранения маппинга
  bool get _canSaveMapping {
    return _originalCategory != null &&
        _originalCategory!.isNotEmpty &&
        widget.onMappingCreated != null &&
        _selectedCategoryId != null;
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
              // Опция сохранения маппинга — показываем только если есть originalCategory
              if (_canSaveMapping && _originalCategory != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_fix_high, size: 18, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Категория из прайса:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"$_originalCategory"',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _saveMapping,
                        onChanged: _isSavingMapping
                            ? null
                            : (value) {
                                setState(() {
                                  _saveMapping = value ?? false;
                                });
                              },
                        title: const Text(
                          'Запомнить для всех товаров этой категории',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Создаст маппинг и применит ко всем товарам в прайсе',
                          style: TextStyle(fontSize: 11),
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ],
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
          onPressed: _isSavingMapping ? null : () async {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            final isFixedWeight = widget.product['isFixedWeight'] == true;
            final updatedProduct = {
              ...widget.product,
              'name': _nameController.text.trim(),
              'price': double.tryParse(_priceController.text) ?? 0,
              'unit': _unitController.text.trim(),
              'description': _descriptionController.text.trim(),
              'suggestedCategoryId': _selectedCategoryId,
              'saleType': _selectedSaleType,
              'basePrice': double.tryParse(_priceController.text) ?? 0,
              // Для весовых товаров baseUnit всегда 'шт', не из контроллера
              'baseUnit': isFixedWeight ? 'шт' : _unitController.text.trim(),
              // Для весовых товаров inPackage = null (они штучные по кускам)
              'inPackage': isFixedWeight
                  ? null
                  : (_selectedSaleType == 'только уп'
                      ? widget.product['inPackage']
                      : 1),
            };

            // Если выбрано "Запомнить маппинг" — сохраняем
            if (_saveMapping &&
                _originalCategory != null &&
                _selectedCategoryId != null &&
                widget.onMappingCreated != null) {
              setState(() => _isSavingMapping = true);

              try {
                // Сохраняем маппинг через API
                final success = await CategoryMappingService.createMapping(
                  supplierCategory: _originalCategory!,
                  targetCategoryId: _selectedCategoryId!,
                );

                if (success) {
                  // Вызываем callback для применения ко всем товарам
                  await widget.onMappingCreated!(
                    _originalCategory!,
                    _selectedCategoryId!,
                    _selectedSaleType,
                  );
                }
              } catch (e) {
                // Ошибка не критична — товар всё равно сохранится
                debugPrint('Ошибка сохранения маппинга: $e');
              }

              setState(() => _isSavingMapping = false);
            }

            widget.onSave(updatedProduct);
            if (mounted) Navigator.pop(context);
          },
          child: _isSavingMapping
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
