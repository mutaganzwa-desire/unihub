# Deployment guide

## Prerequisites
- `flutter pub get` succeeds.
- `flutterfire configure` has generated `firebase_options.dart`.
- Rules and indexes deployed (see firebase_setup.md).

## Android
```bash
flutter build appbundle --release
```
Upload the `.aab` to Google Play. Ensure `google-services.json` is present and
the signing config set in `android/app/build.gradle`.

## iOS
```bash
flutter build ipa --release
```
Open `ios/Runner.xcworkspace`, set the team/signing, and distribute via
Xcode/Transporter. Ensure `GoogleService-Info.plist` and the push capability
are configured.

## Backend
```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```
(`functions` only if you added the push-delivery/verification callable
functions described in firebase_setup.md.)

## Release checklist
- Crashlytics enabled (automatic in release builds).
- Analytics collection enabled (set in `bootstrap()`).
- App verified against a production Firebase project, not the emulator.
