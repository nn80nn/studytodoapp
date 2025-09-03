# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StudyTodo is a Flutter application for managing study tasks with AI integration. It features task management, subject organization, analytics, and AI-powered suggestions using Google's Gemini AI.

## Key Technologies

- **Flutter SDK**: >=3.10.0, Dart SDK >=3.0.0
- **State Management**: BLoC pattern with flutter_bloc and equatable
- **Backend**: Firebase (Firestore for data, Firebase Auth for authentication)
- **AI Integration**: Google Generative AI (Gemini) for text correction and task suggestions
- **Navigation**: go_router for declarative routing
- **UI**: Material Design 3 with Google Fonts (Inter family)
- **Notifications**: flutter_local_notifications with timezone support
- **Analytics**: fl_chart for data visualization

## Architecture

The app follows a layered architecture with BLoC pattern:

```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── models/                   # Data models (Task, Subject)
├── blocs/                    # BLoC state management
│   ├── tasks_bloc.dart      # Task CRUD operations and state
│   └── subjects_bloc.dart   # Subject management state
├── services/                # Business logic and external integrations
│   ├── database_service.dart # Firebase Firestore operations
│   ├── ai_service.dart      # Gemini AI integration
│   └── notification_service.dart # Local notifications
├── screens/                 # Main app screens
│   ├── home_screen.dart     # Task list and quick actions
│   ├── subjects_screen.dart # Subject management
│   └── analytics_screen.dart # Statistics and charts
└── widgets/                 # Reusable UI components
```

### Core Models

- **Task**: `{id, subjectId, title, description?, deadline, plannedTime?, priority, status, createdAt}`
- **Subject**: `{id, name, color, description?, createdAt}`
- **Enums**: TaskPriority (low, medium, high), TaskStatus (pending, completed, overdue)

### State Management

- Uses BLoC pattern with events and states
- `TasksBloc` handles CRUD operations for tasks
- `SubjectsBloc` manages subject lifecycle
- All BLoCs are provided at app level in `main.dart`

### Services

- **DatabaseService**: Singleton pattern for Firestore operations with both one-time queries and real-time streams
- **AIService**: Singleton for Gemini AI integration (text correction, task auto-completion)
- **NotificationService**: Manages local notifications and reminders

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (development)
flutter run

# Run on specific platforms
flutter run -d android
flutter run -d ios
flutter run -d web
flutter run -d windows

# Build for release
flutter build apk
flutter build ios
flutter build web

# Run tests
flutter test

# Analyze code
flutter analyze

# Generate code (if using build_runner)
flutter packages pub run build_runner build
```

## Configuration Requirements

### Firebase Setup
1. Create Firebase project with Firestore Database and Authentication enabled
2. Add platform-specific config files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Web: Configure in `web/index.html`

### AI Service Setup
- Requires Gemini API key initialization in `main.dart`:
```dart
AIService().initialize('YOUR_GEMINI_API_KEY');
```

### Assets Structure
- `assets/images/` - App images
- `assets/icons/` - Custom icons
- `fonts/` - Inter font family (Regular, Medium, Bold)

## Code Conventions

- Uses Russian language for UI text and AI prompts
- Follows standard Flutter/Dart conventions with flutter_lints
- Models include `toJson()` and `fromJson()` methods for Firebase serialization
- Services use singleton pattern for global access
- All DateTime fields stored as millisecondsSinceEpoch for Firebase compatibility
- BLoC events and states extend Equatable for proper comparison
- UI uses Material Design 3 with both light and dark theme support

## Key Features to Understand

1. **Quick Task Addition**: Bottom sheet with minimal input fields
2. **AI Integration**: Text correction and smart task completion suggestions
3. **Swipe Actions**: Task cards support swipe gestures for quick actions
4. **Real-time Updates**: Firestore streams for live data synchronization
5. **Analytics**: Charts showing productivity patterns and subject progress
6. **Smart Notifications**: Context-aware reminders based on deadlines and planned times

## Testing Notes

- No specific test configuration found beyond standard flutter_test
- When adding tests, follow Flutter testing conventions for widgets, units, and integration tests