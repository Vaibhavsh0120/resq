# ResQ production release

ResQ is a best-effort hackathon safety companion. It does not dispatch emergency
services. Digital SOS, AI, push, alerts, and background jobs can be delayed or
unavailable; the app exposes 112 calling and manual SMS separately.

## Hosted services

| Part | Free service | Production address or project |
| --- | --- | --- |
| Flutter web | Firebase Hosting (Spark) | <https://resq-106ed.web.app/> |
| Authentication and data | Firebase Auth and Firestore (Spark) | `resq-106ed` |
| FastAPI | Vercel Hobby | <https://resq-api.vercel.app/v1/health> |
| Assistant text | Gemini API free tier | `gemini-3.1-flash-lite`, called by FastAPI |
| Private report photos | Cloudinary Free | `dhthlaknh`, called by FastAPI |
| Manual maintenance and release builds | GitHub Actions free allowance | `operations.yml`, `build-release.yml` |

The web and mobile clients call Firebase Auth and Firestore directly under
Firestore rules. They send Firebase ID tokens to FastAPI for privileged
operations. FastAPI verifies those tokens, uses Firebase Admin for Firestore,
calls Gemini for assistant text, and uses authenticated Cloudinary delivery for
report photos. The browser never receives these provider secrets.

Firebase test and production data share the same project. Use disposable test
accounts carefully and do not present demo records as official alerts.

## Configuration

The operator account is `vaibhavsh0120@gmail.com`. `backend/.env` is local,
ignored by Git, and holds the same production backend settings for operator
testing. The Vercel `resq-api` project holds encrypted Production variables:
`APP_ENV`, `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`,
`ALLOWED_ORIGINS`, `CLOUDINARY_URL`, `AI_PROVIDER`, `AI_API_KEY`,
`AI_TEXT_MODEL`, and `TRUST_CLOUDFLARE_CLIENT_IP`. Use
`backend/.env.production.example` as the key list. Never commit a populated
`.env` or put these values in Flutter defines. Vercel CLI `env pull` masks
encrypted values; empty strings in that export do not prove the deployed
variables are empty. Its OIDC token is short lived and should not be shared.

GitHub Actions needs repository secrets `RESQ_FIREBASE_SERVICE_ACCOUNT_JSON`
and `RESQ_CLOUDINARY_URL` for manual maintenance, plus repository variable
`RESQ_API_BASE_URL=https://resq-api.vercel.app` for release builds. Inspect a
manual `ResQ Manual Maintenance` run when screening photos or retrying safety delivery.
No workflow runs on a schedule, push, or pull request. Updates triggers bounded
feed refreshes at most every 30 minutes globally; failed attempts back off for
five minutes and preserve still-relevant cached records. Physical cleanup occurs
on refresh/manual maintenance; expired records are excluded from reads immediately.
Check-in reminders, pending SOS retries, photo screening, and stored-asset deletion
are operator-triggered. Photo access still ends after 30 days at the API.
Optional `RESQ_IMD_DISTRICT_IDS` requires official IMD access and verified IDs;
without them IMD is unconfigured. NDMA SACHET RSS is the default feed.

To deploy the current source manually from `main`:

```powershell
cd backend
vercel --prod --yes
cd ..\frontend
flutter build web --release --dart-define=RESQ_APP_ENV=production --dart-define=RESQ_API_BASE_URL=https://resq-api.vercel.app
firebase deploy --project resq-106ed --only firestore:rules,firestore:indexes,hosting
```

The Firebase deployment uses `frontend/firebase.json` and its explicit Hosting
site. The API deployment uses `backend/pyproject.toml` and `backend/vercel.json`.
Hosting revalidates app files on each visit to prevent stale releases. A browser
that cached a pre-release build under the former one-hour policy may need one
hard refresh after this upgrade.
CLI authentication must be the operator's account. Cloudinary and Gemini free
allowances have limits; monitor usage and stop optional features at exhaustion.

The web pilot uses the durable inbox only; no Web Push key is generated.
APNs credentials are absent, so iOS push is not configured. The unsigned IPA
is a build artifact, not an installable App Store/TestFlight release.
Invite links use Firebase Hosting. Native automatic link opening needs the
matching Android signing fingerprints and Apple team association files;
the HTTPS links work in the web app without those associations.

## Verification and release

1. Run `python -m pytest -q` in `backend`, `npm run test:rules` and
   `flutter analyze --fatal-infos` plus `flutter test` in `frontend`.
2. Build web and Android artifacts with the production API URL. Run an iOS
   build and device checks on macOS with signing credentials. A Windows build
   cannot establish iOS behavior.
3. Check `/v1/health`, open the hosted web app, enter Emergency access, and
   make an assistant request. Verify Firebase Auth, Firestore permissions, and
   Cloudinary API access. Use a disposable account and clean up test data.
4. Check real Circle, SOS inbox, manual SMS/112 handoff, denied location,
   offline state, report moderation and expiry, official feed age, and push on
   actual devices before claiming those flows are validated. An FCM send
   acceptance does not prove delivery or reading.
5. Run manual maintenance and inspect source/job health and quota dashboards.
   Vercel Hobby functions have bounded duration. No timer-driven work or
   guaranteed emergency delivery is configured.

The `Build ResQ Mobile Releases` workflow builds release artifacts on a
manual dispatch. Its unsigned iOS artifact needs device signing before use. Do not
acknowledge device tests that did not happen.

## Rollback

Re-deploy the prior known-good Vercel deployment and Firebase Hosting version,
then review Firestore rules before reverting them. Run manual photo cleanup
and safety retries during rollback. Record affected features, commit
SHAs, and any pending SOS inbox or photo deletion work.
