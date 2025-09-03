# StudyTodo - Умное приложение для управления учебными задачами

![StudyTodo Banner](https://via.placeholder.com/800x200/6366f1/ffffff?text=StudyTodo)

## 🌟 Особенности

### ✨ Основной функционал
- **Быстрое добавление задач** с минимальным количеством кликов
- **Управление предметами** с цветовой кодировкой
- **Дедлайны и планирование** времени выполнения
- **Приоритеты задач** (низкий, средний, высокий)
- **Свайп-жесты** для быстрых действий

### 🤖 ИИ Интеграция (Gemini)
- **Исправление ошибок** в названиях и описаниях
- **Автодополнение** описаний задач
- **Умные предложения** приоритетов и времени
- **Анализ продуктивности** с рекомендациями

### 📊 Аналитика и статистика
- **Графики активности** по дням недели
- **Прогресс по предметам** с диаграммами
- **Достижения** и мотивационные сообщения
- **Анализ продуктивности** по времени

### 🔔 Умные напоминания
- **Уведомления о дедлайнах** за 24 часа
- **Напоминания о планируемом времени**
- **Мотивационные сообщения** о прогрессе
- **Гибкая настройка** частоты уведомлений

### 🎨 Современный дизайн
- **Material Design 3** с темной и светлой темой
- **Плавные анимации** и переходы
- **Адаптивный интерфейс** для всех устройств
- **Красивые графики** и визуализации

## 🚀 Быстрый старт

### Предварительные требования
- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode для соответствующих платформ
- Firebase проект (для backend)

### Установка

1. **Клонируйте репозиторий**
```bash
git clone https://github.com/yourusername/study-todo-app.git
cd study-todo-app
```

2. **Установите зависимости**
```bash
flutter pub get
```

3. **Настройте Firebase**

#### Android:
- Создайте проект в [Firebase Console](https://console.firebase.google.com/)
- Добавьте Android приложение с package name `com.example.study_todo_app`
- Скачайте `google-services.json` в папку `android/app/`
- Включите Firestore Database и Authentication

#### iOS:
- Добавьте iOS приложение с Bundle ID `com.example.studyTodoApp`
- Скачайте `GoogleService-Info.plist` в папку `ios/Runner/`
- Добавьте файл в Xcode проект

#### Web:
- Добавьте Web приложение в Firebase
- Скопируйте конфигурацию в `web/index.html`

4. **Настройте Gemini AI**
```dart
// В main.dart инициализируйте AI сервис
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Замените YOUR_API_KEY на ваш ключ от Google AI
  AIService().initialize('YOUR_GEMINI_API_KEY');
  
  await NotificationService().initialize();
  runApp(StudyTodoApp());
}
```

5. **Запустите приложение**
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d web

# Windows
flutter run -d windows
```

## 🛠️ Структура проекта

```
lib/
├── main.dart                 # Точка входа
├── blocs/                    # BLoC для управления состоянием
│   ├── subjects_bloc.