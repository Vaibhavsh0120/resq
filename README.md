# ResQ

ResQ is a cross-platform personal safety companion built with Flutter and
Firebase. Its long-term goal is to help people prepare for emergencies, receive
trusted guidance, contact help, coordinate with family, report hazards, and find
nearby safe places from one application.

> ResQ is currently an early-stage project. It is not a replacement for local
> emergency services, professional medical advice, or official government alerts.

## Current milestone

This repository currently implements the startup, authentication, and onboarding
foundation:

- Light, dark, and system themes using the Precision Light visual language
- Theme-aware startup video on Android and iOS; tap anywhere to skip
- No startup video on web
- Email/password sign-in and account creation
- Google sign-in
- Password-reset email
- Anonymous Emergency access for quick guest entry
- Four-step, resumable onboarding stored in Firestore
  - Personal information
  - Medical and accessibility information
  - Family Circle contacts
  - Address, GPS coordinates, and OpenStreetMap preview
- Responsive layouts for phones, tablets, landscape displays, and desktop web
- Haptic feedback on supported mobile devices
- Minimal authenticated home screen with logout

SOS activation, emergency calling, live family tracking, incident reporting,
preparedness checklists, alerts, and safe-place discovery are planned features and
are not implemented yet.

## Technology

- Flutter `3.47.4` on the stable channel
- Dart `3.13.3` or compatible
- Firebase Authentication
- Cloud Firestore
- OpenStreetMap through `flutter_map`—no paid map API key
- GitHub Actions for Android and iOS release artifacts

The Flutter version used by CI is the safest version for a new developer to
install.

## Supported platforms

| Platform | Development support | Notes |
| --- | --- | --- |
| Android | Windows, macOS, or Linux | Startup video and haptics enabled |
| iOS/iPadOS | macOS with Xcode | Startup video and haptics enabled |
| Web | Windows, macOS, or Linux | Startup video intentionally skipped |

There is no standalone Windows, macOS, or Linux desktop target in this repository.
Desktop users should run the responsive web version.

## Project structure

```text
assets/videos/             Light and dark startup videos
docs/architecture.md       Architecture and future data-boundary guidance
lib/
  main.dart                App initialization and root theme setup
  firebase_options.dart    FlutterFire client configuration
  models/                  Firestore-facing domain models
  routing/                 Authentication and onboarding gate
  screens/
    auth/                  Login, signup, and password reset
    onboarding/            Four-step onboarding flow
    startup/               Native startup video
    home/                  Current authenticated placeholder
  services/                Firebase, platform, profile, and theme services
  theme/                   Design tokens and motion
  widgets/                 Shared form and button components
android/                   Android platform project
ios/                       iOS/iPadOS platform project
web/                       Flutter web shell and PWA assets
firestore.rules            Firestore authorization policy
firestore.indexes.json     Firestore index configuration
firebase.json              Firebase CLI project configuration
```

For architectural boundaries and the recommended future feature-module layout,
read [docs/architecture.md](docs/architecture.md).

## Prerequisites

Install the following before cloning the project:

1. Git
2. Flutter `3.47.4` stable, with Flutter available on your `PATH`
3. Android Studio or Visual Studio Code
4. For Android: Android Studio, Android SDK, Java 17, and an emulator or USB
   debugging-enabled device. Android Studio's bundled JDK is suitable.
5. For web: Google Chrome or another Flutter-supported browser.
6. For iOS/iPadOS: a Mac, current Xcode command-line tools, and CocoaPods if
   required by the installed Flutter/Xcode toolchain.
7. Optional for managing Firebase: Node.js, Firebase CLI, and FlutterFire CLI.

Confirm the environment:

```shell
flutter --version
flutter doctor -v
```

Resolve every relevant `flutter doctor` error before continuing. iOS builds cannot
be produced locally from Windows or Linux.

## First-time setup

Clone the repository and install packages:

```shell
git clone <repository-url>
cd resq
flutter pub get
```

Verify the checkout:

```shell
flutter analyze
flutter test
```

Both commands should complete without errors.

### Use the existing Firebase development project

The repository includes the public client configuration for the existing Firebase
project:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

These files contain public project identifiers and are safe to commit. They do not
grant administrative access. Never commit a Firebase Admin SDK service-account
JSON file, private key, signing key, `.env` file, or provisioning profile.

Private local files can be backed up to Git only after encrypting them with the
project's age recipient. See [note.md](note.md) for the recipient, corrected
PowerShell helpers, restore instructions, and the list of files that should or
should not be encrypted. Commit `.env.age`, never `.env`, and never commit the age
private identity.

A collaborator needs Firebase console access only to inspect configuration, deploy
rules, or manage Authentication. Running the app does not require console access.

### Connect a different Firebase project

Only follow this section when intentionally replacing the existing project.

1. Create a Firebase project on the free Spark plan.
2. Register an Android app using package `com.vaibhav.resq`.
3. Register an iOS app using bundle ID `com.vaibhav.resq`.
4. Register a web app.
5. Enable Email/Password, Google, and Anonymous Authentication.
6. Create a Firestore database.
7. Install and authenticate the tools:

   ```shell
   npm install --global firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```

8. Regenerate configuration:

   ```shell
   flutterfire configure
   ```

9. Confirm the project/app IDs match across all platform configuration files.

Do not commit any service-account key downloaded from Firebase or Google Cloud.

## Google sign-in setup

### Android

Google sign-in validates the package name and signing-certificate fingerprint.
Every developer or CI signing key that should use Google sign-in must have its
SHA-1 and SHA-256 registered under the Android app in Firebase Project settings.

Generate fingerprints on Windows PowerShell:

```powershell
cd android
.\gradlew signingReport
cd ..
```

On macOS/Linux:

```shell
cd android
./gradlew signingReport
cd ..
```

Add the fingerprints in Firebase, download the refreshed `google-services.json`,
and place it at `android/app/google-services.json`. Do not leave an extra copy at
the repository root.

### iOS

The Firebase-generated file belongs at
`ios/Runner/GoogleService-Info.plist`. It must be included in the Runner target's
Copy Bundle Resources phase. Its `REVERSED_CLIENT_ID` must also appear in
`CFBundleURLTypes` inside `ios/Runner/Info.plist`. Both are already configured in
this repository.

## Run the app

List available devices:

```shell
flutter devices
```

Run on the selected device:

```shell
flutter run
```

Common explicit targets:

```shell
flutter run -d chrome
flutter run -d <android-device-id>
flutter run -d <ios-device-id>
```

Expected signed-out flow:

```text
Android/iOS startup video → Login → Signup/Reset/Emergency access
Web                         → Login → Signup/Reset/Emergency access
Registered user            → Resumable onboarding → Home
Anonymous guest            → Home directly
```

## Firestore

Private onboarding data is stored in `users/{firebaseAuthUid}`. The checked-in
rules enforce owner-only access, prevent profile listing, reject unknown top-level
fields, deny anonymous profile access, and deny every future collection until
feature-specific rules are added.

Validate the rules with the local emulator:

```shell
npm install
npm run test:rules
```

Deploy rules and indexes:

```shell
firebase deploy --only firestore:rules,firestore:indexes
```

Deployment requires Firebase project access but does not require leaving the free
Spark plan.

## Build artifacts

```shell
# Web
flutter build web --release

# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS unsigned build—macOS only
flutter build ios --release --no-codesign
```

Without a release keystore, Android falls back to debug signing for local,
non-store release-mode builds. App Store/TestFlight and Play Store distribution
require developer accounts and signing setup; neither is required for development
or direct Android testing.

## GitHub Actions

`.github/workflows/build-release.yml` runs analysis/tests and builds Android and
iOS artifacts. Run it manually or push a semantic version tag such as `v1.0.0`.

Without signing secrets, Android produces a release-mode APK signed with the debug
key and iOS produces an unsigned IPA. Never commit signing material; use GitHub
Actions secrets if store distribution is added later.

## Free-tier policy

ResQ is free-tier first. Its default development setup must not require a credit
card.

- Keep Firebase usage compatible with the Spark plan and its quotas.
- Do not introduce Cloud Functions, paid Google Maps APIs, paid AI services, or a
  billing-enabled backend without explicit approval and a free-alternative review.
- The mini-map uses OpenStreetMap without an API key. Use public tiles responsibly;
  a large deployment would need an appropriate free tile provider or self-hosting.
- Emergency-critical behavior must degrade safely if a network service or free
  quota is unavailable.

## Troubleshooting

### Packages or generated plugin files are stale

```shell
flutter clean
flutter pub get
flutter analyze
```

### Android Google sign-in reports a configuration error

- Confirm the running build's SHA-1 and SHA-256 are registered in Firebase.
- Confirm the package is exactly `com.vaibhav.resq`.
- Download a new `google-services.json` after adding fingerprints.
- Uninstall the old app from the test device and rebuild it.

### Google sign-in does not return to the iOS app

- Confirm `GoogleService-Info.plist` belongs to `com.vaibhav.resq`.
- Confirm it is included in the Runner target.
- Confirm its `REVERSED_CLIENT_ID` matches the URL scheme in `Info.plist`.

### Firestore returns `permission-denied`

- Confirm the user is signed in with a non-anonymous account.
- Confirm the path is `users/{currentUser.uid}`.
- Deploy the checked-in rules to the active Firebase project.

### Native behavior is absent on web

This is expected for the startup video and haptics. Web intentionally skips the
native startup video, and browsers do not expose the same haptic behavior.

## Before opening a pull request

Run:

```shell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
npm run test:rules
```

For Android-affecting changes, also run:

```shell
flutter build apk --debug
```

Never commit `build/`, `.dart_tool/`, IDE state, Firebase emulator output, signing
files, service-account credentials, or environment files. `.gitignore` covers these
categories.

## Contributing

Keep changes scoped and testable. New features should follow the feature-module
direction in [docs/architecture.md](docs/architecture.md), preserve Emergency
access, remain responsive across phone and wide layouts, and include
collection-specific Firestore rules before adding new data paths.
