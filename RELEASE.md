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
| Scheduled operations | GitHub Actions free allowance | `.github/workflows/operations.yml` |

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
and `RESQ_CLOUDINARY_URL` for scheduled jobs, plus repository variable
`RESQ_API_BASE_URL=https://resq-api.vercel.app` for release builds. Inspect a
manual `ResQ Best-Effort Operations` run before relying on its schedule.
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
CLI authentication must be the operator's account. Cloudinary and Gemini free
allowances have limits; monitor usage and stop optional features at exhaustion.

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
5. Check the GitHub scheduled workflow and quota dashboards. Operations are
   best effort: GitHub schedules can run late, and Vercel Hobby functions are
   bounded in duration. Do not claim guaranteed emergency delivery.

The `Build ResQ Mobile Releases` workflow builds release artifacts on a
version tag. Its unsigned iOS artifact needs device signing before use. Do not
acknowledge device tests that did not happen.

## Rollback

Re-deploy the prior known-good Vercel deployment and Firebase Hosting version,
then review Firestore rules before reverting them. Keep scheduled photo expiry
and safety retries running during rollback. Record affected features, commit
SHAs, and any pending SOS inbox or photo deletion work.
