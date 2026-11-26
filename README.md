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
- Offline-first SQLite storage for studio records and photos.
- GitHub Actions for automated Android and iOS build checks.

## Current status

**Early functional prototype.** The app has an offline SQLite store with add, edit, list, and delete flows for pottery pieces, materials, kiln firing records, and finished items for sale. Records and photos persist on the device. Marketplace listing drafts can be prepared and copied for manual review and publishing. Structured firing measurements, richer material inventory, search, and backup/export remain planned.

## Build locally

Install the Flutter stable SDK, then run:

```bash
flutter create --platforms=android,ios --project-name pottery_tracker .
flutter pub get
flutter run
```

The `flutter create` command generates the native Android and iOS runner projects. If those folders already exist, do not regenerate them unnecessarily.

## CI builds

GitHub Actions runs on pushes and pull requests to `main`. Android produces release APK artifacts and the iOS workflow compiles an unsigned iOS app on a macOS runner. The iOS app must be signed before it can be installed on a physical iPhone; TestFlight distribution requires Apple signing credentials and an Apple Developer account.

## License

MIT. See [LICENSE](LICENSE). The app includes an **About → Open-source licenses** screen that displays the app's MIT notice and the license notices registered by Flutter and its dependencies. Flutter's license registry supplies the third-party notices at runtime, including transitive packages.
