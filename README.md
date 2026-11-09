# WaZaqer (وَذَكِر)

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

## Content attribution

The adhkar texts (`assets/adhkar.json`) are supplications and remembrances
transmitted in the public-domain hadith collections (Sahih al-Bukhari, Sahih
Muslim, Sunan Abi Dawud, Jami` at-Tirmidhi, Sunan an-Nasa'i, Sunan ibn Majah,
Musnad Ahmad and others), cited per dhikr in the `source` field. They are
ancient religious texts with no copyright holder; only their compilation was
taken from public datasets, and the category arrangement is this project's own.

The bundled Arabic fonts are under the SIL Open Font License, each with its
license text in `assets/fonts/OFL-*.txt`: Amiri, Scheherazade New, Noto Naskh
Arabic, Cairo, Reem Kufi and Tajawal (source: google/fonts).
