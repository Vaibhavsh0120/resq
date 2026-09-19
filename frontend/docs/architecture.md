# ResQ architecture

## Current milestone

The current app has four clear boundaries:

1. **Presentation** — responsive screens and reusable widgets under `screens/`
   and `widgets/`.
2. **Application flow** — the authentication/onboarding gate in `routing/`.
3. **Data and platform services** — Firebase Auth, Firestore profiles, theme
   persistence, and platform detection under `services/`.
4. **Domain data** — typed onboarding/profile values under `models/`.

Firebase Auth is the source of truth for session state. For registered users,
`users/{uid}` is the source of truth for onboarding progress. Anonymous emergency
sessions deliberately skip profile creation and onboarding.

This architecture is appropriate for the present auth milestone: screens do not
talk to Firebase directly, shared behavior is centralized, and the UI is not tied
to a specific phone width.

## Growth path

Do not continue adding every future feature to the global `screens`, `models`, and
`services` folders. As ResQ grows, use feature modules:

```text
lib/
  app/                 app bootstrap, navigation, theme
  core/                shared UI, failures, platform adapters
  features/
    auth/
    onboarding/
    sos/
    preparedness/
    guidance/
    incidents/
    family_circle/
    safe_places/
```

Each feature should own its presentation, domain models, and repository interface.
Firebase implementations should sit behind repositories so emulator tests and
future backend changes do not require screen rewrites. Adopt a larger state/router
package only when deep links, background SOS flows, or independently nested
navigation make the current small gate insufficient.

## Firestore boundaries

Keep highly sensitive data private by default and avoid one giant user document.
Recommended future collection ownership:

```text
users/{uid}                         private profile and onboarding state
users/{uid}/readiness/{itemId}      private checklist state
sosEvents/{eventId}                 owner plus explicitly authorized participants
familyInvites/{inviteId}            sender and intended recipient only
familyCircles/{circleId}/members/*  accepted members only
locationShares/{shareId}            short-lived, consented access only
incidentReports/{reportId}          create by user; moderated public projection
publicAlerts/{alertId}               server/admin writes; authenticated reads
safePlaces/{placeId}                 server/admin writes; authenticated reads
guidance/{guideId}                   server/admin writes; client reads
```

SOS fan-out, public alerts, invitation acceptance, moderation, and authorization
claims should be enforced by trusted server code (Cloud Functions or another
backend), not by trusting fields submitted by a client.

## Safety and privacy rules

- Deny by default; add one collection-specific rule at a time.
- Never make medical information, home coordinates, phone numbers, or live
  locations publicly queryable.
- Use expiring grants for location sharing and store server timestamps.
- Require an explicit accept step before family membership grants access.
- Add Firebase App Check before exposing report creation or other abuse-prone
  endpoints.
- Keep emergency access functional when account onboarding is unavailable.
- Treat device permissions as optional and preserve manual fallbacks.

## Cost guardrail

The default architecture must work without a billing account or credit card.

- Prefer Firebase products available on the Spark plan and design for their free
  quotas.
- Do not add Cloud Functions, paid Google Maps APIs, paid AI APIs, or another
  billing-enabled backend without explicit approval and a free alternative review.
- Keep maps provider-agnostic. The onboarding preview currently uses
  OpenStreetMap without an API key; cache responsibly and follow the public tile
  usage policy. A high-traffic production deployment would need a suitable free
  tile host or self-hosting plan rather than abusing the public tile service.
- Treat quota exhaustion as a normal failure mode: Emergency access and locally
  available guidance must degrade safely rather than becoming unusable.

## Testing expectations

Every milestone should pass `flutter analyze`, `flutter test`, a web release build,
and an Android build. Add Firebase Emulator Suite rule tests before introducing
cross-user reads/writes such as family invitations or SOS sharing.
