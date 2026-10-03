# ResQ

ResQ is a cross-platform personal safety companion built with Flutter and
Firebase. Its long-term goal is to help people prepare for emergencies, receive
trusted guidance, contact help, coordinate with family, report hazards, and find
nearby safe places from one application.

> ResQ is a best-effort hackathon pilot. It is not a replacement for local
> emergency services, professional medical advice, or official government alerts.

## Current milestone

This repository now contains a connected Flutter safety-app foundation and a
FastAPI service:

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
- Adaptive Home, Updates, Report, Family, and Places navigation
- SOS countdown, `112` calling, location-aware event records, Circle fan-out, and SMS fallback
- Readiness checklist, verified alert feed, private reports, and nearby safe places
- Household Circle creation, invitations, emergency check-ins, and consent-aware location UI
- Durable notification inbox; optional FCM registration on configured mobile devices
- Provider-neutral assistant API with streaming text and device speech input/output

The [web pilot](https://resq-106ed.web.app/) runs on Firebase Hosting with a
[Vercel FastAPI backend](https://resq-api.vercel.app/v1/health) and Gemini assistant.
The release is a public,
best-effort safety companion. Digital SOS and alerts can be delayed or unavailable;
the app keeps the 112 call and manual SMS available. Report photos are private,
unavailable at 30 days, and deleted through operator-triggered maintenance.

Updates has two views: **Nearby** shows official alerts affecting your saved
home district/state and marks coverage at home; **Across India** shows disaster
events from the Global Disaster Awareness and Coordination System (GDACS) at
published coordinates. Both have matching cards, source links, and freshness
labels. GDACS events disappear seven days after their published end date.
Opening Updates refreshes cached feeds when due, at most once per 30 minutes
globally, with bounded requests and a five-minute failure backoff.
The web pilot uses the notification inbox only, as requested; Web Push is not
configured. iOS push needs APNs credentials and signing outside this no-card pilot.

The connected milestone also includes persisted assistant history, consent-filtered
retrieval, moderated reports and places, official NDMA/IMD ingestion, emergency
check-in jobs, account deletion, and an admin console. See the
[production release guide](RELEASE.md) for exact configuration, testing, deployment,
monitoring, and rollback steps. See the [data notice](PRIVACY.md) for retention
and account deletion details.

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
frontend/                  Flutter application and Firebase client project
  assets/videos/           Light and dark startup videos
  docs/architecture.md     Architecture and future data-boundary guidance
  lib/                     Application source
  test/                    Flutter and Firestore rules tests
  android/                 Android platform project
  ios/                     iOS/iPadOS platform project
  web/                     Flutter web shell and PWA assets
  firestore.rules          Firestore authorization policy
  firestore.indexes.json   Firestore index configuration
  firebase.json            Firebase CLI project configuration
backend/                   FastAPI service workspace
```

For architectural boundaries and the recommended future feature-module layout,
read [frontend/docs/architecture.md](frontend/docs/architecture.md).

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
cd resq/frontend
flutter pub get
```

Verify the checkout:

```shell
flutter analyze
flutter test
```

Both commands should complete without errors.

### Push-notification development

Android notification permission, the web messaging service worker, and the iOS
Push Notifications/Background Modes entitlements are included.
For web push, create a Web Push certificate in Firebase and pass its public VAPID
key at build or run time:

```shell
flutter run -d chrome --dart-define=RESQ_FCM_VAPID_KEY=<public-vapid-key>
```

The app registers device tokens only after a registered user explicitly enables
push alerts. Before distributing iOS builds, create an APNs authentication key in
the Apple Developer portal, upload it in Firebase Console under Project settings
→ Cloud Messaging, and use a provisioning profile for `com.vaibhav.resq` that
contains the Push Notifications entitlement. Validate this on a physical device;
the Windows development environment cannot produce or sign an iOS build.

The hosted web pilot can serve invitations at
`https://resq-106ed.web.app/invite/:token`. Native invitation and notification
app links still use `https://resq.app`; before distributing mobile builds,
serve an Apple App Site Association file at
`https://resq.app/.well-known/apple-app-site-association` and an Android Digital
Asset Links file at `https://resq.app/.well-known/assetlinks.json`, using the
production Apple Team ID and Android signing-certificate fingerprint. The app
entitlements and intent filters are already configured, but the operating systems
will not trust universal/app links until those two HTTPS files are deployed.

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

### One-command local development on Windows

Install frontend and backend dependencies once:

```powershell
cd frontend
flutter pub get
npm install
cd ..\backend
python -m pip install -e ".[dev]"
cd ..
```

Then start the Firebase Auth/Firestore emulators, FastAPI, and Flutter web app:

```powershell
.\scripts\run-local.ps1 -Target chrome -Seed
```

The app opens at `http://localhost:5000`, FastAPI listens on
`http://localhost:8080`, and the Firebase Emulator UI is at
`http://localhost:4000`. Remove `-Seed` after the first run. For an Android
emulator, use `-Target android`; its configuration uses `10.0.2.2` to reach the
Windows host.

The checked-in frontend files under `frontend/config/` contain public runtime
switches only. Flutter reads them with `--dart-define-from-file`. Release CI
creates the production JSON file from GitHub variables with
`frontend/tool/write_release_config.py`. Do not put server secrets in a Flutter
define because they are embedded in the client bundle.

`backend/.env` is a gitignored local operator file currently configured for
production. Use `backend/.env.example` for emulator settings, while
`backend/.env.production.example` documents deployment variables. In production,
inject the selected AI provider key, Firebase credentials, Cloudinary URL, and
admin key through Vercel encrypted variables; never upload a populated `.env`. Voice uses
device speech recognition and text-to-speech with the same backend text quota.

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

For direct manual local runs, include the matching profile:

```shell
flutter run -d chrome --web-port 5000 --dart-define-from-file=config/local.web.json
flutter run --dart-define-from-file=config/local.android.json
flutter run -d <ios-device-id> --dart-define-from-file=config/local.ios.json
```

### Backend jobs

There are **no scheduled GitHub Actions**. The only workflows are manual release
builds (which also run quality checks) and manual maintenance. In GitHub Actions,
run **ResQ Manual Maintenance** and choose `all`, `feeds`, `safety`, `photos`, or
`health`. Feeds also refresh on demand when Updates is opened. Photo screening,
stored-asset deletion, pending SOS retries, and due check-in reminders require
the operator to run maintenance; they do not run on a timer.

For local operator maintenance, run from `backend/`:

```shell
python scripts/ingest_alerts.py
python scripts/retry_sos.py
python scripts/send_checkin_reminders.py
python scripts/scan_photos.py
python scripts/purge_photos.py
```

The default NDMA SACHET RSS is configured. IMD district IDs are optional and
must be verified from the official source. Report approval is deliberately not an
automatic copy: `POST /v1/admin/reports/{reportId}:approve` requires a reviewed
`public_description` so private text and identifying details are not published.
The admin console requires a registered account with the Firebase `admin`
custom claim. Trusted operator routes can use `X-Admin-Key`.

### Production backend and monitoring

The production FastAPI service is [on Vercel](https://resq-api.vercel.app/v1/health)
and the Flutter web app is [on Firebase Hosting](https://resq-106ed.web.app/).
Follow [RELEASE.md](RELEASE.md) for the service map and operator checks.
Monitor Vercel health, manual maintenance results, the admin source-health view,
Firestore usage, Cloudinary usage, and the free AI allowance. The backend
reports a commit SHA at `GET /v1/health` when the deployment provides one.

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
Spark plan. This repository's `.firebaserc` selects `resq-106ed` by default. If
you intentionally connect a different Firebase project, run `firebase use --add`
and select the appropriate alias before deploying.

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

`.github/workflows/build-release.yml` runs analysis/tests and builds Android,
iOS, and web artifacts. Run it manually against `main` and set a semantic release
label such as `v1.0.0`. Pushing a tag or opening a pull request starts no Actions.
The separate CI workflow was removed because the release workflow includes its
checks. Manual maintenance is kept for production operations.

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
