# Baby Vax — Play Store release prep

Working branch: `release/play-v1` → PR into `main`. Autonomous cloud run, started 2026-11-06.

## Progress

**2026-11-06 — run 1 (in progress)**
- Environment: Flutter 3.47.9 stable / Dart 3.13.7 installed. Android SDK (cmdline-tools, platform 36, build-tools 36) installing.
- Baseline captured: `flutter analyze` = 24 issues; `flutter test` = **fails to compile** (`google_fonts 6.2.1` is incompatible with Dart 3.13.7).
- Next: dependency + toolchain upgrade (blocks everything else), then the known-issue list in order.

---

## Plan

Phases, in dependency order. Each phase ends with `flutter analyze`, `flutter test`, a commit and a push.

| # | Phase | Covers |
|---|---|---|
| 1 | Environment + baseline | — |
| 2 | Plan, notes, draft PR | — |
| 3 | Dependency + toolchain upgrade | Known issue 2 |
| 4 | Release signing hardening | Known issue 1 |
| 5 | Manifest + alarm permissions | Known issues 3, 4, 5 |
| 6 | Local notifications as the single reminder source | Known issues 8, 9 |
| 7 | Schedule generation + date correctness | Audit: correctness |
| 8 | Delete-account flow | Known issue 6 |
| 9 | Firestore rules, indexes, rules tests | Known issue 7 |
| 10 | Crashlytics + App Check | Audit: crash reporting, security |
| 11 | Error handling, logging, offline | Audit: error handling, offline |
| 12 | Cleanup → zero analyze issues | Known issue 10 |
| 13 | Disclaimer, localization, a11y, performance | Audit |
| 14 | Tests, CI, release build | Audit: tests, CI, release build |
| 15 | Play Store deliverables + docs | Deliverables 3, 4, 5 |
| 16 | Final notes, PR ready for review | Deliverable 1, 2 |

### Baseline (before any change)

- `flutter analyze` → **24 issues** (7 warnings, 17 info): deprecated `withOpacity` / `onBackground`, unused imports, one `dead_null_aware_expression`, two unused optional parameters, and `flutter_localizations` imported without being declared in `pubspec.yaml`.
- `flutter test` → **does not compile.** `google_fonts 6.2.1` fails const evaluation on Dart 3.13.7 (`FontWeight` map keys have no primitive `==`). All four existing test files fail to load. Upgrading `google_fonts` is therefore a prerequisite for *any* test work.

---

## Changes (by area)

_Filled in as each phase lands._

---

## Decisions I made

### 1. Known issue 1 (leaked signing key) was already resolved — no history purge needed

The task brief lists `android/app/keystore_base64.txt` as a PKCS12 keystore committed to the public repo. **It is not in the working tree, and it is not in any commit reachable from any ref.** Verified by enumerating every blob path in every commit:

```bash
git rev-list --all | while read c; do git ls-tree -r --name-only $c; done | sort -u \
  | grep -iE "keystore|\.jks|\.p12|\.pfx|key\.properties|analyze_report"
# → no matches
```

`.gitignore` already covers `*.jks`, `*.keystore` and `key.properties`. `analyze_report.txt` is likewise absent from the tree and from history.

**Conclusion:** there is nothing to purge, so I am not giving you `git filter-repo` commands to run — running them would rewrite history for no reason. I still hardened the parts that *were* real problems (see phase 4): the release `signingConfig` silently accepted a null keystore, and `.gitignore` did not cover base64 keystore *dumps*.

⚠️ **One thing you should still check yourself:** if that file ever existed on a branch or tag that was deleted, or in a fork, the key may still be exposed via GitHub's dangling-commit API. If you ever did commit a real keystore, treat the key as compromised and generate a fresh upload key regardless of what git says now.

### 2. OneSignal is being removed (not in the brief, found during the audit)

`pubspec.yaml` carries `onesignal_flutter: ^5.3.5`, and `lib/app/core/notification/data/onesignal_notification_provider.dart` initializes it at startup, requests notification permission, and calls `OneSignal.login(userId)`. The brief's known-issue list never mentions it — it describes the push stack as "local notifications + FCM from a Cloud Function".

This matters for three reasons:
- It is a **third server dependency**, which directly contradicts the requirement that reminders work with no server and fully offline.
- It is a **third notification path**, so it is a live duplicate-notification risk (known issue 9).
- It sends the user's ID and device token to a **third-party processor** that the privacy policy does not mention — a Play Data safety disclosure problem.

Removing it, and recording the OneSignal App ID that was hardcoded in `lib/app/config/constant/app_constant.dart` below under "Commands for Ahmed" so you can delete the OneSignal app itself.

### 3. Notification IDs

_Pending — phase 6._

### 4. Timezone

_Pending — phase 6._

### 5. firebase_messaging

_Pending — phase 6._

---

## Blocked — needs Ahmed

_Filled in as blockers appear._

---

## Commands for Ahmed

_Filled in as phases land. Will include: keystore creation, `key.properties`, signed AAB build, Firestore rules/index deploy._

### Delete the OneSignal app (after this PR merges)

The app no longer talks to OneSignal. The App ID that was hardcoded in the repo was:

```
188b14f6-389b-404b-991a-babe68d66589
```

A OneSignal App ID is a public client identifier, not a secret (the REST API key is the secret, and that was **not** in the repo). Still, once this ships, delete the app at <https://dashboard.onesignal.com> so no stale device records or tokens are retained there.

---

## Manual QA checklist

_Filled in at the end of the run._

---

## What only Ahmed can do

- Create the Google Play developer account (USD 25, identity verification).
- Create the upload keystore with his own passwords, and back it up somewhere he will not lose.
- Deploy Firestore rules and indexes from his own machine (`firebase deploy --only firestore`). Project stays on the free Spark plan, no functions.
- Enable Crashlytics and App Check in the Firebase console, and add the SHA-256 fingerprints.
- Host `docs/privacy-policy.html` and `docs/delete-account.html`, and put their URLs in Play Console.
- Test on a real Android 14/15/16 device using the Manual QA checklist.
- Run a closed test with at least 12 testers opted in for 14 consecutive days, then apply for production access.
