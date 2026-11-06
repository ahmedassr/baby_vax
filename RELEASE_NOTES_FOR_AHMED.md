# Baby Vax — Play Store release prep

Branch `release/play-v1` → draft PR into `main`.
Autonomous cloud run, 2026-11-06.

---

## Progress

**2026-11-06 — run 1. All phases complete.**

Finished: environment and baseline; dependency and toolchain upgrade; release
signing hardening; manifest permissions; local reminders as the single source;
schedule date correctness; delete-account flow; Firestore rules, index and
rules tests; Crashlytics and App Check; error handling, logging and offline;
cleanup to zero analyze issues; medical disclaimer; CI; release build; Play
Store deliverables.

Verified in this environment:

| Check | Result |
|---|---|
| `flutter analyze --fatal-infos --fatal-warnings` | **No issues found** (was 24) |
| `flutter test` | **62 / 62 passing** (was: would not compile) |
| Firestore rules tests (emulator) | **32 / 32 passing** |
| `flutter build apk --debug` | **succeeds** |
| `flutter build appbundle --release` | **succeeds**, 63.5 MB AAB, R8 + resource shrinking |
| Release artifact target SDK | **`targetSdkVersion="36"`**, `minSdkVersion="24"` |
| Release artifact permissions | INTERNET, ACCESS_NETWORK_STATE, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, VIBRATE — the restricted ones are gone, including after plugin manifest merging |
| Secrets in the repo | none |

**Next:** nothing is blocked in code. What remains is the list under
[What only Ahmed can do](#what-only-ahmed-can-do) — the keystore, the Play
account, the console toggles, hosting the two pages, device QA, and the
12-tester closed test.

---

## Changes (by area)

### Toolchain and dependencies

- Flutter pinned to **3.47.9** stable (Dart 3.13.7). Android SDK 36,
  build-tools 36.0.0, JDK 17 target.
- **Gradle 8.11.1 → 8.14.3**, **AGP 8.9.1 → 8.13.0**, **Kotlin 2.1.0 → 2.4.0**.
  Flutter 3.47 requires Gradle ≥ 8.14.0, and `firebase-auth` 25.0.0 ships
  Kotlin 2.4.0 metadata so anything older fails to compile against it.
- Deliberately **not** on AGP 9. Flutter's template now defaults to it, but
  AGP 9 reads only the new DSL and fails to apply the Flutter plugin to this
  project's Groovy build files.
- `compileSdk` and `targetSdk` pinned explicitly to **36** rather than tracking
  `flutter.compileSdkVersion`, so Play's requirement cannot drift with the SDK.
- 86 packages upgraded. `google_fonts` 6.2.1 → 9.0.0 was the blocker: the old
  version fails const evaluation under Dart 3.13.7, which made **every** test
  file fail to load.
- Removed `googleapis_auth` (only ever re-exported, never used) and
  `onesignal_flutter` (see Decisions). Added `flutter_timezone`,
  `firebase_crashlytics`, `firebase_app_check`. Declared
  `flutter_localizations`, which `main.dart` imported without it being in
  `pubspec.yaml`.

### Reminders

- **Local notifications are now the only reminder path.** `functions/` is gone
  from the repo and from `firebase.json`; the function is parked at
  `docs/future/cloud-function-reminders.js`.
- Reminder text is localized (ar + en). It was hardcoded Arabic, so English
  users got Arabic reminders. (The Arabic also had a typo: "غذا" for "غداً".)
- **Notification ids** now use FNV-1a/32 instead of `String.hashCode`, which
  Dart does not guarantee to be stable across versions or platforms and which
  can exceed the signed 32-bit range Android requires. An id that shifts means
  `cancel()` misses the old notification — which is exactly how duplicates
  appear.
- **Timezone** now comes from the device. It was hardcoded to `Asia/Jerusalem`,
  so every reminder fired at Palestine's clock wherever the user actually was,
  and ignored DST.
- Reminders are capped to a **6-month horizon and 200 pending**, topped up on
  every app start. Sign-up previously scheduled all 10 vaccines across 15 years
  at once, which Android's pending-alarm limit silently truncates.
- `syncFromFirestore` is the single sync entry point (login, app start,
  timezone change, vaccine completed). It only cancels **after** the Firestore
  read succeeds, so a failed read no longer leaves you with no reminders at all.
- Reminders are now cancelled on **logout** and when a vaccine is **marked
  completed**. Neither happened before, so the app kept reminding about
  vaccinations already given, and on a signed-out phone.
- Past reminders are skipped. The old code scheduled a same-day reminder one
  minute into the future, which fires immediately and looks like a bug.

### Schedule correctness

The generator used fixed `Duration(days:)` offsets. Three separate bugs:

- **12 months was written as 350 days** — the MMR/varicella dose landed about
  two weeks early.
- Year offsets used `365 * n`, so the 5-, 11- and 15-year doses drifted early
  as leap days accumulated. The 15-year Td booster was **4 days early**.
- Adding a `Duration` to a local `DateTime` shifts by absolute hours, so
  crossing a DST boundary moved an appointment's time of day and could move it
  onto the adjacent calendar day.

Now calendar-month arithmetic that clamps to month length (31 Jan + 1 month =
28/29 Feb), dates normalized to midnight, and a stable `code` on each record so
names can be localized later without rewriting documents.

**Birth-date validation** added: empty, unparseable, future, and over-18 dates
are rejected with localized field errors, *before* the Auth user is created.
Previously `DateTime.parse` could throw a raw `FormatException` that nothing
caught, and a typo produced a schedule of impossible appointments.

### Security and privacy

- `firestore.rules` added, default-deny, with per-collection ownership and
  field validation. 32 emulator tests cover it.
- `firestore.indexes.json` carries the composite index `HomeController`
  actually needs (`state ==` + `date >=` + `orderBy date`). Without it that
  query fails at runtime with `FAILED_PRECONDITION`.
- **Account deletion** added (Play policy requirement). Re-authenticate →
  delete Firestore data → cancel reminders → delete Auth user → sign out.
- **Firebase App Check** (Play Integrity in release, debug provider in debug).
- OneSignal removed — it was sending user ids to an undisclosed third-party
  processor.
- FCM token storage removed, so there is no device identifier to declare.

### Robustness

- `getFriendlyErrorMessage` substring-matched `error.toString()` against
  English fragments. Replaced with `friendlyFirebaseError`, which switches on
  `FirebaseException.code` and returns localized strings. It now handles
  offline, `permission-denied`, expired sessions, and rate limiting — none of
  which were handled at all.
- **Crashlytics** wired to `FlutterError.onError` and
  `PlatformDispatcher.instance.onError`, disabled in debug.
- Fixed the service boot order: notifications were initialized **before**
  `GetStorage.init()` and before the storage and Firestore services were
  registered.
- Firestore offline persistence enabled explicitly, unlimited cache.
- Logger drops below-warning records in release — they cost CPU and put names,
  dates and document paths into logcat.
- `MedicalDatesModel` parsing hardened: it read `name`/`description` straight
  into non-nullable fields and assumed `date` was always a `Timestamp`, so one
  partial document threw and took out the whole schedule screen.

### Fixed in passing (not on the task list)

- **Sign-up wrote the user profile to the bare uid** — a single-segment path,
  which is not a valid Firestore document reference, while every read uses
  `users/<uid>`.
- Removed the dead "additional" third button from `AlertModel` / `AlertWidget`:
  plumbed all the way to the widget, but no factory ever set it.
- Deleted `test/widget_test.dart`, the unmodified Flutter counter template
  asserting on a counter this app does not have.

### Release engineering

- Release builds **fail loudly** without `key.properties` instead of silently
  producing an unsigned artifact. Verified.
- R8 minify + resource shrinking on, with keep rules in
  `android/app/proguard-rules.pro`.
- CI (`.github/workflows/ci.yml`): analyze + format + test, rules tests on the
  emulator, and a debug-signed release bundle, on every PR.
- `.gitignore` extended to `*.p12`, `*.pfx`, `key.properties.*` and base64
  keystore dumps.

---

## Decisions I made

### 1. Known issue 1 was already resolved — no history purge

The brief lists `android/app/keystore_base64.txt` as a committed PKCS12
keystore. **It is not in the working tree and not in any commit reachable from
any ref.** Verified by enumerating every blob path in every commit:

```bash
git rev-list --all | while read c; do git ls-tree -r --name-only $c; done | sort -u \
  | grep -iE "keystore|\.jks|\.p12|\.pfx|key\.properties|analyze_report"
# → no matches
```

`.gitignore` already covered `*.jks`, `*.keystore` and `key.properties`, and
`analyze_report.txt` is likewise absent.

**So there is nothing to purge, and I am not giving you `git filter-repo`
commands** — running them would rewrite history for no reason. I did fix the
parts that were genuinely broken: the release `signingConfig` accepted a null
keystore, and `.gitignore` did not cover base64 keystore *dumps*.

⚠️ If that file ever existed on a deleted branch or in a fork, the key could
still be reachable through GitHub's dangling-commit API. If you believe you ever
committed a real keystore, treat it as compromised and generate a fresh upload
key regardless of what git says now.

### 2. OneSignal removed (not in the brief)

`onesignal_flutter` was initialized at startup, requested notification
permission, and called `OneSignal.login(userId)`. The brief never mentions it.

It was a third server dependency (contradicting offline-first reminders), a
third notification path and therefore a live duplicate-reminder source, and an
**undisclosed third-party data processor** — a Play Data safety problem.
Removed. Nothing is lost: it was only used for identity linking.

### 3. Notification ids: FNV-1a/32, not `String.hashCode`

Dart does not promise `String.hashCode` is stable across VM versions or
platforms, and its value can exceed the signed 32-bit range Android requires.
FNV-1a is a fixed, specified algorithm. Reference vectors are pinned in
`test/notification/domin/notification_id_test.dart`, because if the hash ever
changes, reminders scheduled by an older build become uncancellable.

### 4. Timezone from the device, UTC as fallback

If the device reports a zone `timezone` does not know, scheduling falls back to
UTC and logs a warning, rather than throwing and leaving the user with no
reminders. The hour may be wrong until the next successful resolve.

### 5. `firebase_messaging` removed

The brief allowed either. Removed, because:

- its only purpose was receiving the parked Cloud Function's pushes — the
  foreground handler was literally empty;
- the FCM token was written to Firestore **solely** for that function;
- keeping it means declaring a device identifier in the privacy policy and in
  Play's Data safety form, for a feature you are not using;
- `getToken`/`onTokenRefresh` are deprecated in v17, so keeping it also meant a
  migration.

**If you later want console campaigns**, re-adding it is small: add
`firebase_messaging`, restore the default-channel `meta-data` in
`AndroidManifest.xml`, and call `FirebaseMessaging.instance.requestPermission()`.
You must then also add **Device or other IDs → collected** to the Data safety
form and mention the token in the privacy policy.

### 6. Reminder times kept at 09:00 and 18:00

The brief suggested "1 day before at 9:00". The app already had constants for
09:00 on the day and 18:00 the evening before, which reads better — the evening
reminder is when a parent can actually plan tomorrow. Kept, in
`AppConstant.morningReminderHour` / `eveningReminderHour`.

### 7. Category: Parenting, not Medical

Both fit. Parenting draws a lighter review and describes the app better — it
organises appointments rather than providing clinical information.

### 8. Staying on AGP 8.x

Flutter 3.47's template defaults to AGP 9.1.0 / Gradle 9.3.1. AGP 9 reads only
the new DSL and fails to apply the Flutter Gradle plugin to this project's
Groovy build files. Migrating the whole Android build to the new DSL is a
separate, riskier change, so this release stays on the supported AGP 8.13 /
Gradle 8.14.3 pairing.

### 9. Dead third alert button removed

`AlertModel` carried `additionalButtonText`/`additionalAction`, plumbed through
to `AlertWidget`, but no factory ever set them so the button could never
render. Removed rather than kept as an unreachable parameter.

> Note: `dart fix` tried to "fix" this automatically and produced **invalid
> Dart**. I replaced its output by hand.

### 10. Vaccine names are not yet localized at display time

Vaccine names and descriptions are generated in English and written to
Firestore at sign-up, so switching the app to Arabic does not re-translate an
existing schedule. Each record now carries a stable `code`, which is the
groundwork, but wiring the views to it would also need a migration for existing
documents. Out of scope for this release — see Blocked.

---

## Blocked — needs Ahmed

Nothing in this release is blocked by tooling. Everything attempted succeeded,
including the Android build and the Firestore emulator tests. These are the
items that need a human, a device, or an account:

| # | Item | Why | What to do |
|---|---|---|---|
| 1 | **Screenshots** | Needs a real device and a populated profile | Capture the 6 shots listed in `docs/play-store-listing.md` |
| 2 | **Device QA** | No physical device here | Work through the Manual QA checklist below on Android 14/15/16 |
| 3 | **Upload keystore** | Must be created with your own passwords and never leave your machine | Commands below |
| 4 | **Console toggles** | Crashlytics and App Check enforcement are console-only | See "What only Ahmed can do" |
| 5 | **Hosting the two pages** | Needs your GitHub Pages or Vercel account | See below |
| 6 | **Demo account for Play review** | Must be created in the live Firebase project | The whole app is behind sign-in; Play rejects builds the reviewer cannot open |
| 7 | **Vaccine-name localization** | Needs a migration for existing documents | Deferred; Decision 10 |

### Partially done, worth knowing

- **Accessibility**: the disclaimer and the delete-account dialog are explicitly
  marked up for screen readers, and the password reveal button is labelled. A
  full pass over every screen at text scale 1.3 needs a device and is on the
  QA checklist.
- **iOS**: nothing was broken, but nothing was added either. It still has the
  default bundle id and no App Store assets. Android ships first, as instructed.

---

## Commands for Ahmed

### 1. Create the upload keystore

Run this once, on your own machine. **Back the file up somewhere you will not
lose it** — if you lose it you cannot update the app on Play without Google's
key-reset process.

```bash
keytool -genkey -v \
  -keystore ~/baby-vax-upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

It will ask for a keystore password, your name and organisation, and then a key
password. Use a long password and store both in a password manager.

### 2. Create `android/key.properties`

This file is gitignored and must never be committed.

```bash
cat > android/key.properties <<'EOF'
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/baby-vax-upload-key.jks
EOF
```

If any of the four lines is missing, the build stops at configuration time and
names the missing entry.

### 3. Back up the keystore

```bash
gpg -c ~/baby-vax-upload-key.jks
# store baby-vax-upload-key.jks.gpg somewhere off this machine
```

### 4. Build the signed release bundle

```bash
flutter clean && flutter pub get
```

```bash
flutter build appbundle --release
```

The AAB lands at `build/app/outputs/bundle/release/app-release.aab`.

### 5. Build with obfuscation and keep the symbols

Recommended for the real upload. **Keep the `debug-symbols` directory** — you
need it to read any crash report from that build.

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-symbols
```

### 6. Verify what you are about to upload

```bash
unzip -p build/app/outputs/bundle/release/app-release.aab base/manifest/AndroidManifest.xml | strings | grep -i targetSdk
```

### 7. Deploy the Firestore rules and index

The project stays on the free Spark plan. There are no functions, so this
deploys only rules and indexes.

```bash
npx firebase-tools login
```

```bash
npx firebase-tools deploy --only firestore:rules,firestore:indexes --project babyvax-2562f
```

Building the index takes a few minutes; watch it in the Firebase console under
Firestore → Indexes.

### 8. Run the rules tests yourself

```bash
cd firestore-tests && npm install && npm test
```

### 9. Host the privacy policy and deletion page

Simplest route, GitHub Pages from the `docs/` folder on `main`:

1. Merge this PR.
2. Repo → Settings → Pages → Source: "Deploy from a branch", branch `main`,
   folder `/docs`.
3. The URLs become:
   - `https://ahmedassr.github.io/baby_vax/privacy-policy.html`
   - `https://ahmedassr.github.io/baby_vax/delete-account.html`
4. Paste both into Play Console (privacy policy under Store listing, deletion
   URL under Data safety).

### 10. Delete the OneSignal app

The app no longer talks to OneSignal. The App ID that was hardcoded in the repo
was `188b14f6-389b-404b-991a-babe68d66589`. That is a public client identifier,
not a secret — the REST API key was never in the repo. Still, delete the app at
<https://dashboard.onesignal.com> so no stale device records are retained there.

---

## Manual QA checklist

Run on a real Android 14, 15 or 16 device. The reminder items are the ones that
cannot be covered by the automated tests.

### Sign-up and schedule

- [ ] Sign up with a new email. The schedule appears with 10 entries.
- [ ] The 2-month dose is exactly 2 calendar months after the birth date; the
      15-year dose is exactly 15 years after.
- [ ] Enter a **future** birth date → a localized error appears on the field and
      no account is created.
- [ ] Enter a birth date more than 18 years ago → a localized error appears.
- [ ] Enter nonsense in the birth date field → a localized error, no crash.
- [ ] The medical disclaimer is visible on sign-up and above the schedule.

### Reminders

- [ ] Accept the notification permission prompt at sign-up. Confirm it appears
      *after* the schedule is created, not at cold start.
- [ ] **Deny** the permission instead → sign-up still completes, the schedule
      still appears, no crash.
- [ ] Set the device clock to the evening before a scheduled dose → the advance
      reminder fires, in the app's current language.
- [ ] Reminder text is Arabic when the app is Arabic, English when English.
- [ ] Reboot the device → pending reminders survive.
- [ ] Mark a vaccine **completed** → its two reminders stop arriving.
- [ ] **Log out** → no further reminders arrive.
- [ ] Open the app repeatedly over several days → no duplicate reminders for the
      same dose. *(This is the regression that stable ids fix.)*
- [ ] Change the device timezone, reopen the app → reminders move to the new
      zone's 09:00 / 18:00.

### Offline

- [ ] Turn on aeroplane mode, open the app → the schedule still renders from
      cache.
- [ ] Try to mark a dose completed offline → a friendly localized message, no
      crash or silent failure.
- [ ] Reminders still fire with no connection. **This is the core promise.**

### Account deletion

- [ ] Settings → Delete account → the warning names what is destroyed.
- [ ] Enter a **wrong** password → a specific error, and the account still
      exists with its data intact.
- [ ] Cancel the dialog → nothing is deleted.
- [ ] Delete with the correct password → signed out, and signing in again
      fails: the account is gone.
- [ ] After deletion, no reminders arrive.
- [ ] In the Firebase console, confirm the `users/<uid>` document **and** its
      `medical_dates` subcollection are both gone.

### Localization and layout

- [ ] Switch to Arabic → every screen is RTL, with no clipped or mirrored text.
- [ ] No untranslated keys visible (a raw `Something_like_this` string on screen
      means a missing key).
- [ ] Set system font size to the largest setting → no overflow on the schedule,
      home, settings or sign-up screens.
- [ ] Dark mode on every screen; the disclaimer stays readable.

### General

- [ ] Rotate the device on each screen; no crash.
- [ ] Kill and relaunch from the launcher; the session is restored.
- [ ] With TalkBack on, the disclaimer is read as one notice, and the
      password-reveal button announces "Show"/"Hide" rather than just "button".

---

## What only Ahmed can do

- Create the **Google Play developer account** (USD 25, identity verification).
- Create the **upload keystore** with your own passwords, and back it up.
- **Deploy Firestore rules and indexes** from your own machine (section 7
  above). The project stays on the free Spark plan, with no functions.
- **Enable Crashlytics** in the Firebase console (Firebase → Crashlytics →
  Enable). Nothing arrives until you do.
- **Enable App Check enforcement** (Firebase → App Check → register the Android
  app with Play Integrity, then enforce per-service). Until then App Check is
  inert, so turning it on in the app cannot lock anyone out — but equally it
  protects nothing. Enforce it only after a release with App Check is live and
  you have verified real traffic is being attested.
- **Add the SHA-256 fingerprints** (Firebase → Project settings → your Android
  app). You need both your upload key and Google's app-signing key from Play
  Console → Setup → App signing. App Check and Play Integrity will not work
  without them.
- **Host the two HTML pages** and put their URLs in Play Console.
- **Create a demo account** in the live project and add it under Play Console →
  App content → App access. The whole app is behind sign-in, so without this the
  reviewer sees a login wall and rejects the build.
- **Capture the screenshots** listed in `docs/play-store-listing.md`.
- **Test on a real Android 14/15/16 device** using the checklist above.
- Run a **closed test with at least 12 testers opted in for 14 consecutive
  days**, then apply for production access.
