# ResQ v1.0.0 architecture

## Application boundaries

- `lib/app/` owns the GoRouter routes, Riverpod providers and adaptive app shell.
- `lib/routing/` gates authentication and resumable onboarding. Registered users
  complete their profile; anonymous Emergency access goes directly to Home.
- `lib/screens/`, `models/` and `services/` contain the shared auth/onboarding
  flow, profile data, theme, locale and platform services.
- `lib/features/` groups Home, Updates, SOS, Family, reports, places, readiness,
  notifications, assistant, profile and administration. Each feature owns its
  models, repository/API boundary, providers and presentation as needed.
- `lib/widgets/` and `theme/` contain the shared visual components. Maps use
  OpenStreetMap through `flutter_map`, with visible credits below the tiles.

## Services and requests

Firebase Hosting serves Flutter web. Firebase Authentication issues ID tokens.
Client repositories read/write permitted Firestore paths under `firestore.rules`.
For privileged work, the client sends its ID token to FastAPI on Vercel, which
verifies it and uses Firebase Admin, Gemini or Cloudinary. Provider secrets are
backend-only. Anonymous guests have limited emergency and assistant access.

The assistant streams text from Gemini and stores registered users' conversations
in Firestore. Retrieval filters private context by ownership and consent. Voice
uses device speech recognition and text-to-speech with the same text API.
Reports remain private; photos use authenticated Cloudinary delivery, a manual
malware scan and moderation before a sanitized public projection is published.

## Firestore ownership

| Path | Access boundary |
| --- | --- |
| `users/{uid}` | Registered owner profile and onboarding; no client listing |
| `users/{uid}/settings`, `readiness`, `emergencyContacts` | Registered owner reads/writes |
| `users/{uid}/notifications` | Backend creates; owner reads, marks read or deletes |
| `householdCircles/{circleId}` and members/check-ins | Accepted members read; backend manages writes |
| `circleInvites/{inviteId}` | Backend invitation and acceptance only |
| `locationShares/{shareId}` | Consented, expiring shares between accepted members |
| `sosEvents/{eventId}` | Owner and explicitly authorized accepted Circle members |
| `incidentReports/{reportId}` | Registered submitting owner reads; backend writes |
| `conversations/{id}` and messages | Registered owner reads; backend writes |
| `publicAlerts`, `emergencyEvents`, `safePlaces`, `guidance`, `verifiedReports` | Signed-in readers, including guests; backend writes |
| `indiaEvents`, `ingestionState`, devices and quota records | Backend only |

The checked-in rules are authoritative. Unrecognized collections are denied.
Onboarding Family contacts are private contact records, migrated into the contact
list. They do not grant household Circle membership; invitations require explicit
acceptance through the backend.

## Alerts and maintenance

Nearby uses official NDMA SACHET alerts matching the saved home region. Its map
marker identifies coverage at home, not an invented disaster location. Across
India uses India-impacting GDACS events at published coordinates. Cards expose
sources and freshness and remain usable if tiles fail. GDACS events disappear
seven days after their published end; expired local alerts are excluded as well.

Updates requests trigger feed refreshes under a Firestore compare-and-swap lease:
at most every 30 minutes globally, five-minute failure backoff, bounded network
and database calls. Still-relevant cached events survive an upstream failure.
Expired data is excluded from reads immediately and purged on refresh/maintenance.

The two GitHub workflows are manual: release builds with quality checks, and
operator maintenance for feed ingestion, reminders, pending SOS retries, photo
scanning/deletion and health. There is no scheduler. The web release uses its
Firestore inbox; no browser push credential or messaging worker is configured.

## Repository and cost boundaries

Source, tests, dependency lockfiles, native platform projects, public Firebase
client configuration, configuration examples and useful documentation are tracked.
Local environments, generated artifacts, test data, identities and plaintext
credentials are ignored. `backend/.env.age` is an encrypted operator backup;
it is excluded from deployment uploads and is never loaded by the application.

Hosting/Auth/Firestore use Firebase Spark, the API uses Vercel Hobby, photos use
Cloudinary Free, and Gemini uses its free allowance. No credit card or billing
account was added. Quota exhaustion and unavailable services require usable error
states and manual emergency fallbacks. Public OSM tiles have usage limits.

## Verification boundaries

The release workflow checks backend tests, Flutter analysis/tests and Firestore
rule tests, then builds web, Android APK/AAB and an unsigned iOS IPA. Production
checks use disposable accounts for Circle/inbox SOS, private report moderation,
Gemini streaming/history and account deletion. Physical calling, SMS, voice, push
and signed iOS installation require actual device checks. See the root
[release guide](../../RELEASE.md) and [privacy notice](../../PRIVACY.md).
