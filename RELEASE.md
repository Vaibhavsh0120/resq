# ResQ production release

ResQ is an open-public, best-effort hackathon release. Digital SOS, push,
check-ins, AI, and official alerts depend on external services and scheduled
jobs. They may be delayed or unavailable. The 112 call and manual SMS stay
available in the app. ResQ is not an emergency dispatch service.

## One-time operator setup

1. Use Firebase project `resq-106ed`. Enable Authentication and Firestore.
   Create a service account with the minimum Firebase permissions needed for
   the API, Firestore deployment, and scheduled jobs. Keep its JSON in secrets.
2. Create a Render Free web service from `render.yaml`, keep auto deploy off,
   and set the service's production URL as GitHub variable
   `RESQ_API_BASE_URL` (for example `https://resq-api.onrender.com`). Set a
   Render deploy hook as secret `RESQ_RENDER_DEPLOY_HOOK`. The hook must refer
   to this service's linked repository.
   The blueprint enables `TRUST_CLOUDFLARE_CLIENT_IP` for the Render edge.
   Check that the service receives `CF-Connecting-IP` during the pilot so guest
   per-IP AI allowances are per visitor; a missing or invalid header falls back
   to the proxy address. The app never trusts client-supplied
   `X-Forwarded-For` for quota identity.
3. Create a Cloudinary Free account. Set its `CLOUDINARY_URL` only in Render
   and GitHub secrets. Report assets use authenticated delivery; moderators
   obtain them through the API only after scanning.
4. Select one active text provider: `openai`, `groq`, `gemini`, or `claude`.
   Set `AI_PROVIDER`, `AI_API_KEY`, and `AI_TEXT_MODEL` only in Render. Confirm
   that the chosen account has an allowance that incurs **no charges**. The
   operator must run a live pilot before public use. Other provider adapters
   have contract tests, not live guarantees.
5. Set Render `FIREBASE_SERVICE_ACCOUNT_JSON`, `CLOUDINARY_URL`,
   `ADMIN_API_KEY`, and `ALLOWED_ORIGINS`. The latter must include the exact
   Firebase Hosting domains. Set GitHub secrets
   `RESQ_FIREBASE_SERVICE_ACCOUNT_JSON`, `RESQ_CLOUDINARY_URL`, and
   `RESQ_RENDER_DEPLOY_HOOK`. Set GitHub variables `RESQ_API_BASE_URL` and,
   if web push is enabled, `RESQ_FCM_VAPID_KEY`.
6. Optional IMD district IDs use GitHub variable `RESQ_IMD_DISTRICT_IDS` in
   `id:district:state` comma-separated form. Use only IDs and labels confirmed
   from the official IMD source, with at most 50 IDs per run. The official
   district endpoint returned an IP whitelist error during development; enable
   it only after IMD grants the scheduled runner access and a live pilot passes.
   With no IDs, IMD is shown as unconfigured; the NDMA SACHET RSS remains the
   default source. Never present an unconfigured or blocked source as coverage.
7. Give a registered Firebase account the moderator claim from a trusted
   operator shell with Firebase credentials configured:
   `cd backend && python scripts/manage_admin.py UID grant`. Refresh that
   account's ID token, then open `/admin`. Never grant this to a guest.
8. Configure Android signing if distributing through a store. iOS push needs
   working APNs credentials and a signed build. An unsigned IPA requires an
   external sideload signing path and cannot prove push delivery.

The scheduled `ResQ Best-Effort Operations` workflow runs from the repository
default branch. It retries SOS inbox delivery and check-in reminders, refreshes
official feeds, scans photos with current ClamAV definitions, and purges
expired photos. Enable GitHub Actions and inspect the first manual run. GitHub
schedules may run late; no job has an exact delivery-time guarantee.

## Exact-commit release sequence

1. Merge the reviewed code to the intended release commit. Do not change
   source or configuration between build, device tests, and deployment.
2. Set the final Render URL in `RESQ_API_BASE_URL`. Trigger
   `Build ResQ Mobile Releases` with a new `vMAJOR.MINOR.PATCH` tag value.
   Save its run ID and full 40-character head SHA. The build runs backend,
   Flutter, and Firestore rules tests, then builds Android APK/AAB, IPA, and
   web artifacts with production API configuration.
   Workflow artifacts are retained for three days to limit free storage use;
   complete testing and deployment within that window.
3. Exercise the **artifact from that run** in a browser and on an Android
   device. Install that run's IPA on the user's iPhone through a valid signing
   or sideload path. Test 112 opening, SMS handoff, real Circle membership,
   offline and denied-location states, check-ins, assistant quota, report
   moderation, account deletion, photo expiry, and official feed freshness.
   Verify push only where the installed build has working platform credentials;
   otherwise verify the in-app inbox and show the push limitation.
4. Check the free-provider pilot and scheduled job health. Check no paid
   provider billing is enabled. Record artifact hashes and the same SHA.
5. Trigger `Deploy Tested ResQ Commit` with the build run ID, same SHA,
   release tag, and true device/web test acknowledgements. It downloads the
   tested artifacts, deploys Firestore rules/indexes and that exact web
   artifact, deploys the same Git SHA to Render, checks its health SHA, and
   publishes the same mobile artifacts. A failed deploy is not a release.

Do not enter `true` for a device test that did not happen. A passing emulator,
web build, or unsigned IPA build does not replace an iPhone installation test.

## Operational states

- SOS event `deliveryStatus` means server processing/inbox state only. Push
  `sent` means FCM accepted a send attempt; it does not mean a person received
  or read it. If the API sleeps or fails, use 112 or manual SMS immediately.
- Official alerts are matched to a saved district and state, carry source and
  expiry, and show last refresh/coverage gaps. They are best effort and never
  replace direct official warnings. Verified places require a human-recorded
  source and verification.
- Report photos remain private and cannot be fetched by moderators until
  scanned clean. Moderator access stops at `photoExpiresAt` (30 days after
  upload). The purge job deletes Cloudinary assets at its next run, retries
  failures, and fails visibly when deletion is overdue. Account deletion
  removes photos before deleting the account so a storage failure can be
  retried.
- AI text and device speech share one daily allowance. Exhaustion never
  blocks emergency calling or SMS. Voice recognition and speech output
  depend on the device and may not work offline. Daily per-user and hashed
  guest-IP allowance counters are removed after 35 days by a scheduled job.
- Monitor GitHub Actions failures, Render health, `/admin` source health,
  Firestore usage, and Cloudinary Free usage. `monitor_health.py` fails the
  scheduled workflow for stale or failed jobs. If capacity is exhausted,
  disable the affected optional feature and tell users its status.

## Rollback

Use Render's previous successful deploy and re-deploy the previous known-good
web artifact from its release run. Firestore rules and indexes are source
controlled: deploy the matching previous commit's configuration after review.
Do not restore old rules if they would re-enable client-authored SOS events or
private photo access. Keep scheduled deletion jobs running through a rollback.
Record the incident, exact SHAs, affected features, and whether pending SOS
inbox records or overdue photo deletions require a manual retry.
