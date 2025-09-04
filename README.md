# StudyTodo 📚✨

**Красивое Flutter-приложение для управления учебными задачами с ИИ помощником**

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.10+">
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart 3.0+">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Material_Design_3-1976D2?style=for-the-badge&logo=material-design&logoColor=white" alt="Material Design 3">
  <img src="https://img.shields.io/badge/Google_AI-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="Google AI">
</div>

## 🌟 Особенности

### 🔐 **Firebase Authentication**
- **Google Sign-In** для быстрого входа
- **Анонимный вход** для тестирования
- **Пользовательские профили** с аватарами и статистикой
- **Безопасность данных** - каждый пользователь видит только свои задачи
- **Управление аккаунтом** - выход и удаление аккаунта

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
- **Пользовательские данные** - задачи привязаны к аккаунту
- Статусы: в работе, выполнено, просрочено
- Три уровня приоритета с визуальными индикаторами
- **Swipe-действия** для быстрого редактирования
- **Отметка незавершённых** для завершённых задач

### 🎯 **Предметы**
- **20+ цветов** в расширенной палитре
- **Редактирование предметов** с изменением названия и цвета
- **Личные предметы** для каждого пользователя
- Группировка задач по цветам предметов
- Автоматические иконки с первой буквой названия
- Защита от удаления предметов с активными задачами

### 📊 **Личная аналитика и профиль**
- **Объединённый экран** профиля и аналитики
- **Личная статистика** по пользователю
- **Прогресс выполнения** с процентами
- **Аватары** пользователей из Google аккаунта
- Статистика по предметам и задачам
- Отслеживание просроченных задач
- **Динамическая статистика** в реальном времени

### ⚡ **Производительность**
- **Оптимистичные обновления** - UI реагирует мгновенно
- **Offline поддержка** через Firebase Firestore
- **Кэширование данных** для быстрой загрузки
- **Real-time синхронизация** между устройствами
- Минимальные задержки интерфейса

### 🤖 **ИИ Интеграция (Gemini)**
- **Исправление ошибок** в названиях и описаниях
- **Автодополнение** описаний задач
- **Умные предложения** приоритетов и времени
- **Анализ продуктивности** с рекомендациями

### 🔔 **Умные напоминания** (опционально)
- **Уведомления о дедлайнах** за 24 часа
- **Напоминания о планируемом времени**
- **Мотивационные сообщения** о прогрессе
- **Гибкая настройка** частоты уведомлений

### 📱 **Кросс-платформенность**
- Android (полная поддержка)
- iOS (полная поддержка)
- Web (полная поддержка)
- Windows (базовая поддержка)

## 🚀 Технологии

- **Framework**: Flutter 3.10+ / Dart 3.0+
- **Архитектура**: BLoC паттерн с Equatable
- **Backend**: Firebase (Firestore + Authentication)
- **Аутентификация**: Google Sign-In, анонимный вход
- **ИИ**: Google Generative AI (Gemini)
- **Навигация**: go_router
- **UI**: Material Design 3, Google Fonts (Inter)
- **Уведомления**: flutter_local_notifications (опционально)
- **Графики**: fl_chart
- **Состояние**: flutter_bloc + equatable

## 🛠️ Установка и запуск

### Предварительные требования
- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode для соответствующих платформ
- Firebase проект (обязательно для работы с данными)
- Google Cloud проект с Gemini API (для ИИ функций)

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

#### Создание проекта:
- Создайте проект в [Firebase Console](https://console.firebase.google.com/)
- Включите **Firestore Database** (начните в тестовом режиме)
- Включите **Authentication** → **Sign-in method** → **Google** и **Anonymous**

#### Android:
- Добавьте Android приложение с package name `com.example.studytodoapp`
- Скачайте `google-services.json` в папку `android/app/`

#### iOS:
- Добавьте iOS приложение с Bundle ID `com.example.studytodoapp`
- Скачайте `GoogleService-Info.plist` в папку `ios/Runner/`
- Добавьте файл в Xcode проект

#### Web:
- Добавьте Web приложение в Firebase
- Скопируйте конфигурацию в `web/index.html`

4. **Настройте Gemini AI (опционально)**
```dart
// В main.dart инициализируйте AI сервис
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Замените YOUR_API_KEY на ваш ключ от Google AI Studio
  AIService().initialize('YOUR_GEMINI_API_KEY');
  
  await NotificationService().initialize();
  DatabaseService().initialize();
  runApp(StudyTodoApp());
}
```

5. **Запустите приложение**
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

## 🛠️ Структура проекта

```
lib/
├── main.dart                 # Точка входа с Firebase инициализацией
├── blocs/                    # BLoC для управления состоянием
│   ├── auth_bloc.dart       # Аутентификация пользователей
│   ├── subjects_bloc.dart   # Управление предметами
│   └── tasks_bloc.dart      # Управление задачами
├── models/                   # Модели данных
│   ├── task.dart            # Модель задачи
│   ├── subject.dart         # Модель предмета
│   └── user_profile.dart    # Профиль пользователя
├── screens/                  # Экраны приложения
│   ├── home_screen.dart     # Главный экран с задачами
│   ├── subjects_screen.dart # Управление предметами
│   └── analytics_screen.dart # Профиль и аналитика
├── services/                 # Сервисы
│   ├── auth_service.dart    # Firebase Authentication
│   ├── database_service.dart # Firestore операции
│   ├── ai_service.dart      # Gemini AI интеграция
│   └── notification_service.dart # Уведомления
└── widgets/                  # Переиспользуемые виджеты
    ├── main_navigation.dart # Нижняя навигация
    └── task_card.dart       # Карточка задачи
```

### Ключевые файлы конфигурации
- `pubspec.yaml` - зависимости и ресурсы
- `CLAUDE.md` - инструкции для Claude Code
- Firebase конфигурационные файлы

## 🔧 Команды разработчика

```bash
# Анализ кода
flutter analyze

# Запуск тестов
flutter test

# Сборка APK
flutter build apk

# Сборка для iOS
flutter build ios

# Сборка для Web
flutter build web

# Очистка проекта
flutter clean
flutter pub get
```

## 🔒 Безопасность и приватность

- **Изолированные данные**: Каждый пользователь видит только свои задачи и предметы
- **Firebase Security Rules**: Настроены для защиты пользовательских данных
- **Шифрование**: Все данные передаются через HTTPS
- **Анонимность**: Поддержка анонимного входа для тестирования
- **Удаление данных**: Возможность полного удаления аккаунта и данных

## 🏗️ Архитектура

### BLoC Pattern
Приложение использует BLoC паттерн для разделения бизнес-логики и UI:
- **AuthBloc**: Управляет состоянием аутентификации
- **TasksBloc**: Обрабатывает CRUD операции с задачами
- **SubjectsBloc**: Управляет жизненным циклом предметов

### Сервисы
- **Singleton паттерн** для глобального доступа
- **Асинхронные операции** с обработкой ошибок
- **Real-time обновления** через Firebase streams

### Модели данных
- **Immutable модели** с методами копирования
- **JSON сериализация** для Firebase
- **Type-safe** операции с enum'ами

## 🤝 Участие в разработке

1. Форкните репозиторий
2. Создайте feature ветку (`git checkout -b feature/amazing-feature`)
3. Зафиксируйте изменения (`git commit -m 'Add amazing feature'`)
4. Отправьте в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📝 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для подробностей.

## 📞 Поддержка

Если у вас есть вопросы или проблемы:
- Создайте [Issue](https://github.com/yourusername/study-todo-app/issues)
- Обратитесь к [документации Flutter](https://docs.flutter.dev/)
- Ознакомьтесь с [Firebase документацией](https://firebase.google.com/docs)

---

<div align="center">
  <p>Сделано с ❤️ для студентов всего мира</p>
  <p>🚀 <strong>StudyTodo</strong> - управляй временем, достигай целей!</p>
</div>