# CLAUDE.md

Read `PROJECT_KNOWLEDGE.md` first — it documents the full architecture, data flow, DB schema,
features, real-vs-mocked status, and known issues.

@PROJECT_KNOWLEDGE.md

## Rules
- Flutter Clean Architecture per feature: data → domain → presentation (BLoC). Register new classes in `lib/di/injection_container.dart`.
- Never edit `lib/core/database/app_database.g.dart`; after schema changes bump `schemaVersion`, add a migration, run `dart run build_runner build --delete-conflicting-outputs`.
- CI fails on formatting and info-level lints. Before finishing: `dart format .`, `flutter analyze --fatal-infos`, `flutter test`.
- Update `PROJECT_KNOWLEDGE.md` when architecture, schema, or feature status changes.



 <!-- first now read and understand totl project architecture , flow function etch and every thing ok , after complete that wait for my call ok -->