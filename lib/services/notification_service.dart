// Заглушка для NotificationService без внешних зависимостей
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // Пустая реализация - уведомления временно отключены
    print('NotificationService initialized (stub)');
  }

  Future<void> scheduleTaskReminder(Task task) async {
    // Пустая реализация - уведомления временно отключены
    print('Task reminder scheduled for: ${task.title}');
  }

  Future<void> scheduleMotivationalNotification() async {
    // Пустая реализация - уведомления временно отключены
    print('Motivational notification scheduled');
  }
}