# MyLife

A cross-platform personal life management app built with Flutter.
Combines task planning, money tracking, notes, reminders,
PDF reporting, and AI-assisted insights into one local-first,
privacy-focused productivity app.

## Core Features

- Task management with categories, priorities, due dates,
  reminders, and completion tracking
- Money tracking for payables, receivables, and bills
  with overdue status and paid toggles
- Notes with color labels, pin-to-top support,
  and edit/delete actions
- Home dashboard with summary cards and today's pending items
- Global search across tasks and money entries
- Local PIN lock with biometric fallback
- Settings screen for PIN changes, biometric toggle,
  and secure API key management
- Scheduled local notifications and reminders
- PDF monthly report export for money entries
- AI query support for task summaries and spending analysis
  via Claude API

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter + Dart |
| Local Database | SQLite via `sqflite` |
| Secure Storage | `flutter_secure_storage` (encrypted, device keystore) |
| Notifications | `flutter_local_notifications` |
| Biometric Auth | `local_auth` |
| Preferences | `shared_preferences` |
| HTTP | `http` |
| PDF Generation | `pdf` |
| Charting | `fl_chart` |
| Date/Timezone | `intl`, `timezone` |
| Hashing | `crypto` (SHA256) |

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # Root MaterialApp + theme
├── theme.dart                         # Shared color constants
├── models/                            # Task, MoneyEntry, NoteItem
├── services/                          # DatabaseService, NotificationService,
│                                      # ReportService, AuthService,
│                                      # ClaudeService, SecureStorageService
├── widgets/                           # Shared widgets (PIN pad, stat cards)
└── screens/                           # One file per screen
    ├── home/
    ├── tasks/
    ├── money/
    ├── notes/
    ├── ai/
    ├── settings/
    └── lock/                          # PIN/biometric lock flow
```

## Current Status

- ✅ Builds and runs on Android
- ✅ Task, money entry, and notes — full CRUD support
- ✅ App lock with PIN and biometric authentication
- ✅ PDF monthly report export
- ✅ Claude API integration for AI-powered summaries
- ✅ Encrypted API key storage via device keystore
- ✅ Modular architecture — models, services, widgets, screens
- ✅ Unit tests for models and AuthService
- ✅ Widget smoke test for PIN flow

## How to Run

1. Install Flutter and configure your platform SDKs
2. Clone the repository
3. Run `flutter pub get`
4. Run `flutter run` on a connected device or emulator

## Security Notes

- All data is stored locally on device (SQLite + shared preferences)
- Claude API key is stored via `flutter_secure_storage`
  using the device keystore/keychain — never in plaintext
- PIN is hashed with SHA256 before storage

## Future Improvements

- Tablet and desktop responsive layout
- Expanded database layer test coverage
