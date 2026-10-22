# Campus Events — Flutter Lab 01

Offline campus-events manager with 3 tabs (Events, Favourites, Profile), a details screen and a create/edit form. All data is in memory.

## Run

Requires Flutter 3.35+ and Dart 3.9+. On Windows, double-click `../run-sis.cmd` to start in Chrome. The launcher selects the project directory and browser automatically.

For a terminal launch, run commands from this directory (the parent `SIS` directory is not the Flutter project):

```bash
flutter pub get
flutter run -d chrome
```

## Check and build

```bash
flutter analyze
flutter test
flutter test --platform chrome
dart format --output=none --set-exit-if-changed lib test
flutter build web
flutter build apk --debug
```

The Android debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.
Android uses Gradle 8.14, Android Gradle Plugin 8.11.1 and Kotlin 2.2.20, matching the installed Flutter 3.41.2 toolchain. `android.overridePathCheck=true` allows this project's existing Cyrillic directory on Windows.

The regression suite covers search and category/date filters, favourites, form validation, creation and editing, unsaved changes, profile/attendance synchronization, full/past events, deletion, themes, reset confirmation, and phone/tablet/landscape layouts with enlarged text. Model tests cover immutable attendees, copies, countdown boundaries, sample data and formatting.

Data intentionally lives only in memory and resets when the app restarts. New registrations close when an event starts; existing attendees can still leave. Renaming the saved profile updates its registrations.

Windows desktop builds (`flutter run -d windows`) require Visual Studio with the Desktop development with C++ workload. Chrome runs do not need Visual Studio. iOS/macOS builds require macOS and Xcode.

After moving the project, run `flutter clean` and `flutter pub get` from this directory to regenerate build files with the current paths. If cleanup fails on extracted read-only directories, remove the generated `build` and `.dart_tool` directories and the affected platform's `flutter/ephemeral` directory, then run `flutter pub get` again.

## Screenshots

After running, save three real screenshots here:
- `screenshots/phone_light.png`
- `screenshots/phone_dark.png`
- `screenshots/tablet_grid.png`

## Decisions

The event list and profile live in HomeShell state, so all tabs read the same data. Detail receives callbacks so it can change data without owning the source of truth. The form returns an Event through Navigator.pop, letting the caller commit only after a successful save. LayoutBuilder decides between list and grid based on actual available width, not device identity. The form compares a snapshot of current values with the values on opening to detect dirty edits. PopScope intercepts unsaved exits and prompts for confirmation. Derived counts are computed directly from the immutable event record rather than separately stored. With a later state-management lesson, I would move event and profile storage into a dedicated repository and notifier.
