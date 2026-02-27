# Spetaka

Private friend relationship intelligence — Android (Flutter).

## Getting Started

### Prerequisites

- Flutter ≥ 3.22 (stable channel)
- Android SDK with API 26+ (minSdkVersion 26)
- Java 11+

### First-time setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --release
```

### Architecture

Feature-first clean architecture:

```
lib/
  core/       # Cross-cutting infrastructure (database, encryption, utils)
  features/   # Feature modules (friends, events, daily-view, sync, …)
  shared/     # Design system tokens, shared widgets, cross-feature utilities
```

### Permissions

Only two Android permissions are declared:
- `READ_CONTACTS` — for contact import when creating friend cards
- `INTERNET` — for WebDAV backup/sync
