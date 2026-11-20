# Stage 2 Tasks: `identity`

> Plan: [plan.md](plan.md) · Spec: [SPEC-identity.md](../specs/SPEC-identity.md) · Gate = `dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test && flutter build web --release`, plus `cd firebase && npm test` when the rules change (prefix `JAVA_HOME=/usr/lib/jvm/java-21-openjdk` if your shell still points at JDK 17)

---

## Slice 1: `feat/identity-claim`

> Before Task 1 (you): `git switch -c feat/identity-claim dev`. The uncommitted plan files come along.

### Task 1: Spec answers and data classification

**Description:** Fold the plan's decisions and your answers into the specs before any code:
- **`SPEC-identity.md`:**
  - status → approved
  - the password minimum: Firebase's default, 6 characters, so AC-ID-1 keeps "≥ 6-char"
  - username input is trimmed before lowercasing
  - **Display name:**
    - trimmed, 1–30 characters, defaults to the username
    - changeable from the account screen: a Scope line, new AC-ID-11, and `UserRepository.updateDisplayName(uid, displayName)` in the interface
  - **Rules:**
    - the shape checks
    - the `getAfter` cross-check
    - `users/{uid}` update = the owner, `displayName` only (`affectedKeys`)
    - `delete` denied on both collections
  - **Data classification table:**
    - email: personal, Firebase Auth only, never in Firestore
    - username and display name: personal, used to find and show members
    - uid: pseudonymous
    - deletion path: from the uid, `users/{uid}` leads to `usernames/{username}`. Deleting an account stays out of v1.
  - **Sign-out:** pop to the first route, then sign out. The cache wipe points to KI-3.
- **`SPEC.md`:** add KI-3 (the offline cache survives sign-out; fix before `households` caches private data).

**Acceptance criteria:**
- [x] SPEC-identity has no open question left, and every field has a class, a purpose and a deletion path
- [x] The rules section says exactly what Task 2 tests

**Verification:**
- [x] You read both diffs (docs only; merged in #12)

**Dependencies:** None (your answers are in)
**Files:** `.claude/specs/SPEC-identity.md`, `.claude/specs/SPEC.md`
**Scope:** XS

### Task 2: `users` and `usernames` rules, deny-tests first (AC-ID-9)

**Description:**
1. **Tests first.** Write `firebase/test/identity.test.js`, seeding existing docs with `withSecurityRulesDisabled`.
   - **Denied:**
     - every AC-ID-9 case
     - a `usernames` doc written without its `users` doc, and the reverse
     - a second username for an account that has one
     - an extra field on create
     - a 31-character or empty `displayName`
     - an id that's uppercase, 2 characters or contains `-`
     - an update by the owner that changes `username` or adds a field
     - A updating `users/B`'s `displayName`
     - `delete` on either collection
   - **Allowed:**
     - A claims `ana` in one batch that writes both docs
     - A changes their own `displayName`
     - A gets `usernames/bea` and `users/B`
     - a 30-character `displayName` made of accented letters and emoji. This checks that the rules' `size()` counts no more than Dart's `length`, so a name the app accepts is never refused by the rules
2. **Then the rules.** Add `match /usernames/{username}` and `match /users/{uid}` to `firestore.rules`, with `validUsername(u)` and `validDisplayName(s)` helpers.

**Acceptance criteria:**
- [x] Every deny and allow case above passes, and `foundation.test.js` stays green
- [x] Removing the `getAfter` condition from either create rule, or the `affectedKeys` check from the update rule, makes a test fail (then revert)

**Verification:**
- [x] `cd firebase && npm test`
- [x] The negative checks above, one at a time

**Dependencies:** Task 1
**Files:** `firebase/firestore.rules`, `firebase/test/identity.test.js`
**Scope:** M

### Task 3: Username and display-name parsing, profile model (AC-ID-6)

**Description:**
- **`lib/domain/username.dart`:**
  - `parseUsername(String input) → String?`: trim, lowercase, then the regex. `null` means invalid.
  - `parseDisplayName(String input, String username) → String?`: trim. Empty becomes `username`, and more than 30 characters gives `null`.
- **`lib/domain/models/user_profile.dart`:**
  - `AppUser(uid, email, displayName)`
  - `UserProfile(uid, username, displayName, householdId?)`
  - `UserProfile.fromMap(uid, Map?) → UserProfile?`: `null` when the username is missing or invalid, and the display name falls back to the username. Wrong types never throw.

**Acceptance criteria:**
- [x] `parseUsername` table:
  - `Dan_M` → `dan_m`
  - `" dan_m "` → `dan_m`
  - `abc` and a 20-character name are accepted
  - `ab`, a 21-character name, `dan m`, `dan-m`, `dañ` and `""` → `null`
- [x] `parseDisplayName` table:
  - `"  Ana María "` → `Ana María`
  - `"   "` → the username
  - 30 characters → accepted
  - 31 characters → `null`
- [x] `fromMap` table: a full map, a missing `displayName`, a missing or numeric `username` (→ `null`) and a `null` map (→ `null`)

**Verification:**
- [x] `flutter test test/domain/username_test.dart test/domain/user_profile_test.dart`
- [x] The gate is green

**Dependencies:** None
**Files:** `lib/domain/username.dart`, `lib/domain/models/user_profile.dart`, `test/domain/username_test.dart`, `test/domain/user_profile_test.dart`
**Scope:** S

### Task 4: `UserRepository` and the claim transaction (AC-ID-4, 5)

**Description:**
- Add `fake_cloud_firestore` as a dev dependency.
- `lib/data/repositories/user_repository.dart` implements the spec's interface:
  - `watchProfile`, `getProfile` and `uidForUsername`
  - `claimUsername`: one transaction. It reads `usernames/{u}`, throws `UsernameTaken` if the doc exists, and otherwise sets `usernames/{u} = {uid}` and `users/{uid} = {username, displayName}`.

**Acceptance criteria:**
- [x] Claiming `dan_m` writes exactly those two docs, with exactly those fields (AC-ID-4)
- [x] A second uid claiming `dan_m` throws `UsernameTaken`, and no doc changes (AC-ID-5)
- [x] `watchProfile` emits `null`, then the profile after the claim. `uidForUsername` returns `null` for an unknown name

**Verification:**
- [x] `flutter test test/data/user_repository_test.dart`
- [x] The gate is green, and `flutter pub get` prints no advisories

**Dependencies:** Task 3
**Files:** `pubspec.yaml`, `pubspec.lock`, `lib/data/repositories/user_repository.dart`, `test/data/user_repository_test.dart`
**Scope:** S

### Checkpoint 1
- [x] Tasks 1–4 verified, secret scans clean → REVIEW → you commit, open a PR, `flutter` and `rules` are green, you squash-merge (#12)

---

## Slice 2: `feat/identity-email`

### Task 5: `AuthRepository` with email sign-up, sign-in, sign-out and error mapping

**Description:**
- Add `firebase_auth_mocks` as a dev dependency.
- `lib/data/repositories/auth_repository.dart`:
  - `watchAuthUser` → `AppUser?`
  - `signUpWithEmail`: creates the user and, if a display name was given, sets it on the Auth user
  - `signInWithEmail` and `signOut`
  - Failures are thrown as `AuthException(AuthFailure)`. `failureFor(String code)` is a pure mapping: `invalidCredentials` (covering `invalid-credential`, `wrong-password` and `user-not-found`), `emailInUse`, `weakPassword`, `invalidEmail`, `tooManyRequests`, `network`, `accountExists`, `cancelled` and `unknown`.
  - Logs carry the code only.

Google sign-in and password reset come in Tasks 12–13.

**Acceptance criteria:**
- [x] A table test maps every code above, plus an unknown code → `unknown`
- [x] Sign-up with a display name sets it on the Auth user, and `watchAuthUser` emits the matching `AppUser`
- [x] A mocked `FirebaseAuthException` comes out as `AuthException`, with no raw message

**Verification:**
- [x] `flutter test test/data/auth_repository_test.dart`
- [x] The gate is green

**Dependencies:** Task 3
**Files:** `pubspec.yaml`, `pubspec.lock`, `lib/data/repositories/auth_repository.dart`, `test/data/auth_repository_test.dart`
**Scope:** S

### Task 6: Sign-in screen, email only (AC-ID-1, 2)

**Description:**
- **`SignInViewModel`:** a sign-in/sign-up mode, `busy` and `failure`.
- **`SignInScreen`:**
  - email and password fields, plus an optional display name in sign-up mode
  - checks before any call: the fields aren't empty, and the password meets the minimum at sign-up
  - each `AuthFailure` shows its localized message
- Every string goes in `app_en.arb` and `app_es.arb`.

**Acceptance criteria:**
- [x] A wrong password, an unknown email and a malformed email each show a localized message and stay on Sign-in. No error code appears (AC-ID-2)
- [x] A 5-character password at sign-up is refused before any call, and a 6-character one goes through
- [x] The screen renders in English and Spanish (AC-ID-10, this screen)

**Verification:**
- [x] `flutter test test/ui/auth/`
- [x] The gate is green

**Dependencies:** Task 5
**Files:** `lib/ui/auth/view_models/sign_in_view_model.dart`, `lib/ui/auth/widgets/sign_in_screen.dart`, `test/ui/auth/view_models/sign_in_view_model_test.dart`, `test/ui/auth/sign_in_screen_test.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` (plus the generated `app_localizations*.dart`)
**Scope:** M

### Task 7: Choose-username screen (AC-ID-4, 5, 6)

**Description:**
- **`ChooseUsernameViewModel(UserRepository, AppUser)`:**
  - a username field and a display name field, the display name prefilled from `AppUser.displayName`
  - `parseUsername` and `parseDisplayName` run before any call
  - `UsernameTaken` → "Username already taken"
  - a network error → "No connection"
- **`ChooseUsernameScreen`** with its arb strings.

**Acceptance criteria:**
- [x] `ab`, a 21-character name, `dan m` and `dan-m` show a validation message, and the fake records no write (AC-ID-6)
- [x] `Dan_M` stores `dan_m` (AC-ID-4)
- [x] A taken name shows "Username already taken" and changes nothing (AC-ID-5)
- [x] The display name is prefilled. When it's left empty, it's stored as the username
- [x] The screen renders in English and Spanish

**Verification:**
- [x] `flutter test test/ui/auth/`
- [x] The gate is green

**Dependencies:** Tasks 4, 6 (shared arb files)
**Files:** `lib/ui/auth/view_models/choose_username_view_model.dart`, `lib/ui/auth/widgets/choose_username_screen.dart`, `test/ui/auth/view_models/choose_username_view_model_test.dart`, `test/ui/auth/choose_username_screen_test.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`
**Scope:** M

### Task 8: Session, gate and provider wiring (AC-ID-1, 7)

**Description:**
- Add `provider`.
- **`SessionViewModel`:**
  - It listens to `watchAuthUser`, and for each uid to `watchProfile(uid)`, cancelling the previous profile subscription.
  - Its states are loading, signed out, needs username (`AppUser`), ready (`UserProfile`) and error.
  - `signOut()`.
- **`AuthGate`** shows, in order:
  - Sign-in
  - Choose-username
  - `AppShell`, keyed by uid
  - a generic error with a Sign out button
- **`lib/config/dependencies.dart`** registers `AuthRepository`, `UserRepository` and `SessionViewModel` above `MaterialApp`.
- **`main.dart`** wraps `FridgeApp` in a `MultiProvider`. `FridgeApp` takes `home`, `main` passes `AuthGate`, and the shell tests pass `AppShell`.

**Acceptance criteria:**
- [x] View model test: sign-up → needs username → claim → ready (AC-ID-1)
- [x] View model test: sign out → signed out → sign back in with a profile → ready, skipping Choose-username (AC-ID-7)
- [x] A profile stream error → the error state, with no crash. The shell tests still pass

**Verification:**
- [x] `flutter test`
- [x] The gate is green
- [x] `cd firebase && npm run emulators`, then the `web-emulator` launch config: sign up, claim a username, land in the shell. The Emulator UI shows the user, `users/{uid}` and `usernames/{name}` *(2026-11-20: flow works and both docs exist, but under the `fridge-food-managing` namespace, so the UI shows only the Auth user: [KI-4](../specs/SPEC.md#ki-4-the-apps-emulator-traffic-lands-under-the-prod-project-id))*

**Dependencies:** Tasks 6, 7
**Files:** `pubspec.yaml`, `pubspec.lock`, `lib/config/dependencies.dart`, `lib/ui/auth/view_models/session_view_model.dart`, `lib/ui/auth/widgets/auth_gate.dart`, `lib/main.dart`, `test/ui/auth/view_models/session_view_model_test.dart`, `test/ui/core/app_shell_test.dart`
**Scope:** M (two of the files are lockfile and test touch-ups)

### Task 9: KI-2, emulator runs on the phone

**Description:**
- Pass `automaticHostMapping: false` to `useAuthEmulator` and `useFirestoreEmulator`, and fix the comment.
- Update SPEC-app-foundation's "Passing `localhost` covers both" line and SPEC.md's Stage 1 line: use `localhost` everywhere, plus `adb reverse` on Android.
- Delete KI-2 from SPEC.md, and tick Stage 1's Emulator UI box with the evidence.

**Acceptance criteria:**
- [ ] With `adb reverse` on both ports, the phone's `flutter run -d A059 --dart-define=USE_EMULATOR=true` signs up and claims a username, visible in the Emulator UI
- [x] Web against the emulator still works (2026-11-20; docs land under the prod project id, see KI-4)

**Verification:**
- [ ] The manual run above, and the gate is green

**Dependencies:** Task 8
**Files:** `lib/main.dart`, `.claude/specs/SPEC-app-foundation.md`, `.claude/specs/SPEC.md`
**Scope:** XS

### Checkpoint 2
- [ ] Tasks 5–9 verified, secret scans clean
- [ ] Carried over from Stage 1: web in English, Spanish and a fallback language, in a narrow and a wide window; the phone launches into the app
- [ ] REVIEW → you commit, open a PR, CI is green, you squash-merge

---

## Slice 3: `feat/identity-account`

### Task 10: Account screen and sign-out (AC-ID-7)

**Description:**
- `lib/ui/auth/widgets/account_screen.dart` replaces `AccountPlaceholderScreen`. It keeps the title "Household & account" and has an account section with username, display name, email and a Sign out button.
- Sign out pops to the first route, then calls `SessionViewModel.signOut`.
- Remove the placeholder's string from both arb files.

**Acceptance criteria:**
- [ ] The screen shows the three values from the session
- [ ] Sign out leaves only Sign-in on screen, and signing back in goes straight to the shell (AC-ID-7)
- [ ] The screen renders in English and Spanish

**Verification:**
- [ ] `flutter test test/ui/`
- [ ] The gate is green

**Dependencies:** Task 8
**Files:** `lib/ui/auth/widgets/account_screen.dart`, `lib/ui/core/app_shell.dart`, `test/ui/auth/account_screen_test.dart`, `test/ui/core/app_shell_test.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`
**Scope:** M

### Task 11: Edit the display name (AC-ID-11)

**Description:**
- `UserRepository.updateDisplayName(uid, displayName)` updates that one field.
- `SessionViewModel.updateDisplayName(input)` runs `parseDisplayName` and then the repository.
- On the account screen, an edit button next to the display name opens a dialog:
  - the field is prefilled with the current name
  - validation shows inline, and Save is disabled while saving
- The profile stream refreshes the screen. No manual reload.

**Acceptance criteria:**
- [ ] Saving `"  Ana María "` stores `Ana María`, and an empty field stores the username
- [ ] 31 characters shows the validation message and writes nothing
- [ ] The update changes only `displayName`: the fake shows `username` untouched
- [ ] A 30-character name ends in "…" on the account screen at 360 px wide, with no overflow
- [ ] The dialog renders in English and Spanish

**Verification:**
- [ ] `flutter test test/data/ test/ui/auth/`
- [ ] The gate is green
- [ ] Manual, against the emulator: rename, and the Emulator UI shows the new `displayName` only

**Dependencies:** Task 10
**Files:** `lib/data/repositories/user_repository.dart`, `lib/ui/auth/view_models/session_view_model.dart`, `lib/ui/auth/widgets/account_screen.dart`, the matching tests, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`
**Scope:** M

### Task 12: Continue with Google (AC-ID-3)

**Description:**
- `AuthRepository.signInWithGoogle`: `signInWithPopup` on web, `signInWithProvider` on Android, both with `GoogleAuthProvider()`.
- A "Continue with Google" button on Sign-in. Cancelling the popup shows nothing.
- Choose-username already prefills the Google display name, through `AppUser`. A Google name longer than 30 characters shows the validation message, so the user shortens it.
- **Try the phone first**, since it's the riskiest part (see Risks).

**Acceptance criteria:**
- [ ] Mocked Google sign-in leads to needs username, with the display name prefilled
- [ ] The cancel codes show no message, and `account-exists-with-different-credential` shows its message
- [ ] Manual, against the emulator: the fake account chooser works on web and on the phone, and a first-time user lands on Choose-username with the name prefilled

**Verification:**
- [ ] `flutter test test/data/ test/ui/auth/`
- [ ] The gate is green
- [ ] The manual runs above

**Dependencies:** Task 10
**Files:** `lib/data/repositories/auth_repository.dart`, `lib/ui/auth/view_models/sign_in_view_model.dart`, `lib/ui/auth/widgets/sign_in_screen.dart`, the matching tests, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`
**Scope:** M

### Task 13: Forgot password (AC-ID-8)

**Description:**
- `AuthRepository.sendPasswordReset` swallows `user-not-found`.
- "Forgot password?" on Sign-in asks for the email and shows one confirmation for any well-formed email.

**Acceptance criteria:**
- [ ] A known and an unknown email show the identical confirmation. A malformed email shows the email error
- [ ] Manual: the reset link appears in the Auth emulator (Emulator UI or log)

**Verification:**
- [ ] `flutter test test/data/ test/ui/auth/`
- [ ] The gate is green
- [ ] The manual run above

**Dependencies:** Task 12 (same files)
**Files:** `lib/data/repositories/auth_repository.dart`, `lib/ui/auth/view_models/sign_in_view_model.dart`, `lib/ui/auth/widgets/sign_in_screen.dart`, the matching tests, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`
**Scope:** S

### Task 14: Seed profiles for ana and bea

**Description:**
- First, fix [KI-4](../specs/SPEC.md#ki-4-the-apps-emulator-traffic-lands-under-the-prod-project-id) with its recommended option: with `USE_EMULATOR`, `main.dart` initializes a named app with `projectId: 'demo-fridge'` and passes its Auth and Firestore instances to `providers(...)`. Without that, the app can't see the seed docs. Delete KI-4 in the same change.
- Add `users/{uid}` and `usernames/` docs for the seed accounts:
  - ana: uid `U2UNtJp7i9yw9P4zFTYcN9vHte3B`, username `ana`, display name `Ana`
  - bea: uid `aIBm7jR48E48EN07SelprAFalNrl`, username `bea`, display name `Bea`
- Re-export `firebase/seed/` and note the usernames in `firebase/README.md`.

**Acceptance criteria:**
- [ ] After `npm run emulators`, signing in as `ana@fridge.test` goes straight to the shell
- [ ] A new sign-up's `users/{uid}` and `usernames/{name}` show in the Emulator UI, on web and on the phone (KI-4)
- [ ] The account screen shows `@ana`
- [ ] A restart shows the same data and nothing else

**Verification:**
- [ ] The manual check above
- [ ] `npm test` is still green

**Dependencies:** Tasks 2, 10
**Files:** `lib/main.dart`, `.claude/specs/SPEC.md`, `firebase/seed/**`, `firebase/README.md`
**Scope:** S–M

### Checkpoint 3
- [ ] Tasks 10–14 verified, secret scans clean
- [ ] Manual, against the emulator:
  - Google on web and on the phone
  - the reset link
  - sign-out and back
  - editing the display name
  - every identity screen in English and Spanish
- [ ] REVIEW → you commit, open a PR, CI is green, you squash-merge

---

## Slice 4: `ci/release`

### Task 15: Release signing and the release workflow

**Description:**
1. **Specs first:**
   - **SPEC.md:**
     - module loop step 6, Release & rollback, and the "Automated deploy (later)" line
     - Boundaries: releases and rules deploys go through the approved `production` run, and manual deploys still ask first
     - Commands: the release steps
   - **`dev_rules.md`:**
     - §1: the workflow drafts the release after your approval, and you publish it
     - §7: the deploy wording, same as SPEC.md's Boundaries
     - §9 Secrets: the release keystore lives only in `production`, plus your backup
2. **`android/app/build.gradle.kts`:** a `release` signing config read from `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`) when that file exists. Otherwise it signs with the debug key, as today.
3. **`.github/workflows/release.yml`**, on `push: tags: ['v*']`, with top-level `permissions: contents: read` and one run per tag at a time:
   - **job `check`**, no environment: fail unless the tag equals `v` + pubspec's version without `+build`.
   - **job `release`**: `needs: check`, `environment: production`, `contents: write`. In order:
     1. checkout, Java 17, and Flutter from `pubspec.yaml`
     2. `pub get --enforce-lockfile`
     3. fail if `ANDROID_KEYSTORE_BASE64` is empty, decode it to `$RUNNER_TEMP/upload.jks`, and write `android/key.properties` with alias `upload`. A PKCS12 keystore uses one password for both, so it needs only `ANDROID_KEYSTORE_PASSWORD`
     4. `flutter build apk --release`
     5. print the signer SHA-256 with `apksigner verify --print-certs`
     6. `gh release create "$TAG" --draft --verify-tag --generate-notes`, attaching the APK renamed `fridge-food-managing-$TAG.apk`

     Task 16 inserts the rules deploy before the last step.
4. **Handoff:** the one-time setup commands for you:
   - `keytool -genkeypair` for the release key
   - its fingerprints
   - the password-manager backup
   - the `production` environment settings
   - `gh secret set … --env production`, reading the keystore from stdin so it's never pasted or echoed

**Acceptance criteria:**
- [ ] Local, with a throwaway keystore in the scratchpad and a temporary `key.properties`: the release APK's signer is the throwaway cert. Without the file it's the debug cert. The temporary file is deleted afterwards
- [ ] The `check` logic, run locally, passes `v0.2.0` and refuses `v0.2.1` while pubspec says `0.2.0+3`
- [ ] No step echoes a secret, and the empty-secret guard stops the build

**Verification:**
- [ ] The local builds above, checked with `apksigner verify --print-certs`
- [ ] The gate is green
- [ ] The full run is proven at Checkpoint 4

**Dependencies:** None in code (placed after Slice 3)
**Files:** `android/app/build.gradle.kts`, `.github/workflows/release.yml`, `.claude/specs/SPEC.md`, `.claude/dev_rules.md`
**Scope:** M

### Task 16: Rules deploy in the release run

**Description:**
- **SPEC.md first:**
  - Tech Stack: `google-github-actions/auth`, if WIF
  - Commands: the deploy now runs inside the release job
- **In `release`, between the build and the draft:**
  1. `google-github-actions/auth`, using the WIF provider and the service account. They're identifiers, not secrets, so they're set as environment variables
  2. Node from `firebase/.nvmrc`
  3. `npm ci` in `firebase/`
  4. `npx firebase deploy --project prod --only firestore:rules,firestore:indexes --non-interactive`
  - `id-token: write` on this job only.
- **Handoff:** the one-time Google Cloud commands for you:
  - a WIF pool and a GitHub provider, with the condition `assertion.repository == 'DanMau1410/fridge_food_managing' && assertion.environment == 'production'`
  - a `firebase-deploy` service account with only the rules and index admin roles
  - the binding between the two

**Acceptance criteria:**
- [ ] With WIF, the job's only Google credential comes from OIDC: no key file or token in any secret
- [ ] The deploy runs only after a successful build and before the draft, so a failed deploy creates no draft

**Verification:**
- [ ] At Checkpoint 4: the deploy step is green, and the Firebase console's Rules tab shows a new version at that time

**Dependencies:** Task 15, your Google Cloud setup
**Files:** `.github/workflows/release.yml`, `.claude/specs/SPEC.md`, `firebase/README.md`
**Scope:** S

### Task 17: Stage close

**Description:**
- **Version:** `0.2.0+3`.
- **Dependency review:**
  - Drop `cupertino_icons` (deferred finding).
  - Run `flutter pub outdated` and `cd firebase && npm audit`, triage the results, and update the deferred findings.
- **Security:** walk the checklist over `git diff main...dev`, and run both secret scans.
- **Specs:** tick SPEC-identity's ACs, with the evidence, in the spec.
- **REVIEW:**
  - the Slice 4 summary
  - the `dev` → `main` PR draft, with a rollback note
  - the `v0.2.0` annotated-tag and push commands
  - the release steps: approve the run, check the signer SHA-256, install the APK, sign in against `prod`, publish

**Acceptance criteria:**
- [ ] `docker compose run --rm test` is green
- [ ] Every git and GitHub step is a command for you to run. I run none of them

**Verification:**
- [ ] `docker compose build test && docker compose run --rm test`
- [ ] `cd firebase && npm test`

**Dependencies:** Tasks 14–16
**Files:** `pubspec.yaml`, `pubspec.lock`, `.claude/specs/SPEC.md`, `.claude/specs/SPEC-identity.md`, `.claude/specs/REVIEW.md`, `.claude/tasks/plan.md`, `.claude/tasks/todo.md`
**Scope:** S

### Checkpoint 4: Stage 2 done
- [ ] Slice 4 PR squash-merged, both CI jobs green
- [ ] You merge `dev` → `main` with a merge commit, tag `v0.2.0` and push the tag
- [ ] `check` passes. You approve the `production` run, and it deploys the rules and drafts the release
- [ ] Before publishing:
  - the logged signer SHA-256 is your release key's
  - the APK installs on the phone
  - email and Google sign-in work against `prod`

  Then you publish.
- [ ] Next: plan `households` (Stage 3), only when you ask

---

## Deferred findings

Carried over from Stage 1:
- **`npm audit` in `firebase/`: 24 findings (14 moderate, 10 high)**, all in the dev-only emulator test tooling. npm's "fixes" are major downgrades. **Review:** Task 17.
- **`cupertino_icons` 2.0.0 (major):** a template dependency the app doesn't use. **Review:** Task 17 drops it.
- **`vector_math`, `vm_service`, `test_api`, `material_color_utilities`:** pinned by the Flutter SDK. They move with a Flutter bump.
- **`IndexedStack` builds all three tabs at launch.** **Review:** when planning `inventory`, before tabs open Firestore listeners.

New in Stage 2:
- **KI-3: the offline cache survives sign-out** (deferred by you, 2026-11-19). **Review:** when planning `households`, before household data is cached.
