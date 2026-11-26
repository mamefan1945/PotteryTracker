# PotteryTracker

A cross-platform pottery studio companion for Android and iOS, built with Flutter.

## Project goals

- Track pottery pieces from clay preparation through completion.
- Organize clay bodies, glazes, glaze recipes, ingredients, and test tiles.
- Record kiln loads, firing schedules, cone targets, and firing results.
- Keep studio notes, inventory, costs, photos, and project history together.
- Work offline, with reliable export and backup.

## Technology

- Flutter and Dart for a shared Android/iOS application.
- Offline-first data storage (database implementation is part of the next development phase).
- GitHub Actions for automated Android and iOS build checks.

## Current status

**Early functional prototype.** The app now has an offline SQLite store and working add/list/delete flows for pottery pieces, materials, and kiln firing records. Records persist on the device. Structured firing measurements, richer material inventory, photos, editing, search, and backup/export are planned next.

## Build locally

Install the Flutter stable SDK, then run:

```bash
flutter create --platforms=android,ios --project-name pottery_tracker .
flutter pub get
flutter run
```

The `flutter create` command generates the native Android and iOS runner projects. If those folders already exist, do not regenerate them unnecessarily.

## CI builds

GitHub Actions runs on pushes and pull requests to `main`. Android produces a debug APK artifact. The iOS workflow compiles an unsigned iOS build on a macOS runner; distribution through TestFlight requires Apple signing credentials and an Apple Developer account.

## License

MIT. See [LICENSE](LICENSE).
