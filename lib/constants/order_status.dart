// lib/constants/order_status.dart
// Единый источник истины для статусов заказов

/// Статусы заказов
enum OrderStatus {
  pending, // Ожидает оплаты
  paid, // Оплачен
  shipped, // Отправлен
  delivered, // Доставлен
  cancelled // Отменен
}

/// Порядок статусов в жизненном цикле заказа (для прогресса)
const List<String> orderStatusFlow = [
  'pending',
  'paid',
  'shipped',
  'delivered'
];

/// Переводы статусов на русский язык
const Map<String, String> statusTexts = {
  'pending': 'Ожидает оплаты',
  'paid': 'Оплачен',
  'shipped': 'Отправлен',
  'delivered': 'Доставлен',
  'cancelled': 'Отменен'
};

/// Цвета для отображения статусов
const Map<String, String> statusColors = {
  'pending': 'orange',
  'paid': 'green',
  'shipped': 'blue',
  'delivered': 'green',
  'cancelled': 'red'
};

/// Утилиты для работы со статусами
class OrderStatusUtils {
  /// Получить индекс статуса в жизненном цикле
  static int getStatusIndex(String status) {
    return orderStatusFlow.indexOf(status);
  }

  /// Проверить, завершен ли статус (относительно другого)
  static bool isStatusCompleted(String currentStatus, String checkStatus) {
    // Отмененные заказы не имеют прогресса
    if (currentStatus == 'cancelled') return false;

    final currentIndex = getStatusIndex(currentStatus);
    final checkIndex = getStatusIndex(checkStatus);

    // Если статус не найден в потоке, считаем незавершенным
    if (currentIndex == -1 || checkIndex == -1) return false;

    return currentIndex >= checkIndex;
  }
}
