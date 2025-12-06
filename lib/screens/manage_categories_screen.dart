// lib/screens/manage_categories_screen.dart
// Новый экран для управления категориями

import 'package:flutter/material.dart';
import '../services/admin_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ManageCategoriesScreen extends StatefulWidget {
  @override
  _ManageCategoriesScreenState createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final AdminApiService _apiService = AdminApiService();
  final ImagePicker _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getCategories();
      setState(() {
        _categories =
            List<Map<String, dynamic>>.from(response['categories'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки категорий: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createCategory() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Создать категорию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Название категории *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание (опционально)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Введите название категории')),
                );
                return;
              }

              try {
                await _apiService.createCategory(
                  name,
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                );
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Создать'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Категория создана')),
        );
      }
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить категорию?'),
        content: Text(
            'Вы уверены, что хотите удалить категорию "${category['name']}"?'),
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

    if (confirmed != true) return;

    try {
      final response = await _apiService.deleteCategory(category['id']);

      if (response['success']) {
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Категория удалена')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _uploadCategoryImage(Map<String, dynamic> category) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      await _apiService.uploadCategoryImage(
        category['id'],
        File(image.path),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Картинка загружена')),
      );

      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategoryImage(Map<String, dynamic> category) async {
    // Показываем подтверждение
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить картинку?'),
        content: Text(
            'Вы уверены, что хотите удалить картинку категории "${category['name']}"?'),
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

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      await _apiService.deleteCategoryImage(category['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Картинка удалена')),
      );

      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllEmptyCategories() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить все пустые категории?'),
        content: Text(
          'Будут удалены все категории, в которых нет товаров. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить все пустые'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.deleteAllEmptyCategories();

      if (response['success']) {
        await _loadCategories();
        if (mounted) {
          final deleted = response['deleted'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Удалено пустых категорий: $deleted'),
              backgroundColor: deleted > 0 ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Управление категориями'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Удалить все пустые',
            onPressed: _categories.isEmpty ? null : _deleteAllEmptyCategories,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCategories,
                        child: Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Нет категорий',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Создайте первую категорию',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: category['imageUrl'] != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      'https://api.sevkorzina.ru${category['imageUrl']}',
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor: Colors.blue[100],
                                    child: Text(
                                      '${category['id']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                            title: Text(
                              category['name'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: category['description'] != null
                                ? Text(category['description'])
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Кнопка загрузки/изменения картинки
                                IconButton(
                                  icon: Icon(
                                    category['imageUrl'] != null
                                        ? Icons.edit
                                        : Icons.image,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _uploadCategoryImage(category),
                                  tooltip: category['imageUrl'] != null
                                      ? 'Изменить картинку'
                                      : 'Загрузить картинку',
                                ),
                                // Кнопка удаления картинки (только если есть картинка)
                                if (category['imageUrl'] != null)
                                  IconButton(
                                    icon: Icon(Icons.image_not_supported,
                                        color: Colors.orange),
                                    onPressed: () =>
                                        _deleteCategoryImage(category),
                                    tooltip: 'Удалить картинку',
                                  ),
                                // Кнопка удаления категории
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _deleteCategory(category),
                                  tooltip: 'Удалить категорию',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCategory,
        icon: Icon(Icons.add),
        label: Text('Создать категорию'),
      ),
    );
  }
}
