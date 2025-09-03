# StudyTodo 📚✨\n\n**Красивое Flutter-приложение для управления учебными задачами с ИИ помощником**\n\n<div align=\"center\">\n  <img src=\"https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white\" alt=\"Flutter 3.10+\">\n  <img src=\"https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white\" alt=\"Dart 3.0+\">\n  <img src=\"https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black\" alt=\"Firebase\">\n  <img src=\"https://img.shields.io/badge/Material_Design_3-1976D2?style=for-the-badge&logo=material-design&logoColor=white\" alt=\"Material Design 3\">\n</div>


## 🌟 Особенности

### 🎨 **Современный дизайн**
- **Бирюзово-фиолетовая цветовая схема** с Material Design 3
- Адаптивная светлая/тёмная тема
- Плавные анимации и переходы
- Красивые карточки с тенями и скруглёнными углами

### 📋 **Управление задачами**
- **Группировка по предметам** с цветовым кодированием
- **Автоматическая сортировка** по дедлайнам и приоритетам
- **Мгновенное обновление UI** без задержек
- **Редактирование задач** с полным функционалом
- Статусы: в работе, выполнено, просрочено
- Три уровня приоритета с визуальными индикаторами

### 🎯 **Предметы**
- **20+ цветов** в расширенной палитре
- **Редактирование предметов** с изменением названия и цвета
- Группировка задач по цветам предметов
- Автоматические иконки с первой буквой названия

### 📊 **Аналитика**
- Статистика выполнения по предметам
- Прогресс-бары и процент завершения
- Отслеживание просроченных задач
- Общая статистика продуктивности

### ⚡ **Производительность**
- **Оптимистичные обновления** - UI реагирует мгновенно
- Автоматический откат при ошибках
- Кэширование данных
- Минимальные задержки интерфейса

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

### 🤖 **ИИ интеграция**
- Google Gemini AI для улучшения текстов
- Автодополнение задач
- Умные предложения

## 🚀 Технологии

- **Framework**: Flutter 3.10+ / Dart 3.0+
- **Архитектура**: BLoC паттерн с оптимистичными обновлениями
- **База данных**: Firebase Firestore
- **Аутентификация**: Firebase Auth
- **ИИ**: Google Generative AI (Gemini)
- **Навигация**: go_router
- **UI**: Material Design 3, Google Fonts (Inter)
- **Уведомления**: flutter_local_notifications (опционально)
- **Графики**: fl_chart

## 🛠️ Установка и запуск

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