# WaZaqer (وذكر)

A free and open-source Flutter app for daily adhkar (remembrance): after prayer, morning, evening, and sleep.

تطبيق حر ومفتوح المصدر للأذكار اليومية: أذكار بعد الصلاة، الصباح، المساء، والنوم.

## Status

The app is being rebuilt from scratch. The first release will follow the new UI/UX design.

## Build

Requires the Flutter SDK (stable channel).

```sh
flutter pub get
flutter build apk --release     # Android
flutter build linux --release   # Linux desktop
```

or run it directly with `flutter run`.

## F-Droid

Fastlane metadata lives in `fastlane/metadata/android/` (English and Arabic), ready to be referenced from an fdroiddata build recipe.

## License

GPL-3.0. See [LICENSE](LICENSE).
