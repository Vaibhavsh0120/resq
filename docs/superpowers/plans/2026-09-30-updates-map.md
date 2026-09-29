# Updates Map Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show nearby verified alerts and recent India-impacting disaster events on distinct, map-backed Updates views for v1.0.0.

**Architecture:** The existing GitHub Actions feed job caches bounded GDACS GeoJSON event projections in Firestore and purges out-of-window records. Vercel exposes the India projection and nearby home coverage coordinates. Flutter reads each feed independently and displays either a home-area coverage marker or published event points with matching cards.

**Tech Stack:** FastAPI, Firebase Admin/Firestore, GitHub Actions, Flutter/Riverpod, `flutter_map` 8, Firebase Hosting, Vercel Hobby.

**Spec:** `docs/superpowers/specs/2026-09-30-updates-map-design.md`

## Global Constraints

- Work only on `main`; use no card, paid plan, or new API key.
- Nearby matches the saved home district/state using the existing `/v1/alerts/nearby` endpoint. The home map point is coverage, never an incident location.
- Across India uses GDACS event points, source URLs, visible GDACS attribution, and a seven-day window after published `todate`.
- Keep source failures separate, cap reads/writes/markers, purge irrelevant data even after a failed refresh, and keep cards usable without map tiles.
- Preserve English and Hindi localization, the existing ResQ theme, and visible OpenStreetMap attribution.

## Review Focus

- `todate` is absent, malformed, future-skewed, or timezone-free: reject invalid events or interpret the documented UTC value consistently; never retain indefinitely.
- `affectedcountries` contains India while the point is offshore: include it with an India-impacting label, without claiming the point is on land.
- Duplicate episodes of one GDACS event: use stable event/episode identity so refreshes update rather than multiply markers.
- A saved home has a district/state but missing or invalid coordinates: keep nearby cards and show a map placeholder, with no fabricated marker.
- A feed fails while the other works: show the working feed normally and mark the failed feed stale, removing events past relevance.

---

### Task 1: Cache bounded GDACS events and purge stale records

**Files:**
- Create: `backend/app/integrations/india_events.py` — pure GeoJSON normalization, bounded ingestion, relevance purge.
- Modify: `backend/scripts/ingest_alerts.py` — call GDACS refresh after NDMA/IMD, record failures without aborting local alert ingestion.
- Modify: `backend/scripts/monitor_health.py` — surface stale GDACS status as a monitored best-effort feed.
- Test: `backend/tests/test_india_events.py` — parser, caps, stable IDs, failure retention, purge.

**Interfaces:**
- Produce `parse_gdacs_feature(feature: dict, now: datetime) -> dict | None`, normalized `id`, `title`, `eventType`, `latitude`, `longitude`, `sourceUrl`, `countryLabel`, `startedAt`, `endedAt`, `updatedAt`, `relevanceEndsAt`, and `alertLevel`.
- Produce `async ingest_gdacs(database, *, now: datetime | None = None) -> int` and `purge_old_india_events(database, *, now: datetime | None = None) -> int`; use `indiaEvents` and `ingestionState/gdacs`.

- [ ] Write focused failing tests for India/affected-country filtering, coordinates, missing/naive dates, offshore points, stable event-plus-episode IDs, a 100-feature processing cap, a failed fetch retaining still-relevant records, and seven-day purge.
- [ ] Run `python -m pytest tests/test_india_events.py -q` from `backend`; confirm the new tests fail for the missing implementation.
- [ ] Implement `india_events.py` using the documented GDACS `SEARCH` endpoint, a recent date window, HTTPS GDACS report links only, fixed timeout, and bounded Firestore operations. Record last check/success/error/truncation. Purge outside-window events in a `finally` path.
- [ ] Wire the existing job and monitor; a GDACS error must not undo or hide NDMA/IMD results. Run the focused tests to pass.
- [ ] Commit the backend ingestion and tests on `main`.

### Task 2: Expose independent feed contracts

**Files:**
- Modify: `backend/app/api/routes/alerts.py` — add `GET /v1/alerts/india`; include `homeCenter` in nearby response when coordinates are valid.
- Test: `backend/tests/test_alert_routes.py` — nearby coverage and India projection endpoints.

**Interfaces:**
- Consume normalized `indiaEvents` fields from Task 1.
- Produce `{items: [...], sourceHealth: {...}}` from `/v1/alerts/india`; only records with `relevanceEndsAt > now`, capped and ordered by `updatedAt` descending.
- Extend `/v1/alerts/nearby` with nullable `homeCenter: {latitude, longitude}` for this authenticated user; never log it or return other profile fields.

- [ ] Write failing tests for capped/ordered India events, expired filtering, GDACS health, anonymous Firebase user access, missing home coordinates, and invalid home coordinates.
- [ ] Run `python -m pytest tests/test_alert_routes.py -q`; confirm failure, then implement the two route changes and pass the focused tests.
- [ ] Run `python -m pytest -q` from `backend`; commit endpoint and tests on `main`.

### Task 3: Build the Updates map and cards

**Files:**
- Create: `frontend/lib/features/updates/domain/india_event.dart` — validated event model.
- Create: `frontend/lib/features/updates/data/india_events_repository.dart` and `application/india_events_providers.dart` — independent `/v1/alerts/india` load.
- Create: `frontend/lib/features/updates/presentation/updates_map.dart` — shared map, distinct marker presentation and selection.
- Modify: `frontend/lib/features/updates/data/alerts_repository.dart` — parse nullable `homeCenter`.
- Modify: `frontend/lib/features/updates/presentation/updates_screen.dart` — segmented Nearby/Across India views, independent states, cards, source links.
- Modify: `frontend/lib/l10n/app_en.arb`, `app_hi.arb` — new map labels and honest empty/stale copy; regenerate localization.
- Test: `frontend/test/screens/updates_screen_test.dart` — view switching, marker/card pairing, coverage wording, no-coordinate and independent-failure states.

**Interfaces:**
- Consume Task 2 `homeCenter` and India feed response.
- Produce two selectable views with a home-area coverage marker on Nearby and published GDACS points on Across India; `OsmMapAttribution` always remains visible.

- [ ] Write focused failing widget/model tests for switching, relevant map/card count, no fabricated local incident point, missing home coordinates, India empty state, and one feed failing while the other still renders.
- [ ] Run `flutter test test/screens/updates_screen_test.dart`; confirm the new tests fail.
- [ ] Implement model/repository/provider first, then map and screen. Use `MapController` only after map readiness; constrain heights for phone and desktop, keep cards and keyboard-readable labels. Reuse the existing ResQ theme and OSM widget.
- [ ] Run `flutter gen-l10n`, `dart format` on edited Dart files, focused tests, `flutter analyze --fatal-infos`, and `flutter test --reporter compact`; fix failures and commit on `main`.

### Task 4: Deploy and prove the v1.0.0 release

**Files:**
- Modify: `README.md`, `RELEASE.md` — explain the two sources, map semantics, retention, URLs, no-card limits, and operator checks.
- Modify: `.github/workflows/operations.yml` only if the existing official-alerts job needs a timeout or invocation change.

**Interfaces:**
- Use existing Firebase project `resq-106ed`, Vercel project `resq-api`, and approved GitHub Actions secrets. No new secret is required.

- [ ] Update docs; run backend, rules, Flutter analysis/tests, production web build, and `git diff --check`. Commit and push `main`.
- [ ] Run the official-alerts workflow once; confirm `ingestionState/gdacs` is fresh, irrelevant records purge, and `/v1/alerts/india` returns real bounded event points. Check `/v1/alerts/nearby` still matches a registered home region.
- [ ] Deploy the FastAPI change to Vercel Hobby and Flutter web to Firebase Hosting. Check live Nearby and Across India at phone and desktop widths, marker/card behavior, source links, timestamps, localization, OSM attribution, and empty/error states.
- [ ] Move the user-approved `v1.0.0` tag to the final verified `main` commit; wait for tag CI, then replace stale GitHub Release assets with artifacts from that exact SHA and update its notes. Verify artifact checksums and release links.

