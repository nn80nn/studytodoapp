# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StudyTodo is a Flutter application for managing study tasks with AI integration. It features task management, subject organization, analytics, and AI-powered suggestions using Google's Gemini AI. The app supports both authenticated users (Firebase) and anonymous users (local SQLite), with hybrid data synchronization.

## Key Technologies

- **Flutter SDK**: >=3.10.0, Dart SDK >=3.0.0
- **State Management**: BLoC pattern with flutter_bloc and equatable
- **Backend**: Hybrid Firebase + SQLite (offline-first with cloud sync)
- **Database**: SQLite (sqflite) for local storage, Firestore for cloud sync
- **Authentication**: Firebase Auth (Google Sign-In, Email/Password, Anonymous)
- **AI Integration**: Google Generative AI (Gemini) for text correction and task suggestions
- **Navigation**: go_router for declarative routing
- **UI**: Material Design 3 with Google Fonts (Inter family)
- **Notifications**: flutter_local_notifications (currently disabled in pubspec.yaml)
- **Analytics**: fl_chart for data visualization
- **Connectivity**: connectivity_plus for online/offline detection

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (development)
flutter run --debug

# Run on specific platforms
flutter run -d android
flutter run -d ios
flutter run -d web
flutter run -d windows

# Run tests
flutter test                              # All tests
flutter test test/models/                 # Model tests only
flutter test test/blocs/                  # BLoC tests only
flutter test test/services/               # Service tests only
flutter test test/widgets/                # Widget tests only
flutter test test/integration/            # Integration tests only

# Run specific test file
flutter test test/blocs/tasks_bloc_test.dart

# Analyze code
flutter analyze

# Build for release
flutter build apk
flutter build ios
flutter build web

# Clean and rebuild
flutter clean && flutter pub get && flutter run
```

## Architecture Overview

### Hybrid Data Storage Strategy

The app implements a sophisticated offline-first architecture with automatic cloud synchronization:

1. **SQLite as Primary Storage**: All data operations use local SQLite database first
2. **Firebase as Cloud Backup**: Authenticated users sync data to Firestore
3. **Anonymous Support**: Users can work offline without any account
4. **Seamless Migration**: Anonymous data migrates to cloud when user signs in

### Authentication Flow

The authentication system supports multiple entry points through `AuthWrapper`:

- **AuthUnauthenticated** → Shows `AuthScreen` with login options
- **AuthAuthenticated** → Shows `MainNavigation` with app content
- **Anonymous Mode** → Creates local-only user with SQLite
- **Account Migration** → Moves anonymous data to Firebase on sign-in

### Core Architecture Patterns

```
main.dart
├── AuthWrapper (routes based on auth state)
│   ├── AuthScreen (login/register/anonymous)
│   └── MainNavigation (bottom nav + screens)
│       ├── HomeScreen (tasks)
│       ├── SubjectsScreen (subjects)
│       └── AnalyticsScreen (profile + charts)
```

### State Management Architecture

- **AuthBloc**: Manages user authentication state and profile
- **TasksBloc**: Handles task CRUD operations and filtering
- **SubjectsBloc**: Manages subject lifecycle and colors
- All BLoCs provided at app level in `main.dart`
- Events/States extend Equatable for proper comparison

### Service Layer

- **DatabaseService**: Hybrid storage coordinator (SQLite + Firestore)
- **SQLiteService**: Local database operations
- **AuthService**: Firebase Authentication wrapper
- **AIService**: Gemini AI integration for text improvement
- **NotificationService**: Local notifications (disabled)

## Critical Architecture Details

### DatabaseService Hybrid Strategy

The `DatabaseService` implements a complex offline-first strategy:

```dart
// Always loads from SQLite first for immediate UI response
List<Task> localTasks = await _sqlite.getTasks(userId);

// Syncs with Firebase in background for authenticated users
if (_firebaseAvailable && isAuthenticatedUser) {
  _syncTasksInBackground();
}
```

Key methods:
- `initialize()`: Sets up SQLite, connectivity listeners, Firebase
- `migrateToUser(userId)`: Moves anonymous data to authenticated user
- `syncWithCloud()`: Manual sync trigger
- `_syncInBackground()`: Automatic background sync
- `clearAllUserData()`: Complete data wipe (local + cloud) while preserving all-time stats
- `_incrementTotalCompletedAllTime()`: Auto-increments lifetime completed tasks counter

### User Model Architecture

- **Anonymous Users**: Generated UUID, stored only in SQLite
- **Authenticated Users**: Firebase UID, data in both SQLite and Firestore
- **UserProfile**: Contains stats, Gemini API key, authentication state
- **Migration Path**: Anonymous → Authenticated preserves all data

### Error Handling Patterns

Firebase operations use specific error handling:
```dart
try {
  // Firebase operation
} on FirebaseAuthException catch (e) {
  // Handle Firebase Auth errors specifically
  rethrow;
} catch (e) {
  // Handle general errors
  rethrow;
}
```

## Data Models

### Task Model
```dart
{
  id: String,
  userId: String,
  subjectId: String,
  title: String,
  description?: String,
  deadline: DateTime,
  plannedTime?: int,
  priority: TaskPriority,
  status: TaskStatus,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

### Subject Model
```dart
{
  id: String,
  userId: String,
  name: String,
  color: int (Color.value),
  description?: String,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

### UserProfile Model
```dart
{
  uid: String,
  email?: String,
  displayName?: String,
  photoURL?: String,
  isAnonymous: bool,
  createdAt: DateTime,
  lastLoginAt: DateTime,
  totalTasks: int,
  completedTasks: int,
  totalSubjects: int,
  totalCompletedAllTime: int,  // All-time completed tasks counter (including deleted)
  geminiApiKey?: String
}
```

## Configuration Requirements

### Firebase Setup
1. Create Firebase project with Firestore Database and Authentication enabled
2. Add platform-specific config files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Web: Configure in `web/index.html`
3. Enable Authentication methods: Google, Email/Password, Anonymous
4. Set up Firestore security rules for user data isolation

### Firestore Security Rules
Users can only access their own data:
```javascript
match /tasks/{taskId} {
  allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
}
```

### AI Service Setup
- Gemini API keys are stored per-user in UserProfile
- Users configure their own API keys through the app interface
- No global API key configuration needed

## Code Conventions

- **Language**: Russian for UI text and user-facing strings
- **DateTime Storage**: millisecondsSinceEpoch for Firebase compatibility
- **Error Handling**: Specific Firebase exception types, then general catch
- **Singleton Services**: All services use singleton pattern
- **Model Serialization**: toJson()/fromJson() for both SQLite and Firebase
- **State Equality**: All BLoC events/states extend Equatable
- **Theme**: Material Design 3 with custom teal/purple color scheme

## Testing Architecture

The project includes comprehensive test coverage:
- **Unit Tests**: Models, services, BLoCs
- **Widget Tests**: UI components and screens
- **Integration Tests**: Full app workflows
- **Test Helpers**: Shared mocks and utilities

Test utilities use:
- `mockito` for service mocking
- `bloc_test` for BLoC testing
- `integration_test` for E2E testing

Run tests with specific focus:
```bash
flutter test test/blocs/tasks_bloc_test.dart --coverage
flutter test test/integration/ --verbose
```

## Common Development Patterns

### Adding New Features
1. Create/update models with SQLite and Firebase serialization
2. Add BLoC events and states
3. Implement business logic in service layer
4. Update UI components
5. Add comprehensive tests

### Working with Hybrid Storage
Always load from SQLite first, then sync with Firebase:
```dart
// Load local data immediately
final localData = await _sqlite.getData(userId);
// Sync with cloud in background
_syncWithCloud();
```

### Authentication State Changes
Handle authentication transitions in AuthBloc:
- Anonymous → Authenticated: Migrate data
- Authenticated → Unauthenticated: Show auth screen
- Any → Any: Update DatabaseService user context

## Known Issues and Workarounds

### Google Sign-In in Development
- Google Sign-In may fail in emulator due to OAuth configuration
- Use email/password or anonymous mode for development
- Temporarily disabled in auth screen with "недоступно" label

### Firestore Index Requirements
When testing with real Firebase, create required indexes:
- Collection: tasks, Fields: userId (Ascending), updatedAt (Ascending)
- Collection: subjects, Fields: userId (Ascending), updatedAt (Ascending)

### Notifications Currently Disabled
`flutter_local_notifications` is commented out in pubspec.yaml due to platform compatibility issues. Re-enable when needed.

## Recent Features and Updates

### Analytics and Statistics
- **All-time completed tasks tracking**: `totalCompletedAllTime` field preserves lifetime achievements
- **Auto-increment on task completion**: Automatic tracking when tasks are marked as completed
- **Data persistence through wipes**: All-time stats survive data clearing operations
- **Analytics screen updates**: Enhanced statistics display with historical data

### Data Management
- **Complete data clearing**: Users can wipe all tasks and subjects while preserving achievements
- **Dual confirmation dialogs**: Safety measures to prevent accidental data loss
- **Progress indicators**: Loading states for data clearing and sync operations
- **Error handling improvements**: Better Navigator context management for dialogs

### UI/UX Improvements
- **Enhanced PopupMenu**: Clear data option alongside account deletion
- **Visual separation**: Statistics divided into current vs. all-time metrics
- **Loading dialog fixes**: Proper dialog dismissal after operations complete

## Performance Considerations

- SQLite operations are synchronous within async functions
- Firebase operations use optimistic updates (local first, sync later)
- Real-time streams only enabled for authenticated users
- Connectivity monitoring prevents unnecessary Firebase calls
- Large datasets use pagination and lazy loading
- Dialog management uses captured Navigator references to prevent context issues