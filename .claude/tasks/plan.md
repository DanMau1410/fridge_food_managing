# Implementation Plan: Stage 2, `identity`

> Source: [SPEC-identity.md](../specs/SPEC-identity.md), [SPEC.md › Module loop](../specs/SPEC.md#stages-28-module-loop) · Status: **approved 2026-11-19**
> Tasks: [todo.md](todo.md) · Stage 1's plan is in git history (tag `v0.1.0`). Its last open items, the manual web and phone checks, move to Checkpoint 2 here.

## Overview

People get their own accounts. The flow is:
1. sign up or sign in, with email and password or with Google
2. claim a unique, permanent username
3. land in the shell

The account screen shows who you are, lets you change your display name, and lets you sign out. Firestore rules make the username a real lock: one account gets one name, the name can't be taken from its owner, and the name can't change later.

Releases become a tag push plus one approval. A workflow in the GitHub `production` environment builds and signs the APK, deploys the rules and drafts the release, and you publish it.

The work is four slices, each squash-merged into `dev`:
- three `feat/identity-*` slices
- `ci/release`

The stage ends with a merge of `dev` → `main`, the tag `v0.2.0`, and the first approved release run.

## Starting point (verified 2026-11-19)

- **Git:** `dev` = `origin/dev` at `3f91f59` (#10). `main` is at `239fa76`, tagged `v0.1.0`. The version is `0.1.0+2`. The only uncommitted changes are Stage 1's last ticks in these two files, which this plan replaces.
- **Firebase packages:**
  - `firebase_core` 5.2.0, `firebase_auth` 7.1.0, `cloud_firestore` 7.2.0
  - Both `useAuthEmulator` and `useFirestoreEmulator` take `automaticHostMapping`, so the KI-2 fix is available.
- **New packages, all already listed in SPEC.md's Tech Stack** (dry run, 2026-11-19):
  - `provider` 6.1.5+1, `fake_cloud_firestore` 4.5.0 and `firebase_auth_mocks` 0.16.0
  - They resolve with no downgrades.
  - The mocks support `signInWithPopup`, `signInWithProvider`, `sendPasswordResetEmail` and `updateDisplayName`.
- **Rules:** default deny, with `signedIn()` and a stub `isMember()`.
- **Seed:** the Auth users ana and bea, with no Firestore documents yet.
- **App:**
  - `FridgeApp` has `home: AppShell`, and the shell tests pump `FridgeApp` directly.
  - The account action opens `AccountPlaceholderScreen`.
- **Signing:**
  - Release builds are signed with this machine's debug key, `~/.config/.android/debug.keystore` (Flutter's template TODO).
  - No release key exists, and no SHA is registered in Firebase (`google-services.json` has no `certificate_hash`).
  - No APK is attached to `v0.0.0` or `v0.1.0`, so moving to a release key costs nothing.
- **GitHub:**
  - The repo is public, so an environment with required reviewers works on the free plan.
  - No environments and no secrets exist yet.
  - CI builds web only.
- **Not verified in Stage 1:**
  - the manual web and phone checks
  - the Emulator UI half of AC-AF-3 (it needs a first sign-up)

  Both land at Checkpoint 2.

## Architecture decisions

- **Slices run in risk order.**
  1. The username lock: every identity rule, plus the domain code and the repository, with no UI. The rules are the only server-side boundary, so they come first.
  2. The email flow: sign up → choose a username → shell, plus the gate, the providers and the KI-2 fix.
  3. Everything around it: the account screen, sign-out, editing the display name, Google sign-in, password reset and the seed.
  4. The release pipeline and the stage close. It's independent of Slices 1–3 and could move earlier if you want to try it sooner.
- **The two docs lock each other in the rules.**
  - `usernames/{u}` create requires `getAfter(users/uid).username == u`.
  - `users/{uid}` create requires `getAfter(usernames/{username}).uid == uid`.
  - So neither doc can be written alone, and names can't be squatted. Because a username can never change on update, a second name for the same account is refused too.
  - A `!exists(users/uid)` check was tried and dropped: no test fails without it.
- **`users/{uid}` updates: the owner only, and only `displayName`.**
  - The rule checks `diff(resource.data).affectedKeys().hasOnly(['displayName'])`, so it keeps working when `households` adds `householdId` with its own update path.
  - `delete` is denied.
- **Shape checks, on top of the spec's rules:**
  - `users`: exactly `username` and `displayName`. `displayName` is a string of 1–30 characters.
  - `usernames`: exactly `uid`.
  - The id regex is checked in the rules too, so an uppercase or 2-character id written straight to Firestore fails.
- **Usernames:** the input is trimmed, then lowercased, then checked against `^[a-z0-9_]{3,20}$`. (The spec says lowercase only; Task 1 adds the trim.)
- **Passwords:** Firebase's default minimum, 6 characters (your answer, 2026-11-19). The app checks it at sign-up, so the message is localized and shows before any call. The console's password policy stays as it is.
- **Display names (your answer, 2026-11-19):**
  - trimmed; empty becomes the username
  - 1–30 characters, any characters, not unique
  - set at Choose-username, prefilled from Google or the sign-up field
  - changeable any time from the account screen (new AC-ID-11)
- **Domain models parse `(id, Map)`, not snapshots, so `lib/domain/` keeps no Firebase imports.**
  - A doc with a missing or invalid `username` is "no profile", never a crash.
  - A missing `displayName` falls back to the username.
- **Auth errors map to a small `AuthFailure` enum**, and each value has one localized message.
  - `invalid-credential`, `wrong-password` and `user-not-found` share one message, "Email or password is incorrect", so sign-in doesn't reveal whether an account exists.
  - Closing the Google popup shows nothing.
  - Logs get the error code only, never the email.
- **Password reset shows the same confirmation whether or not the email has an account.** `user-not-found` is swallowed. Only a malformed email or a network error shows an error (AC-ID-8).
- **`SessionViewModel` sits above `MaterialApp`, in `dependencies.dart`.**
  - It listens to the auth user, then to that uid's profile. Its states are loading, signed out, needs username, ready and error.
  - It also handles sign-out and the display-name change.
  - `AuthGate` only switches screens.
  - It sits above `MaterialApp` because routes pushed from the shell, like the account screen, aren't descendants of the gate. Placed there, they can still read the current profile.
  - The shell is keyed by uid, so a different account gets fresh state.
  - No `rxdart`: the profile subscription is cancelled by hand when the uid changes.
- **After the username, the gate goes straight to `AppShell`.** Stage 3 inserts the household gate in between.
- **`FridgeApp` takes a `home` parameter.**
  - `main` passes `AuthGate`.
  - The shell tests keep pumping `FridgeApp(home: AppShell())`, with no Firebase.
- **Test approach:**
  - View model and widget tests run the real repositories over `MockFirebaseAuth` and `FakeFirebaseFirestore`, with no hand-written fakes.
  - Error mapping is a table test of a pure function.
  - The fakes don't enforce rules. Only `firebase/test/identity.test.js` proves the rules.
- **The KI-2 fix lands in Slice 2, with the first Firebase calls.**
  - Pass `automaticHostMapping: false` to both emulator calls.
  - On any Android device (the phone or an AVD), forward the ports with `adb reverse tcp:9099 tcp:9099` and `adb reverse tcp:8085 tcp:8085`.
  - Both spec lines change, and KI-2 is deleted.
- **Sign-out pops back to the first route, then signs out**, so the account screen doesn't stay on top of Sign-in.
- **Offline cache on sign-out: deferred (your answer, 2026-11-19).**
  - In Stage 2, the device caches only `users/` and `usernames/` docs, which any signed-in user can read anyway.
  - The wipe (`terminate` + `clearPersistence`) needs a spike on web and Android. It's recorded as KI-3, to be fixed before `households` caches private data.
- **The release key lives only in the GitHub `production` environment, plus your offline backup** (your design, 2026-11-19).
  - Its required reviewer is you, and it only runs on `main` and `v*` refs.
  - `build.gradle.kts` signs release builds from a gitignored `android/key.properties` when that file exists (Flutter's documented setup). Otherwise it uses the debug key, as today, so local release runs, Docker and CI keep working without the key.
- **`release.yml` runs on `v*` tag pushes, in two jobs.**
  1. `check`, with no environment: the tag must equal `v` + pubspec's version (`v0.2.0` ↔ `0.2.0+3`). A mistyped tag fails here and never asks for your approval.
  2. `release`, in `production`: one approval covers the whole job. In order:
     1. decode the keystore, build and sign the APK, and print its signer SHA-256
     2. deploy the rules and indexes to `prod`
     3. create a **draft** release with the APK

     The side effects run last, so a failed build deploys and drafts nothing. You publish the draft.
- **The approval click is the "ask first" for releases and rules deploys.** Task 15 updates SPEC.md's Boundaries and DevOps sections and `dev_rules.md` §1, §7 and §9 to say so. Manual deploys still ask first.
- **Deploy credentials: Workload Identity Federation** (your answer, 2026-11-19).
  - Google trusts only this repo's `production` jobs.
  - The deploy identity can change only rules and indexes.
  - No Google key exists anywhere.
- **Version:** `0.2.0+3` at the end of the stage, tagged `v0.2.0`.

## Task list

The details are in [todo.md](todo.md). Gate = `dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test && flutter build web --release`, plus `cd firebase && npm test` when the rules change.

### Slice 1: `feat/identity-claim`, the username lock (no UI)
- [x] Task 1: Spec answers and data classification
- [x] Task 2: `users` and `usernames` rules, deny-tests first (AC-ID-9)
- [x] Task 3: Username and display-name parsing, profile model (AC-ID-6)
- [x] Task 4: `UserRepository` and the claim transaction (AC-ID-4, 5)

Task 2 (rules, JS) and Tasks 3–4 (Dart) are independent of each other.

**Security:**
- **Boundary:** Firestore rules for `users` and `usernames`. They're the only server-side control.
- **Worth attacking:**
  - taking someone else's username
  - holding several usernames
  - renaming yourself later
  - writing or renaming another user's profile
  - sneaking other fields (`username`, `householdId`, an admin flag) in through the display-name update
  - listing every user
- **Abuse cases, tested first:**
  - `usernames/x` with another uid
  - a `usernames` doc without the matching `users` doc (squatting)
  - a second name for an account that already has one
  - overwriting or deleting `usernames/x`
  - A writing or updating `users/B`
  - an update that touches anything but `displayName`
  - an extra field, a 31-character or empty display name, an uppercase or 2-character id written directly
  - listing either collection
  - an unauthenticated `get`
- **Residual, by design:** any signed-in user can check whether a username exists and read that user's display name. Invites need that.

**Checkpoint 1:**
- [x] The gate and `cd firebase && npm test` are green
- [x] REVIEW written → you commit, open a PR, `flutter` and `rules` are green, you squash-merge (#12, with the `.gitignore` cleanup)

### Slice 2: `feat/identity-email`, sign up → choose a username → shell
- [x] Task 5: `AuthRepository` with email sign-up, sign-in, sign-out and error mapping
- [x] Task 6: Sign-in screen, email only (AC-ID-1, 2)
- [x] Task 7: Choose-username screen (AC-ID-4, 5, 6)
- [x] Task 8: Session, gate and provider wiring (AC-ID-1, 7)
- [ ] Task 9: KI-2, emulator runs on the phone

**Security:**
- **Boundaries:** user input (email, password, username, display name) and Firebase Auth errors.
- **Worth attacking:**
  - finding out whether an email has an account
  - raw error codes or emails reaching the screen or the logs
  - a username that skips the client check (Slice 1's rules still reject it)
- **Abuse cases, tested first:**
  - every Auth error code shows one localized message, with no code in it
  - a wrong password and an unknown email show the same message
  - a username that fails the regex never reaches the repository (the fake records no write)
- **Emulator access:** `adb reverse` over USB. The emulators stay on `localhost`, never `0.0.0.0`.

**Checkpoint 2:**
- [ ] The gate is green
- [ ] Web against the emulator: sign up → Choose-username → shell, and the Emulator UI shows the Auth user plus both docs (AC-ID-1, AC-AF-3)
- [ ] The same on the phone, over `adb reverse`
- [ ] Carried over from Stage 1: web in English, Spanish and a fallback language, in a narrow and a wide window
- [ ] REVIEW written → you commit, open a PR, CI is green, you squash-merge

### Slice 3: `feat/identity-account`, account, Google, reset, seed
- [ ] Task 10: Account screen and sign-out (AC-ID-7)
- [ ] Task 11: Edit the display name (AC-ID-11)
- [ ] Task 12: Continue with Google (AC-ID-3)
- [ ] Task 13: Forgot password (AC-ID-8)
- [ ] Task 14: Seed profiles for ana and bea, after fixing KI-4 (emulator project id)

**Security:**
- **Boundaries:** Google OAuth (the web popup and Android's provider flow), password reset, sign-out, and the display-name update.
- **Worth attacking:**
  - a reset that reveals whether an account exists
  - the previous user's profile or screens surviving sign-out
  - a Google account colliding with a password account that has the same email
  - a display name that breaks layouts
- **Abuse cases, tested first:**
  - a reset for an unknown email shows the same confirmation as for a known one
  - after sign-out, only Sign-in is on screen and nothing holds the old profile
  - `account-exists-with-different-credential` shows a localized message
  - a display-name save writes only `displayName`
  - a 30-character name ends in "…" in narrow places instead of overflowing

  Names render only through `Text`.
- **Seed:** made-up data, emulator only.

**Checkpoint 3:**
- [ ] The gate is green
- [ ] Manual checks against the emulator:
  - Google on web and on the phone
  - the reset link in the Auth emulator
  - sign-out and sign back in
  - editing the display name
  - every identity screen in English and Spanish
- [ ] REVIEW written → you commit, open a PR, CI is green, you squash-merge

### Slice 4: `ci/release`, release pipeline and stage close
- [ ] Task 15: Release signing and the release workflow
- [ ] Task 16: Rules deploy in the release run
- [ ] Task 17: Stage close: version `0.2.0+3`, dependency and security review, spec ticks, stage PR, tag and release steps

**Security:**
- **Boundaries:** GitHub Actions secrets, the `production` environment, a public repo's public logs, and Google Cloud IAM.
- **Worth attacking:**
  - getting the keystore or deploy rights from a fork PR, a branch push or a workflow edit
  - a mistyped tag shipping the wrong commit
  - secrets leaking into public logs
  - a release APK quietly signed with the debug key
- **Controls, checked in the review:**
  - The secrets exist only in `production`, never at repo level. Fork PRs and branch pushes can't reach them.
  - WIF trusts only `production` jobs from this repo, so no long-lived Google key exists.
  - `check` refuses a tag that doesn't match pubspec's version.
  - The build fails when the keystore secret is empty, instead of falling back to the debug key.
  - Secrets are decoded straight to files in `$RUNNER_TEMP` and never echoed.
  - Only the `release` job gets `contents: write` and `id-token: write`.
  - The log prints the APK's signer SHA-256, so you can compare it before publishing.
- **Residual:** anyone who can push to `main` or push tags could edit the workflow and wait for your approval. Today that's only you, so read what you approve.
- **Stage close:**
  - both secret scans
  - `flutter pub outdated` and `npm audit`, triaged
  - the security checklist walked over `git diff main...dev`

**Checkpoint 4: Stage 2 done:**
- [ ] The gate, `npm test`, `docker compose run --rm test` and both CI jobs are green
- [ ] You merge `dev` → `main`, tag `v0.2.0` and push the tag
- [ ] `check` passes. You approve the `production` run, and it builds, deploys the rules and drafts the release
- [ ] Before publishing:
  - the logged signer SHA-256 is your release key's
  - the APK installs on the phone
  - email and Google sign-in work against `prod`

  Then you publish.

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| The rules' `getAfter` cross-check is subtle | High: a hole means stolen or squatted usernames | Deny-tests are written first, including "one doc alone" and "second name". The negative check drops one condition and watches a test fail |
| Losing the release key | High: installed APKs can't be updated, only uninstalled and reinstalled | The `.jks` file and its password go into your password manager before they go into GitHub. GitHub secrets can't be read back |
| Android `signInWithProvider` against the Auth emulator may not finish (the browser tab must reach `localhost:9099`) | Med: AC-ID-3 can't be checked on the phone | Task 12 tries it first. If it fails, Android Google is checked against `prod` at release, and the spec's fallback is the `google_sign_in` package (ask first) |
| The release workflow is only fully exercised by a real tag | Med | Gradle signing is checked locally with a throwaway keystore first. The real run makes only a draft, which you inspect before publishing. A failed run is re-run from the Actions page for the same tag |
| firebase-tools doesn't pick up the WIF credentials | Med: the deploy step fails | The deploy runs before the draft, so a failure leaves nothing half-released. Fix and re-run. A service-account key secret is the fallback (ask first) |
| "Prevent self-review" on the environment | Med: as the only reviewer, you'd be locked out of your own releases | Leave it off. The setup steps say so |
| The mocks don't reproduce real error codes or stream timing | Low | Error mapping is a pure table test. The mocks only drive the flows. The manual runs use the real emulator |
| Email enumeration protection changes the codes (`invalid-credential`) | Low | All three "wrong credentials" codes map to one message |
| The same email arrives through Google and through a password | Low | `account-exists-with-different-credential` gets a message. For Gmail addresses, Firebase can replace an unverified password account with the Google sign-in; that's Firebase's own behavior, and the spec notes it |
| Claiming a username while offline (transactions need a connection) | Low | A "No connection" message, and the user can retry |

## Prerequisites (you)

1. **Each time the phone reconnects (Slice 2 on):** run `adb reverse tcp:9099 tcp:9099` and `adb reverse tcp:8085 tcp:8085`.
2. **Before Checkpoint 4 (one-time setup).** Tasks 15 and 16 hand over the exact commands.
   - **Keystore:** create the release keystore on your machine, note its SHA-1 and SHA-256, and back up the file and its password in your password manager.
   - **GitHub:**
     - environment `production`, with you as the required reviewer and "Prevent self-review" **off**
     - deployment refs `main` and tags `v*`
     - the secrets `ANDROID_KEYSTORE_BASE64` and `ANDROID_KEYSTORE_PASSWORD`, set in that environment only
   - **Google Cloud:** the WIF pool and provider, and a deploy service account limited to rules and indexes.
   - **Firebase console:**
     - enable the Email/Password and Google providers, with a support email for Google
     - register the debug SHA-1/SHA-256 and the release key's
     - confirm email enumeration protection is on

     `keytool -list -v -keystore ~/.config/.android/debug.keystore -alias androiddebugkey -storepass android` prints the debug fingerprints.

   The emulator needs none of this.

## Open questions

1. ~~**Minimum password length**~~: answered 2026-11-19. Firebase's default, 6 characters. AC-ID-1 keeps "≥ 6-char".
2. ~~**Display name rule**~~: answered 2026-11-19. 1–30 characters, and users can change it from the account screen.
3. ~~**Offline cache on sign-out**~~: answered 2026-11-19. Deferred to `households` as KI-3.
4. ~~**Release signing**~~: answered 2026-11-19. The key lives only in the `production` environment, and you approve each release run.
5. ~~**Deploy credentials for the rules**~~: answered 2026-11-19. Workload Identity Federation.

All questions are answered. The plan was approved on 2026-11-19.
