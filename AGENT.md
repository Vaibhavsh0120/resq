# AGENT.md — resq

## Project Overview
Flutter app (`resq`), package `com.vaibhav.resq`. Very new project: `lib/main.dart` is still
the stock `flutter create` counter template — no real app screens/features implemented yet.
Firebase (`firebase_core`) is wired into the project (Android `google-services.json`,
`lib/firebase_options.dart` for all platforms) but **not yet initialized/used** in `main.dart`
(no `Firebase.initializeApp()` call).

Targets: Android, iOS, Web (Windows/macOS/Linux scaffolding not present — no `windows/`,
`macos/`, `linux/` dirs).

Uses very recent/pre-release-track tooling: Dart SDK `^3.13.3`, AGP `9.1.0`, Kotlin `2.4.0`,
Gradle `9.3.1` (see `android/settings.gradle.kts`, `android/gradle/wrapper/gradle-wrapper.properties`).
CI pins Flutter `3.47.4` (stable channel), which ships a matching Dart SDK — bump this pin
periodically as Flutter releases new stable versions.

**Explicit user decision:** no Play Store / App Store distribution, no real code signing
wanted. GitHub Actions release artifacts must be in **release mode** (not debug) — release mode
avoids the debug banner/overlay and performance warnings that show in the app UI in debug
builds — but stay debug-signed (Android) / unsigned (iOS) since they're only for
direct install/sideloading, not store upload.

## Repository Structure
```
lib/main.dart              - stock counter template (not yet the real app)
lib/firebase_options.dart  - FlutterFire-generated, all platforms
android/                   - standard Flutter Android project (Kotlin DSL gradle files)
  app/google-services.json - present, Firebase Android config
  app/build.gradle.kts     - release signing config reads android/key.properties if present
                             (optional, unused by default — see Important Decisions),
                             else falls back to debug signing
ios/                       - standard Flutter iOS project, CODE_SIGN_STYLE = Automatic,
                             no GoogleService-Info.plist committed (not required — app uses
                             DefaultFirebaseOptions.currentPlatform instead)
web/                       - standard Flutter web scaffold
firebase.json              - FlutterFire CLI config (android + dart + web configured)
.github/workflows/
  build-release.yml        - release APK/AAB/IPA build + GitHub Release publish workflow
test/widget_test.dart      - stock counter smoke test
```

## Architecture
No app architecture yet beyond the Flutter template — nothing to document here until real
screens/features are added.

## Development Commands
- `flutter pub get` — install dependencies
- `flutter analyze` — static analysis (uses `flutter_lints` via `analysis_options.yaml`)
- `flutter test` — run tests (currently just the stock widget smoke test)
- `flutter run` — run locally (see Known Gaps for the web `flutter_web_plugins` issue)
- `flutter build apk --release` / `flutter build appbundle --release` — Android release build
- `flutter build ios --release --no-codesign` — unsigned iOS release build (building requires
  macOS; CI handles this via the `macos-26` runner)

## TODO
- [x] Diagnose the user's local `flutter run` web failure (`Couldn't resolve the package
      'flutter_web_plugins'`) — local-environment issue, not a repo bug, no code change made.
- [x] Fix the existing GitHub Actions workflow (`build-release.yml`) so Android builds in
      **release** mode instead of `--debug` (this was the reported bug), and add an AAB build.
- [x] Confirmed with user: no store distribution, no real signing wanted — release-mode,
      debug-signed APK/AAB and unsigned IPA is the intended final state. Optional signing
      support left in place (unused) behind secrets, in case that changes later.
- [ ] Nothing currently pending.

## Completed Work
**Fixed `.github/workflows/build-release.yml`** (this workflow already existed in the repo but
built Android in debug mode — that was the bug reported):
- Triggers: push of a `v*.*.*` tag, or manual `workflow_dispatch` (both existed/added).
- `build-android` job (ubuntu-latest): `flutter analyze` + `flutter test`, then
  `flutter build apk --release` (was `--debug`) and `flutter build appbundle --release` (new).
  Uploads both as workflow artifacts and stages them for the release job.
- `build-ios` job (`macos-26`): `flutter test`, then `flutter build ios --release --no-codesign`
  + manual `Payload/` zip → unsigned release `.ipa`. This was already release-mode in the
  original workflow, left as-is functionally, just cleaned up.
- `publish-release` job: downloads all artifacts and runs `gh release create` (unchanged
  approach from the original workflow), now including the AAB too.
- Optional real signing paths exist for both platforms (gated behind secrets that are **not**
  set) — dormant by design per the user's explicit "don't want to sign" decision. See Known
  Gaps for the secret names if this is ever revisited.

**Android build.gradle.kts**: added an optional `android/key.properties`-based release signing
config that's inert unless that file exists (it doesn't, and isn't created by the workflow
since signing secrets aren't configured) — release build type currently still signs with the
`debug` config, matching the pre-existing behavior and the user's preference.

## Known Gaps
- **`lib/main.dart` is still the Flutter counter template.** No real app has been built yet.
- **Local `flutter run -d chrome` failure** (`Error: Couldn't resolve the package
  'flutter_web_plugins'` in `web_plugin_registrant.dart`): **local dev-machine environment
  issue**, not a bug in this repository — that file is generated by the Flutter tool at build
  time (not present in the repo), and this error class is consistently caused by a
  stale/corrupted `.dart_tool` build cache or a Flutter SDK out of sync with the pub cache. Fix
  (on the affected Windows machine, not in this repo):
  ```
  flutter clean
  del pubspec.lock        (or: rm pubspec.lock)
  flutter pub get
  flutter doctor -v       (confirm no red flags, especially for the web/Chrome toolchain)
  flutter run -d chrome
  ```
  If it persists, also try `flutter upgrade` — the project's `sdk: ^3.13.3` constraint requires
  a very current Flutter stable install.
- **No `ios/Runner/GoogleService-Info.plist`.** Not currently a build blocker since the app
  uses `DefaultFirebaseOptions.currentPlatform` rather than the plist, and `main.dart` doesn't
  call `Firebase.initializeApp()` yet anyway.
- **Release artifacts are not signed for store distribution** — this is intentional per the
  user's explicit request, not a gap to fix. APK/AAB are debug-signed (installable directly on
  a device, not Play-Store-uploadable); the IPA is unsigned (installable via
  sideloading/AltStore-style tools, not TestFlight/App-Store-uploadable). If this changes later,
  add the secrets documented inline in `build-release.yml`:
  Android — `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
  `ANDROID_KEY_PASSWORD`; iOS — `IOS_BUILD_CERTIFICATE_BASE64`, `IOS_BUILD_CERTIFICATE_PASSWORD`,
  `IOS_MOBILE_PROVISIONING_PROFILE_BASE64`, `IOS_KEYCHAIN_PASSWORD`, `IOS_EXPORT_TEAM_ID`.

## Resume Here
No pending in-progress work on CI/build tooling. Next natural step for the project overall is
starting the actual app (`lib/main.dart` is still the template) — no architecture decisions
have been made yet for real screens/state management/navigation.

## Important Decisions
- **No code signing, no store distribution** (explicit user decision) — release artifacts are
  release-*mode* (optimized, no debug banner/overlay) but not release-*signed*. Kept the
  optional signing code paths in the workflow (dormant, gated behind unset secrets) rather than
  deleting them, since they're harmless when unused and save rework if this decision changes.
- Kept the pre-existing workflow filename/structure (`build-release.yml`, `gh release create`
  style) and fixed the actual bug (`--debug` → `--release`, missing AAB) rather than replacing
  it with a differently-structured workflow — smaller, more reviewable diff.
- Made Android release signing support a **permanent, idiomatic part of
  `build.gradle.kts`** (reads `key.properties`, falls back to debug) rather than having CI
  patch the Gradle file at build time — standard Flutter community pattern, works identically
  for local builds and CI. Currently unused (no `key.properties` present).
- Did not touch `lib/main.dart`, app architecture, or Firebase initialization — out of scope for
  this session's request (CI/build tooling only).

## Verified Findings
- No Flutter/Dart SDK is available in the sandbox used to prepare this change (network access
  is also disabled), so the workflow and Gradle changes were verified by careful manual
  inspection and cross-referencing current Flutter/GitHub Actions docs — **not** by actually
  running `flutter build`/`flutter test` end-to-end. Recommend running the workflow once
  (`workflow_dispatch`) after pushing to confirm end-to-end.
- Confirmed via `.gitignore` and `android/.gitignore` that `key.properties`, `*.jks`,
  `*.keystore`, `*.p12`, `*.mobileprovision` are already excluded from version control.
- `actions/checkout@v5`, `actions/upload-artifact@v5`, `actions/download-artifact@v5`, and the
  `macos-26` GitHub-hosted runner label are current/real as of this session (verified via web
  search) — not stale references, despite being newer than versions commonly seen in older
  documentation.
- Latest Flutter stable as of this session is ~3.47.1–3.47.4, shipping Dart ~3.13.x, consistent
  with this project's `sdk: ^3.13.3` pubspec constraint.
