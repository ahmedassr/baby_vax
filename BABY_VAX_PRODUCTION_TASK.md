# Task: Make Baby Vax production-ready for Google Play (autonomous cloud run)

You are working in the `baby_vax` Flutter repo (github.com/ahmedassr/baby_vax), in a Claude Code cloud session. The owner, Ahmed, has turned his computer off and is not available. **Nobody will answer questions or approve anything during this run.** He has given you full authority to inspect, fix, refactor and improve the code.

The app: a child vaccination tracker. Parents sign up, add a child's birth date, the app generates a vaccination schedule, sends reminders (currently local notifications + FCM from a Cloud Function, which must change; see item 8), tracks growth, and has tips. Flutter + GetX + MVVM, Firebase Auth, Firestore, FCM, Arabic + English localization. The Firebase project is on the free Spark plan. About 124 Dart files under `lib/app/`.

## How to run (read first — this run must never stall)

1. **Never stop to ask a question or wait for approval.** Don't use AskUserQuestion, and don't end a turn with "should I…?". When a decision is unclear, choose the safest reasonable option, write the choice and the reason in `RELEASE_NOTES_FOR_AHMED.md` under "Decisions I made", and keep going.
2. **When something is blocked** (a tool can't be installed, a network download fails, a test needs a real device or a secret): try a reasonable alternative once or twice. If it's still blocked, record it under "Blocked — needs Ahmed" with the exact error and the exact steps for him, skip it, and continue with everything else. One blocked item must never stop the run.
3. **Don't finish early.** Work through every phase below until the Definition of done is met, or until every remaining item is recorded as blocked. Only then write the final summary and stop.
4. **Save progress continuously.** Work on the branch `release/play-v1` (it already exists; check it out and pull, or create it from `main` if missing). Commit after each logical change and **push after every phase**, so nothing is lost if the session ends. Open the PR into `main` early, as a **draft PR**, and keep updating its description. When everything is done, mark it ready for review. Never merge it. Never push to `main`.
5. **Environment setup.** If Flutter, Dart, the Android SDK (cmdline-tools, platform 36, build-tools), Java 17+, Node 22, or firebase-tools are missing, install them yourself. Pin Flutter to the current stable channel. If an Android SDK download is blocked by the network, still do every code change and run `flutter analyze` + `flutter test` (these don't need the Android SDK), and record the build step as blocked.

## Hard limits (skip these: prepare them and document them, never do them)

These would damage the live app or need Ahmed's own accounts. Don't do them, and don't wait for permission either. Prepare everything, write the exact commands in the notes, and move on:

- Rewriting git history or force-pushing (e.g. to purge the leaked keystore from history). Remove the file in a normal commit, and give Ahmed the `git filter-repo` commands.
- Any `firebase deploy` (rules, indexes, functions) or any write to the live Firebase project. Test with the Firebase emulator only.
- Deleting or migrating real user data.
- Changing the applicationId `com.ahmedalassar.babyvax`.
- Creating or using a real release keystore. Ahmed creates his own. Debug-sign any test build, and make the release config read `key.properties`.
- Committing any secret.

## Ground rules

- Keep the existing architecture (GetX + MVVM, feature modules). Improve it. Don't rewrite the app.
- After every phase, the code must still compile. Run `flutter analyze` and `flutter test` often.
- Keep a running log in `RELEASE_NOTES_FOR_AHMED.md` at the repo root, with these sections: Plan, Changes (by area), Decisions I made, Blocked — needs Ahmed, Commands for Ahmed, Manual QA checklist.
- `google-services.json` and `GoogleService-Info.plist` stay in the repo (client config, not secrets).

## Known issues (found in a code review; verify each one and fix it)

1. **Leaked signing key.** `android/app/keystore_base64.txt` is a PKCS12 keystore committed to a public repo. Delete it, and add `*.txt` keystore dumps, `*.jks`, `*.keystore`, `key.properties` to `.gitignore`. Wire `android/key.properties` → `signingConfigs.release` (already read in `build.gradle`). Make release builds fail with a clear message when `key.properties` is missing, instead of silently signing with a null config. Put the exact `keytool` command for Ahmed in the notes, plus a reminder to back up the key.
2. **Target SDK.** Google Play requires new apps to target **API 36** (since 31 Aug 2026). Set `compileSdk = 36` and `targetSdk = 36` explicitly. Upgrade Flutter, AGP, Gradle, Kotlin and plugins as needed (`flutter pub outdated`, then upgrade the Firebase plugins to current major versions). Fix every breaking change.
3. **`USE_FULL_SCREEN_INTENT`** in AndroidManifest. Play restricts it to calling and alarm apps. Remove it, along with any `fullScreenIntent: true`.
4. **Exact alarms.** `local_notification_provider.dart` uses `AndroidScheduleMode.exactAllowWhileIdle` with `SCHEDULE_EXACT_ALARM`. Vaccine reminders don't need minute precision. Switch to `inexactAllowWhileIdle`, remove the permission, and keep reminders working after reboot (the boot receiver is already declared).
5. **POST_NOTIFICATIONS (Android 13+).** Verify the runtime permission request exists, is asked at a sensible moment, and that the app behaves well when it is denied.
6. **Account deletion (Play policy).** The app has sign-up but no delete-account flow. Add "Delete account" in Settings: re-authenticate, delete the user's Firestore data (the user doc and all subcollections, e.g. `medical_dates`), cancel local notifications, delete the Auth user, sign out. Localize it. Add tests.
7. **Firestore security rules are not in the repo.** Add `firestore.rules` and wire it in `firebase.json`. Users can read and write only their own documents (`request.auth.uid == userId`), with validation on field types and sizes. Deny everything else. Add `firestore.indexes.json` if the queries need it. Write rules tests that run against the emulator (`@firebase/rules-unit-testing`). If the emulator can't run here, keep the tests and record that as blocked.
8. **No Cloud Functions: Ahmed is on the free Spark plan, and Blaze is not an option.** The app must not depend on any server. Make **local scheduled notifications the single source of truth for vaccine reminders**:
   - When the schedule is generated or edited, schedule a local reminder for each upcoming vaccine (e.g. 1 day before at 9:00 local time, and on the day). Use stable notification IDs derived from the vaccine record, so rescheduling never duplicates.
   - Re-sync all reminders from Firestore on login, on app start, after editing a child or a date, after a timezone or locale change, and after reboot (the boot receiver exists). Cancel them all on logout and on account deletion.
   - Respect Android's limit on pending alarms: schedule only the next N months (e.g. 6) and top up on each app start.
   - Reminders must work fully offline. That matters for the users this app targets.
   - Remove the server-reminder path: take `functions/` out of `firebase.json`, and move the old function to `docs/future/cloud-function-reminders.js`, with a note on why it's parked. Remove the client code that saved FCM tokens only for that function. Keep `firebase_messaging` only if the app has a real use for messages sent from the Firebase console (free on Spark). Otherwise remove it, stop storing FCM tokens, and drop them from the privacy policy. Record the choice under "Decisions I made".
   - Make sure nothing in the app needs a Blaze-only feature. Firestore, Auth, FCM, Crashlytics and App Check all work on Spark.
9. **Duplicate notifications.** This is solved by item 8: there's one source (local). Verify that no FCM handler still shows a reminder too.
10. **Cleanup.** Remove the unused `googleapis_auth` dependency and its export in `import_library.dart`, if it's truly unused. Delete the committed `analyze_report.txt`. Fix the pubspec `description` ("A new Flutter project."). Fix every `flutter analyze` warning and deprecation (e.g. `withOpacity` → `withValues`, `onBackground` → `onSurface`).

## Full production audit (beyond the list above)

- **Correctness:** the vaccination schedule generation logic, date and timezone handling (`timezone` package, DST), age calculations, edge cases (future birth dates, leap years, a child older than the schedule).
- **Error handling:** no unhandled exceptions. Offline, Firestore permission denied, auth errors and token expiry all show friendly localized messages. No `print`; use `logger` and silence verbose logs in release.
- **Crash reporting:** add Firebase Crashlytics (`FlutterError.onError` + `PlatformDispatcher.instance.onError`). Enabling it in the console is for Ahmed: note it.
- **Security:** add Firebase App Check (Play Integrity provider in release, debug provider in debug). Enforcement in the console is for Ahmed: note it. Validate all form inputs. No sensitive data in logs.
- **Offline:** Firestore offline persistence works, and the app is usable without internet.
- **Localization:** every user-facing string goes through the localization system, in Arabic and English. RTL layout is correct on every screen.
- **Accessibility:** semantics labels, tap target sizes, no overflow at text scale 1.3, sufficient contrast.
- **Performance:** `const` constructors, no rebuild storms, images sized properly.
- **Release build:** R8 minify + resource shrinking, with ProGuard keep rules if needed. Try `flutter build appbundle --release` (debug-signed is fine here) to prove it builds. Document the obfuscated build command with `--split-debug-info`.
- **Medical disclaimer:** a clear in-app note (onboarding and the schedule screen) that the schedule is informational, and that parents should follow their doctor and their national immunization schedule. State which schedule the app uses and its source.
- **Tests:** unit tests for schedule generation and date logic, widget tests for the main flows, and Firestore rules tests. Focus on meaningful coverage of core logic, not a percentage.
- **CI:** add a GitHub Actions workflow running `flutter analyze` and `flutter test` on every PR.
- **Firebase MCP:** don't install or authenticate the Firebase MCP server or the Firebase CLI against the live project in this run. Use the local emulator only.
- **iOS:** don't spend much time here (Android ships first), but don't break iOS. List what's needed for a later App Store release.

## Deliverables

1. Draft PR `release/play-v1` → `main`, marked ready for review at the end, with a clear description.
2. `RELEASE_NOTES_FOR_AHMED.md`, with the sections listed under Ground rules. It must include exact, copy-paste commands for: creating the upload keystore, filling `key.properties`, building the signed AAB, deploying Firestore rules and indexes, and purging the old keystore from git history.
3. `docs/privacy-policy.html` and `docs/delete-account.html`: simple, honest pages hostable on GitHub Pages or Vercel. The privacy policy covers what data is collected (email, child name, birth date, growth data, crash data, and the FCM token only if FCM is kept), why, where it's stored (Firebase / Google Cloud), retention, deletion, and contact (ahmedassr360@gmail.com).
4. `docs/play-store-listing.md`, containing:
   - app name, short description (≤80 chars) and full description (≤4000 chars), in English and Arabic
   - a recommended category
   - draft answers for Data safety, Content rating, Target audience (**18+**, since the app is for parents; avoid the Families program), the Health apps declaration, and Ads (none)
   - the list of screenshots to capture
5. A 512×512 store icon and a 1024×500 feature graphic, generated from `assets/appIcon.png` / `assets/app_branding.png` if possible. Otherwise list the specs.

## What only Ahmed can do (list these in the notes)

- Create the Google Play developer account (USD 25, identity verification).
- Create the upload keystore with his own passwords, and back it up.
- Deploy Firestore rules and indexes from his own machine (`firebase deploy --only firestore`). The project stays on the free Spark plan, with no functions.
- Enable Crashlytics and App Check in the Firebase console, and add the SHA-256 fingerprints.
- Host the two HTML pages, and put their URLs in Play Console.
- Test on a real Android 14/15/16 device using the Manual QA checklist.
- Run a closed test with **at least 12 testers opted in for 14 consecutive days**, then apply for production access.

## Definition of done

- `flutter analyze`: zero issues. `flutter test`: passes, including tests for reminder scheduling (IDs are stable, no duplicates, cancel on logout).
- `flutter build appbundle --release` succeeds, targeting API 36 (or is recorded as blocked, with the exact error).
- No secrets in the repo tree.
- All of known issues 1–10 are fixed, or recorded as blocked with a reason.
- The deliverables exist, everything is pushed, and the PR is marked ready for review.
- The final message in this session is a short summary: what's done, what's blocked, and Ahmed's next 5 steps.

Start now: set up the environment, read the codebase, write the Plan section in `RELEASE_NOTES_FOR_AHMED.md`, push, open the draft PR, then work through it.
