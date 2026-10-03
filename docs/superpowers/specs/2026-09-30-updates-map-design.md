# Updates map: nearby alerts and India-wide events

## Purpose and boundaries

The Updates page must show two map-backed views for a hackathon-ready v1.0.0 release:

- **Nearby** shows verified, active NDMA/IMD alerts that match the user's saved home district and state. The map point is the saved home location and represents **alert coverage for that home area**, never an incident coordinate.
- **Across India** shows recent disaster and safety events that affect India and have published geographic coordinates. These are situational updates, not warnings that apply to the user's home. Use the free GDACS GeoJSON API, attribute it as “Global Disaster Awareness and Coordination System, GDACS,” and link each item to its GDACS source page.

The app remains on Firebase Spark, Vercel Hobby, GitHub Actions, and the existing OpenStreetMap tile source; this change introduces no paid plan, card requirement, or API key. The existing authenticated Firebase session can be anonymous for the Across India view. The two feeds are visually distinct and must never use invented or inferred incident coordinates.

## Data flow and retention

1. Extend the existing `official-alerts` GitHub Actions job to fetch a bounded, recent GDACS `SEARCH` GeoJSON result. Normalize only India-impacting disaster events with valid Point coordinates, a credible event ID, type, title, source URL, and dates. Accept an event whose `country`/`iso3` is India or whose `affectedcountries` includes `IND`; an offshore event may therefore appear outside India's land boundary. Treat source text as plain text and accept links only on GDACS HTTPS hosts.
2. Store normalized events in a dedicated Firestore collection with stable IDs. Store last check, last success, error status, and truncation in `ingestionState/gdacs`. Cap the fetched and served item counts so a source surge cannot cause unbounded reads, writes, or map markers. Do not overwrite the last good event set on a failed fetch.
3. An event is relevant through seven days after its published `todate` (or equivalent end date). Purge events beyond that window on every request-driven or manual refresh, including when the source fetch fails. Also remove events no longer in the bounded source result when they are outside the current relevance window. Existing nearby alerts continue to expire through `expire_old_alerts`.
4. Add a read-only Vercel endpoint for the India-wide projection and its source health. It returns only capped, relevant records; the existing `/v1/alerts/nearby` endpoint remains the sole authority for local matching. The Flutter client reads the two endpoints independently so one feed's failure does not hide the other.

GDACS says its API data are free, offers GeoJSON event locations, asks for attribution, and caps a response at 100 records. The job uses selective dates and bounded processing. The public OpenStreetMap tiles remain an interactive, attributed, best-effort map; no tile prefetch or bulk download is added.

## Screen behavior

Updates contains a compact **Nearby / Across India** segmented control above one map and one matching list. Nearby is the default. The active segment determines the map camera and cards: saved home coordinates for Nearby, an India overview for Across India. The home-area coverage marker shows a count and an explicit coverage label. GDACS markers use the source's event points. Marker selection reveals the corresponding title, date, and details, and the item remains accessible in the list if map tiles fail or a pointer cannot be used.

Each card gives title, area, source, recency, and a source link where available. Severity styling distinguishes urgent local alerts from informational national events. The source-health text says when data was checked and flags a failed or delayed refresh. Missing saved home location gives a sign-in or profile action for Nearby while Across India remains usable. Empty, loading, stale, and error states say what is known without implying that no danger exists. English and Hindi labels use the existing localization system. At compact and wide widths, map attribution stays visible and the map never blocks scroll or access to cards.

## Verification and rollout

- Focused backend tests cover GDACS filtering, coordinate/date validation, stable IDs, caps, stale-on-error handling, and seven-day purge; API tests cover ordering, bounds, source health, and guest access.
- Flutter tests cover view switching, matching markers/cards, coverage wording, and independent empty/error states. Run analyzer, existing suite, and production web build.
- Run the manual maintenance job against production with the already approved GitHub secret, inspect Firestore source health and the Vercel endpoint, then deploy web to the existing Firebase Hosting site. Test both views on the live site at phone and desktop widths and verify source links and map attribution.
- Push only `main`. After live checks, move the user-approved `v1.0.0` tag to the final commit, let the tagged mobile workflow build, and replace the stale GitHub Release assets with artifacts from that exact tag.

## Known limits

GDACS may report few or no India-impacting events on a quiet day; the UI shows an honest empty state. A nearby marker denotes the saved home area's alert coverage, so the app must not describe it as the incident site. OpenStreetMap's public tile service is best-effort and may rate-limit heavy use; the event and alert lists remain usable without tiles. These feeds do not replace emergency instructions from local authorities.

## October 3 user update

The user removed scheduled GitHub Actions and requested minimal manual workflows. Feed refresh is now request-driven, guarded by a Firestore compare-and-swap lease, limited to one attempt per 30 minutes globally and 40 seconds per invocation. Failures back off for five minutes. The API filters expired rows immediately; refresh/manual maintenance purges them. Remaining photo and safety maintenance is manual. No alternate cron service is introduced.
