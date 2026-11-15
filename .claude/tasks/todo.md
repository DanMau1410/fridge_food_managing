# Stage 1 Tasks: `app-foundation`

> Plan: [plan.md](plan.md) · Spec: [SPEC-app-foundation.md](../specs/SPEC-app-foundation.md) · Gate = `dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test && flutter build web --release`

---

## Slice 1: `feat/app-foundation-firebase`

> Before Task 1 (you): `git switch -c feat/app-foundation-firebase dev`. The uncommitted FlutterFire files and spec edits come along.

### Task 1: Android debug build with FlutterFire's Gradle setup

**Description:** Build a debug APK with the uncommitted FlutterFire changes: the Google Services plugin 4.3.15 on AGP 9.1, plus `google-services.json`. If the build fails because of the plugin, bump it to 4.6.0 in `android/settings.gradle.kts`. Keep FlutterFire's generated files as they are.

**Acceptance criteria:**
- [x] `flutter build apk --debug` succeeds
- [x] `flutter build web --release` still succeeds
- [x] The plugin version that works is recorded in REVIEW (4.3.15 kept, or 4.6.0 with the error that forced it)

**Verification:**
- [x] `flutter build apk --debug && flutter build web --release`
- [x] The gate is green

**Dependencies:** None
**Files:** `android/settings.gradle.kts` (only if bumped), plus the FlutterFire files already present: `android/app/build.gradle.kts`, `android/app/google-services.json`, `lib/firebase_options.dart`, `firebase.json`
**Scope:** S

### Task 2: Initialize Firebase, emulator switch, web persistence

**Description:** Add `firebase_auth` and `cloud_firestore` (both approved in the spec's Tech Stack). In `main.dart`:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
3. On web, turn on Firestore persistence.
4. If `USE_EMULATOR`, point Auth at `host:9099` and Firestore at `host:8085`, with `host` = `localhost` on web and `10.0.2.2` on Android, and `debugPrint` the host.
5. Run the existing template app (the shell comes in Slice 4).

Also update SPEC-app-foundation's scope: `dependencies.dart` moves to `identity`.

**Acceptance criteria:**
- [x] With `--dart-define=USE_EMULATOR=true`, startup logs the emulator host and the app renders with no console errors
- [x] Without the flag, there's no emulator log, the app uses the production options, and it renders with no errors
- [x] `flutter test` still passes (widget tests don't initialize Firebase)

**Verification:**
- [x] The gate is green
- [x] `flutter run -d web-server --web-port 8080 --dart-define=USE_EMULATOR=true`, then open http://localhost:8080: the app renders, the browser console is clean, and the terminal shows the emulator log. Repeat without the flag.

**Dependencies:** Task 1
**Files:** `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, `.claude/specs/SPEC-app-foundation.md`
**Scope:** S

### Checkpoint 1
- [x] Tasks 1–2 verified, and `git status` shows only the intended files
- [ ] REVIEW written → you commit, open a PR into `dev`, CI is green, you squash-merge

---

## Slice 2: `feat/app-foundation-emulator` (needs JDK 21)

### Task 3: `firebase/` project with default-deny rules and the AC-AF-8 test

**Description:** Create the `firebase/` folder:
- `firebase.json`: emulators Auth on 9099, Firestore on 8085, UI on 4000; points to the rules and indexes files
- `.firebaserc`: default `demo-fridge`, alias `prod` = `fridge-food-managing`
- `firestore.rules`: `rules_version = '2'`, helpers `signedIn()` and an `isMember(hid)` stub that returns `false`, and no `allow` anywhere, so everything is denied
- an empty `firestore.indexes.json`
- `package.json` + `package-lock.json`: devDependencies `firebase-tools`, `@firebase/rules-unit-testing`, `firebase`; `test` = `firebase emulators:exec --only firestore "node --test test/"`
- `.nvmrc` = `26`
- `test/foundation.test.js`: AC-AF-8

Also:
- Add `firebase/node_modules/` to `.gitignore` and `.dockerignore`.
- Change the spec's deploy command to `--project prod`.

**Acceptance criteria:**
- [ ] `cd firebase && npm ci && npm test` passes, with four denied cases: unauthenticated read, unauthenticated write, authenticated read and authenticated write to `/anything/x`
- [ ] Temporarily adding `allow read: if true;` makes the test fail (then revert)
- [ ] A bare `npx firebase use` inside `firebase/` reports `demo-fridge`

**Verification:**
- [ ] `cd firebase && npm ci && npm test`
- [ ] The negative check above

**Dependencies:** JDK 21 (you)
**Files:** `firebase/firebase.json`, `firebase/.firebaserc`, `firebase/firestore.rules`, `firebase/firestore.indexes.json`, `firebase/package.json`, `firebase/package-lock.json`, `firebase/.nvmrc`, `firebase/test/foundation.test.js`, `.gitignore`, `.dockerignore`, `.claude/specs/SPEC.md`
**Scope:** M (mostly one-line config files)

### Task 4: CI job `rules`

**Description:** Add job `rules` to `ci.yml`, with the same triggers and token permissions:
- `actions/checkout@v7`
- `actions/setup-node` (`node-version-file: firebase/.nvmrc`, npm cache keyed on `firebase/package-lock.json`)
- `actions/setup-java` (Temurin 21)
- `npm ci` and `npm test`, run in `firebase/`

**Acceptance criteria:**
- [ ] The job `rules` runs next to `flutter` on the PR and is green
- [ ] No Node or Java version is hard-coded except Java 21

**Verification:**
- [ ] The PR's checks show `flutter` and `rules` both green
- [ ] Local equivalent: Task 3's commands

**Dependencies:** Task 3
**Files:** `.github/workflows/ci.yml`
**Scope:** XS

### Task 5: Seed two Auth users, plus `npm run emulators`

**Description:**
1. Start the emulators.
2. Create two test accounts through the Auth emulator's REST API (emulator only, never production).
3. Export them to `firebase/seed/`.
4. Add the script `emulators` = `firebase emulators:start --only auth,firestore --import=seed`. It imports only, so dev data never leaks into the seed.

The test emails and password go in a 3-line `firebase/seed/README.md`.

**Acceptance criteria:**
- [ ] `cd firebase && npm run emulators`, then open http://localhost:4000 → Authentication: both users are listed
- [ ] Restarting the emulators shows the same two users and nothing else

**Verification:**
- [ ] The manual check above
- [ ] `npm test` is still green

**Dependencies:** Task 3
**Files:** `firebase/seed/**` (the export), `firebase/seed/README.md`, `firebase/package.json`
**Scope:** S

### Checkpoint 2
- [ ] Tasks 3–5 verified → REVIEW → you commit, open a PR, `flutter` and `rules` are green, you squash-merge
- [ ] You add `rules` as a required check in rulesets `Dev PR` and `Main PR`

---

## Slice 3: `feat/app-foundation-domain`

### Task 6: `itemKey` and date keys

**Description:** Write two pure functions, each with a table test:
- `lib/domain/item_key.dart`: trim, lowercase, collapse inner whitespace, strip Latin accents with a small map. A blank input returns `''`, which callers must reject.
- `lib/domain/date_key.dart`: `toDateKey(DateTime)` → `yyyy-MM-dd`, and `fromDateKey(String)` → a local date. A malformed key throws a `FormatException`.

**Acceptance criteria:**
- [ ] AC-AF-4's table passes, plus `ñ`, `ü` and `ç` cases
- [ ] AC-AF-7 round-trips, and a malformed key throws

**Verification:**
- [ ] `flutter test test/domain/item_key_test.dart test/domain/date_key_test.dart`
- [ ] The gate is green

**Dependencies:** None (can run in parallel with Slice 2)
**Files:** `lib/domain/item_key.dart`, `lib/domain/date_key.dart`, `test/domain/item_key_test.dart`, `test/domain/date_key_test.dart`
**Scope:** S

### Task 7: `FoodCategory`, `StorageLocation`, `Unit`, `Quantity`

**Description:**
- `FoodCategory` is an enum carrying `healthy`, `defaultLocation` and `defaultShelfLifeDays` (`int?`), straight from the spec table, with fruit → cabinet.
- `StorageLocation` is an enum.
- Each `Unit` has a dimension (count, mass or volume) and a base factor.
- `Quantity` has `amount` and `unit`, `convertTo(Unit) → Quantity?`, `+`/`-` within a dimension, and a comparison returning `int?` (`null` = not comparable).

**Acceptance criteria:**
- [ ] AC-AF-5's table passes, using `closeTo` for doubles
- [ ] All 13 categories are asserted against the spec table: healthy flag, location, shelf life

**Verification:**
- [ ] `flutter test test/domain/`
- [ ] The gate is green

**Dependencies:** None
**Files:** `lib/domain/models/food_category.dart`, `lib/domain/models/storage_location.dart`, `lib/domain/models/unit.dart` (`Unit` + `Quantity`), `test/domain/units_test.dart`, `test/domain/food_category_test.dart`
**Scope:** M

### Checkpoint 3
- [ ] Tasks 6–7 verified → REVIEW → you commit, open a PR, CI is green, you squash-merge

---

## Slice 4: `feat/app-foundation-shell`

### Task 8: Localization setup and enum labels

**Description:**
- Add `flutter_localizations` (sdk) and `intl`, plus `generate: true`.
- Add `l10n.yaml` (`arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `format: true`).
- Write `app_en.arb` and `app_es.arb` with the shell strings and every enum label (13 categories, 3 locations, 8 units).
- Add `lib/ui/core/labels.dart` to map each enum value to its localized label.
- Commit the generated files.

**Acceptance criteria:**
- [ ] Every `FoodCategory`, `StorageLocation` and `Unit` value has a non-empty label in both English and Spanish (AC-AF-6, labels part)
- [ ] Spot checks: `fruit` → "Fruit"/"Fruta", `cabinet` → "Cabinet"/"Despensa"
- [ ] The format check passes on the generated files

**Verification:**
- [ ] `flutter test test/ui/core/labels_test.dart`
- [ ] The gate is green

**Dependencies:** Task 7
**Files:** `pubspec.yaml`, `pubspec.lock`, `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_localizations*.dart` (generated), `lib/ui/core/labels.dart`, `test/ui/core/labels_test.dart`
**Scope:** M

### Task 9: App shell and theme, replacing the template

**Description:**
- `lib/ui/core/theme.dart`: Material 3, teal seed, light and dark following the system.
- `lib/ui/core/app_shell.dart`:
  - Food, Groceries and Recipes destinations in an `IndexedStack`, so each tab keeps its state
  - a `NavigationBar` below 840 px wide and a `NavigationRail` at 840 px or wider
  - an app-bar action that opens a placeholder Household & account screen
  - a localized empty placeholder on each destination
- `main.dart`: `MaterialApp` with the theme, localization delegates, English first in `supportedLocales` (so unsupported languages fall back to English), and `home: AppShell`.
- Delete `FridgePage` and `test/widget_test.dart`.

**Acceptance criteria:**
- [ ] AC-AF-1 in tests: the labels appear in English, in Spanish, and in English under `fr`
- [ ] AC-AF-2 in tests: 600 px → `NavigationBar`, 1000 px → `NavigationRail`, and switching tabs keeps the others mounted
- [ ] The account action opens the placeholder and back returns to the shell

**Verification:**
- [ ] `flutter test test/ui/core/app_shell_test.dart`
- [ ] The gate is green
- [ ] Manual: a `web-server` run in a narrow and a wide browser window, and with the browser language set to Spanish

**Dependencies:** Task 8, Task 2
**Files:** `lib/ui/core/theme.dart`, `lib/ui/core/app_shell.dart`, `lib/main.dart`, `test/ui/core/app_shell_test.dart`, `test/widget_test.dart` (deleted)
**Scope:** M

### Task 10: Stage close

**Description:**
- Set `version: 0.1.0+2`.
- Tick Stage 1's acceptance boxes in SPEC.md, citing the evidence.
- REVIEW gets the Slice 4 summary, plus the draft `dev` → `main` PR (with a rollback note) and the `v0.1.0` annotated-tag commands.

**Acceptance criteria:**
- [ ] `docker compose run --rm test` is green (AC-AF-9)
- [ ] Every git and GitHub step is a command for you to run. I run none of them

**Verification:**
- [ ] `docker compose build test && docker compose run --rm test`
- [ ] The Android emulator run (needs an AVD) launches into the shell

**Dependencies:** Task 9
**Files:** `pubspec.yaml`, `.claude/specs/SPEC.md`, `.claude/specs/REVIEW.md`, `.claude/tasks/plan.md`, `.claude/tasks/todo.md`
**Scope:** S

### Checkpoint 4: Stage 1 done
- [ ] Slice 4 PR squash-merged, both CI jobs green
- [ ] You merge `dev` → `main` with a merge commit and tag `v0.1.0`
- [ ] Next: plan `identity` (Stage 2), only when you ask
