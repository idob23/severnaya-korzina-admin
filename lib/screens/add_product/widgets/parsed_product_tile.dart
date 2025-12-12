import 'package:flutter/material.dart';

class ParsedProductTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onToggleSaleType;

  const ParsedProductTile({
    super.key,
    required this.item,
    required this.index,
    required this.isSelected,
    required this.isHighlighted,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onRemove,
    required this.onAdd,
    required this.onToggleSaleType,
  });

  @override
  Widget build(BuildContext context) {
    final saleType = item['saleType'] ?? 'поштучно';
    final isPoshtuchno = saleType == 'поштучно';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isHighlighted
          ? Colors.amber[100]
          : isSelected
              ? Colors.blue[50]
              : null,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => onToggleSelect(),
        ),
        title: Text(item['name'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                Text('${item['price']} ₽ / ${item['unit']}'),
                if (item['maxQuantity'] != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                  Text('${item['maxQuantity']}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            if (item['originalCategory'] != null)
              Text(
                'Excel: ${item['originalCategory']}',
                style: TextStyle(fontSize: 11, color: Colors.blue[600]),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item['suggestedCategoryId'] != null
                    ? Colors.green[100]
                    : Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'БД: ${item['suggestedCategoryName'] ?? 'Не определена'}',
                style: TextStyle(
                  fontSize: 11,
                  color: item['suggestedCategoryId'] != null
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              onTap: onToggleSaleType,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isPoshtuchno ? Colors.blue[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color:
                        isPoshtuchno ? Colors.blue[300]! : Colors.orange[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPoshtuchno
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 12,
                      color:
                          isPoshtuchno ? Colors.blue[700] : Colors.orange[700],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      isPoshtuchno ? 'Поштучно' : 'Только уп',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isPoshtuchno
                            ? Colors.blue[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: onEdit,
                  tooltip: 'Редактировать',
                ),
                IconButton(
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red[400], size: 16),
                  onPressed: onRemove,
                  tooltip: 'Убрать из списка',
                ),
                IconButton(
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.add_circle,
                      color: Colors.green, size: 16),
                  onPressed: onAdd,
                  tooltip: 'Добавить в базу',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
