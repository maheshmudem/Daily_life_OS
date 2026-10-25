# Daily Life OS

![CI](https://github.com/maheshmudem/Daily_life_OS/actions/workflows/ci.yml/badge.svg)
![Release](https://github.com/maheshmudem/Daily_life_OS/actions/workflows/release.yml/badge.svg)

An intelligent, unified personal operating system for daily routines, productivity, and lifestyle.

## Features

- 🗓️ **Planner** — Reminders, recurring habits, and task management with priority levels
- ⏱️ **Pomodoro Timer** — Focus sessions with countdown tracking
- 🔒 **Security** — Biometric authentication and PIN protection
- 📊 **Productivity Metrics** — Track completion rates and overdue items

## Getting Started

### Prerequisites

- Flutter SDK `3.44.6` (stable channel)
- Dart `3.12.2`

### Installation

```bash
# Clone the repository
git clone https://github.com/maheshmudem/Daily_life_OS.git
cd Daily_life_OS

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Static analysis
flutter analyze
```

## CI/CD Pipeline

This project uses **GitHub Actions** for automated quality checks and releases.

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| **CI** | Push to `main`/`dev`, PRs | Format → Analyze → Test |
| **Release** | Push tag `v*` | CI checks → Build APK/AAB → GitHub Release |

### Creating a Release

```bash
# Tag the current commit
git tag v1.0.0

# Push the tag to trigger the release pipeline
git push origin v1.0.0
```

## Architecture

- **State Management**: BLoC pattern (`flutter_bloc`)
- **Dependency Injection**: `get_it`
- **Navigation**: `go_router`
- **Database**: Drift (SQLite)
- **Security**: `flutter_secure_storage` + `local_auth`

## License

This project is private and not published to pub.dev.
