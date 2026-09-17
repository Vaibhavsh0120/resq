# AGENT.md — resq

## Project Overview
Flutter app, package `com.vaibhav.resq`. **Display name is "ResQ"** (Android launcher label,
iOS CFBundleDisplayName/CFBundleName, web page title/PWA manifest, README) — see Important
Decisions for what intentionally stayed lowercase `resq`/`com.vaibhav.resq` (Dart package name,
Android applicationId/namespace, iOS bundle identifier, Firebase project ID) and why. Very new
project: `lib/main.dart` is still the stock `flutter create` counter template — no real app
screens/features implemented yet.
Firebase (`firebase_core`) is wired into the project (Android `google-services.json`,
`lib/firebase_options.dart` for all platforms) but **not yet initialized/used** in `main.dart`
(no `Firebase.initializeApp()` call).

Targets: Android, iOS, Web (Windows/macOS/Linux scaffolding not present — no `windows/`,
`macos/`, `linux/` dirs).

App icon: light/dark-aware on iOS 18+ and web favicon; static (light) on Android and iOS <18,
see Important Decisions for why and Completed Work for what was generated.

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
  app/src/main/res/mipmap-anydpi-v26/ - adaptive icon XML (ic_launcher.xml / _round.xml),
                             references ic_launcher_foreground/_background per density
ios/                       - standard Flutter iOS project, CODE_SIGN_STYLE = Automatic,
                             no GoogleService-Info.plist committed (not required — app uses
                             DefaultFirebaseOptions.currentPlatform instead)
  Runner/Assets.xcassets/AppIcon.appiconset/ - Contents.json declares light/dark/tinted
                             1024 variants (ios-marketing idiom, Xcode 16+ "appearances" key)
                             alongside the full legacy per-size iphone/ipad set
web/                       - standard Flutter web scaffold
  favicon.png / favicon-dark.png - swapped via `prefers-color-scheme` media query in index.html
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
- [x] App icon: user supplied `icon/icon.png` (light) + `icon/icon-dark.png` (dark), both
      1024x1024 opaque. Generated full native icon sets for Android/iOS/Web from these two
      source files, wired up automatic light/dark switching where each platform actually
      supports it, then deleted `icon/` per user request (all derived assets are committed in
      their native platform locations, nothing depends on the source folder at build time).
- [x] Renamed the display name from "resq"/"Resq" to "ResQ" everywhere it's shown to a user:
      Android launcher label, iOS CFBundleDisplayName + CFBundleName, web `<title>` +
      apple-mobile-web-app-title + PWA manifest name/short_name, README heading. Confirmed with
      user and left untouched (technical identifiers, not display names — renaming these would
      make it a different app to Firebase/stores, not a rename): Dart package name (`pubspec.yaml`
      `name: resq`, required lowercase by pub), Android `applicationId`/`namespace`
      `com.vaibhav.resq`, iOS `PRODUCT_BUNDLE_IDENTIFIER` `com.vaibhav.resq`, Firebase project ID
      `resq-106ed` and everything generated from it (`google-services.json`, `firebase_options.dart`,
      `firebase.json`). Release workflow (`build-release.yml`) already used "ResQ" in artifact
      filenames/release notes before this change — untouched, already correct.
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

**App icon (light/dark), generated from user-supplied `icon/icon.png` + `icon/icon-dark.png`**
(1024x1024, opaque RGB, glyph bbox 195,219–828,804 on both — used this to auto-extract a
transparent-background glyph layer for Android/web maskable work, no manual asset editing).
- **iOS**: `AppIcon.appiconset/Contents.json` rewritten to Xcode-16 format — full legacy
  per-size `iphone`/`ipad` idiom set regenerated from the light icon (unaffected by
  appearance, needed since `IPHONEOS_DEPLOYMENT_TARGET = 15.0`), plus three `ios-marketing`
  1024 entries: default (light, opaque), `appearances: [luminosity: dark]` (opaque, edge-to-
  edge per Apple spec — no padding, iOS applies its own corner mask), `appearances:
  [luminosity: tinted]` (grayscale glyph, transparent bg, system composites its own dark
  gradient + tint). **Fully automatic on iOS 18+, silently ignored pre-18** (device just shows
  the light default) — no runtime code involved, this is asset-catalog-only.
- **Android**: no OS-level light/dark launcher-icon mechanism exists (confirmed via research —
  this is a hard platform limitation, not a gap in this implementation). Two things done:
  (1) regenerated legacy flat `ic_launcher.png` at all 5 densities from the light icon: (2)
  added proper **adaptive icons** (`mipmap-anydpi-v26/ic_launcher.xml` + `_round.xml`,
  referencing per-density `ic_launcher_foreground`/`_background` PNGs) since the project had
  none before — foreground is the glyph alone on transparent bg, scaled to ~62% of canvas
  (within Android's 66% safe zone, some margin kept against launcher-mask clipping), background
  is solid white. This is the current Android-recommended icon format regardless of the
  light/dark question, and gives proper masking across launchers (circle/squircle/rounded-
  square) instead of a square icon with baked-in corners.
- **Web**: PWA `manifest.json` icons (192/512 + maskable 192/512, safe-zone-padded) regenerated
  from the light icon — the manifest spec has no dark-icon field. Browser-tab favicon *does*
  support light/dark switching: added `favicon-dark.png` alongside the existing `favicon.png`,
  wired via two `<link rel="icon" media="(prefers-color-scheme: ...)">` tags in
  `web/index.html` (plus an unconditional light fallback link for browsers that don't support
  the media query). `apple-touch-icon` (iOS "Add to Home Screen") intentionally left pointing
  at the light icon only — researched and confirmed iOS Safari does not reliably honor
  `prefers-color-scheme` for that specific icon even when it does for other PWA surfaces.
- Source folder `icon/` deleted per user request after confirming every generated asset lives
  in its native platform location and nothing references the `icon/` path anymore (verified via
  repo-wide grep before deletion).

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

- **No dynamic app icon on Android or iOS <18** — this is a hard platform limitation (verified
  via research), not an implementation gap. Android has no OS-level light/dark launcher-icon
  mechanism at all; iOS only gained per-appearance icons in iOS 18 (Xcode 16 asset-catalog
  feature). Nothing to fix here unless Apple/Google add new platform capability later.
- **iOS PWA "Add to Home Screen" icon stays light-only** even though the browser-tab favicon
  correctly switches with system theme — confirmed via research that iOS Safari doesn't
  reliably honor `prefers-color-scheme` for that specific icon surface. Not fixable from web
  code; would need Apple to change Safari behavior.
- **Icon assets not regenerated via `flutter_launcher_icons`** — no Flutter SDK/pub.dev access
  in the sandbox that did this work, so all native icon files were generated directly with
  Pillow at the correct sizes/paths instead. Functionally equivalent output, but if the source
  art changes again, regenerate manually at the documented sizes (see Completed Work) or run
  `flutter_launcher_icons` locally if preferred going forward.

## Resume Here
No pending in-progress work on CI/build tooling or the app icon. Next natural step for the
project overall is starting the actual app (`lib/main.dart` is still the template) — no
architecture decisions have been made yet for real screens/state management/navigation.

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
- **App icon light/dark switching is a platform-level Xcode-16/iOS-18 asset feature, not
  something implemented in Dart** — there's no runtime "detect theme, set icon" code, and none
  is possible for Android or pre-18 iOS (verified via research, not a gap to revisit). Do not
  attempt to add Dart/platform-channel code to swap the launcher icon at runtime — the correct
  fix if this needs to change is always in the platform asset catalogs/XML, not `lib/`.
  Documented this Findings/Gaps split (see Known Gaps) so it isn't mistaken for missed work
  later.
- Used Pillow (no Flutter SDK/`flutter_launcher_icons` available in the sandbox — no
  network access to pub.dev either) to generate every native icon size directly from the two
  source PNGs, rather than deferring to a package the user would have to run locally. If the
  user ever replaces the source art, regenerate by hand at the same sizes/paths documented
  above (or set up `flutter_launcher_icons` locally, which was not available here).
- **Display name "ResQ" vs. technical identifiers left lowercase** — user initially asked to
  rename the project to "ResQ" everywhere including package/bundle IDs, then confirmed (after
  being walked through the consequence) that IDs should stay exactly `com.vaibhav.resq` /
  `resq-106ed` unchanged, since changing them would deregister the app from its existing
  Firebase project and make it a new app to Play Store/App Store rather than a rename. Net
  effect: only user-visible display strings changed to "ResQ"; every technical identifier
  (Dart package name, Android applicationId/namespace, iOS bundle identifier, Firebase project
  ID and all Firebase-generated config) is untouched. If a real ID change is wanted later, it
  needs a new Firebase app registration (FlutterFire CLI) under the new ID — this was not done.

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
- Confirmed (multiple independent sources, including a real production Contents.json diff and
  an Apple-forum-documented failure mode) that iOS 18 dark/tinted app icon support: (1) requires
  Xcode 16+ to build/archive, (2) is asset-catalog-only — `appearances: [{luminosity: dark}]`
  on an `ios-marketing`/`universal` 1024 image entry, no code; (3) dark/light images must stay
  edge-to-edge opaque, NOT padded/inset — iOS applies its own corner mask on top, so a padded
  canvas produces visible corner wedges instead of a clean masked icon; (4) tinted should be a
  transparent-background grayscale glyph (system supplies its own dark gradient backdrop + the
  user's chosen tint color). Legacy per-size `iphone`/`ipad` idiom entries are unaffected by
  appearance and continue serving iOS <18 exactly as before.
- Confirmed Android has no OS-level equivalent — no resource qualifier, no manifest flag, no
  adaptive-icon appearance slot for light/dark. The project's pre-existing `values-night/`
  folder is unrelated (Flutter's splash-screen `LaunchTheme`, not the launcher icon).
