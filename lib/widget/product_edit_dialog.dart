// lib/widgets/product_edit_dialog.dart - Диалог редактирования товара
import 'package:flutter/material.dart';

class ProductEditDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> categories;
  final Function(Map<String, dynamic>) onSave;

  const ProductEditDialog({
    Key? key,
    required this.product,
    required this.categories,
    required this.onSave,
  }) : super(key: key);

  @override
  _ProductEditDialogState createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;

  int? _selectedCategoryId;
  bool _isApproved = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.product['name'] ?? '');
    _priceController = TextEditingController(
      text: widget.product['price']?.toString() ?? '0',
    );
    _unitController =
        TextEditingController(text: widget.product['unit'] ?? 'шт');
    _descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );

    _selectedCategoryId = widget.product['suggestedCategoryId'];
    _isApproved = widget.product['isApproved'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Редактирование товара',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Поля формы
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Название товара
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Название товара',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_bag),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Введите название товара';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16),

                        // Цена и единица измерения
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: 'Цена',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                  suffixText: '₽',
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Введите цену';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price < 0) {
                                    return 'Неверная цена';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _unitController,
                                decoration: InputDecoration(
                                  labelText: 'Ед. изм.',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.straighten),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Введите единицу';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Категория
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Категория',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: widget.categories.map((category) {
                            return DropdownMenuItem<int>(
                              value: category['id'],
                              child: Text(category['name']),
                            );
                          }).toList(),
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

                        SizedBox(height: 16),

                        // Описание
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Описание (необязательно)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),

                        SizedBox(height: 16),

                        // Статус товара
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isApproved
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color:
                                    _isApproved ? Colors.green : Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Статус товара',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _isApproved
                                          ? 'Подтвержден'
                                          : 'Требует проверки',
                                      style: TextStyle(
                                        color: _isApproved
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isApproved,
                                onChanged: (value) {
                                  setState(() {
                                    _isApproved = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        // Информация об источнике
                        if (widget.product['source'] != null) ...[
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Источник данных',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(_getSourceDescription(
                                          widget.product['source'])),
                                      if (widget
                                              .product['categoryConfidence'] !=
                                          null)
                                        Text(
                                          'Точность категории: ${(widget.product['categoryConfidence'] * 100).toInt()}%',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Кнопки действий
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Отмена'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSourceDescription(String source) {
    switch (source) {
      case 'CSV_PARSE':
        return 'Импортировано из CSV файла';
      case 'TEXT_PARSE':
        return 'Импортировано из текстового файла';
      case 'OCR_PARSE':
        return 'Распознано с изображения (OCR)';
      case 'MANUAL':
        return 'Добавлено вручную';
      default:
        return 'Неизвестный источник';
    }
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Находим название выбранной категории
    final selectedCategory = widget.categories.firstWhere(
      (cat) => cat['id'] == _selectedCategoryId,
      orElse: () => {'name': 'Неизвестная категория'},
    );

    final updatedProduct = {
      ...widget.product,
      'name': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'unit': _unitController.text.trim(),
      'description': _descriptionController.text.trim(),
      'suggestedCategoryId': _selectedCategoryId,
      'suggestedCategory': selectedCategory['name'],
      'isApproved': _isApproved,
    };

    widget.onSave(updatedProduct);
    Navigator.pop(context);
  }
}
