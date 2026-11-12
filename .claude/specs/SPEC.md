# Spec: Fridge Food Managing

> Status: **draft, awaiting review** · Last updated: 2026-11-12
> This is the project-wide spec and the index of module specs (see [Capability map](#capability-map)).
> It is a living document: update it before changing any decision it records.

## Objective

A cross-platform app (Android phone + web for computers in v1) where a **household**, for example a couple sharing one fridge, keeps track of the food at home, shops together from a live shared list, and finds recipes they can cook with what they have.

**Users:** people who share food storage and shopping, usually 2–4 per household. Each person has their own account and a unique username. People join a household by invite.

**User stories**

1. As a household member, I see what's in the fridge, freezer and cabinet, with quantity, when it was bought and when it expires, so we use food before it goes bad.
2. As a household member, I share that inventory with everyone in my household. Any change one of us makes shows up for the others within seconds.
3. As a shopper, I keep a grocery list shared with my household. When we split up in the store, we check items off on our own phones and see each other's checks live, even with patchy signal.
4. As a shopper, when I finish the trip, the items I bought move into the inventory automatically.
5. As a planner, I get restock suggestions (items below a minimum I set, or things we buy regularly that ran out) with healthy items first, and add them to the list in one tap.
6. As a cook, I browse recipes (our own, a starter set, or ideas from a public recipe site) and filter them by name, by what we can cook now, or by the ingredients I pick. I can add a recipe's missing items, or all of them, to the grocery list.
7. I can use the app in English or Spanish.

**Success looks like:** see [Success criteria](#success-criteria).

## Tech Stack

| Layer | Choice |
|---|---|
| UI framework | Flutter **3.47.6** / Dart **3.13.5**, pinned (see [DevOps Stage 0](#stage-0-baseline)) |
| Targets (v1) | **Android + web**. iOS/Windows/macOS later. Linux desktop is not supported by FlutterFire, so local dev runs as web or on an Android emulator |
| Architecture | Flutter's official MVVM guide: views → `ChangeNotifier` view models → repositories → services, wired with **`provider`** |
| Backend | Firebase **Auth** (email/password + Google) and **Cloud Firestore** (real-time listeners, offline persistence). Spark (free) plan, no Cloud Functions |
| Recipe ideas | TheMealDB public API v1 (`https://www.themealdb.com/api/json/v1/1/`) |
| i18n | `flutter_localizations` + `intl`, ARB files, `flutter gen-l10n` (EN + ES) |
| Runtime packages | `firebase_core`, `firebase_auth`, `cloud_firestore`, `provider`, `http`, `intl`, `flutter_localizations` (sdk) |
| Dev packages | `flutter_test`, `flutter_lints`, `fake_cloud_firestore`, `firebase_auth_mocks` |
| Rules tooling | `firebase/` Node project: `firebase-tools`, `@firebase/rules-unit-testing`, Node's built-in `node --test` |

Package versions are the latest stable at install time and are then locked: `pubspec.lock` and `firebase/package-lock.json` are committed. Any package not in this table needs approval first (see [Boundaries](#boundaries)).

**Google sign-in** uses `signInWithPopup` on web and `signInWithProvider(GoogleAuthProvider())` on Android, so the `google_sign_in` package isn't needed. We fall back to that package only if this proves insufficient. Android needs the app's SHA-1/SHA-256 registered in the Firebase console.

## Commands

```bash
# Setup
flutter pub get
flutterfire configure --platforms=android,web     # once, after the Firebase project exists (user)
cd firebase && npm ci                             # rules/emulator tooling

# Quality gate (same checks as CI)
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
cd firebase && npm test                           # security rules tests (runs firebase emulators:exec)
docker compose run --rm test                      # all Flutter checks in the pinned container

# Run (dev)
cd firebase && npx firebase emulators:start --only auth,firestore --import=seed
flutter run -d chrome --dart-define=USE_EMULATOR=true
flutter run -d web-server --web-port 8080 --dart-define=USE_EMULATOR=true   # no Chrome: open http://localhost:8080
flutter run -d <android-device-id> --dart-define=USE_EMULATOR=true
docker compose up dev                             # web dev server in the pinned container -> http://localhost:8080

# Build
flutter build web --release
flutter build apk --release
docker compose up --build web                     # nginx-served release build -> http://localhost:8081

# Deploy (ask first, every time, until automated)
cd firebase && npx firebase deploy --only firestore:rules,firestore:indexes
```

Emulator ports: Firestore **8085** (8080 is taken by the web dev server), Auth **9099**, Emulator UI **4000**. Emulator project id: `demo-fridge`.

## Project Structure

```
lib/
  main.dart                      → entry: Firebase init, emulator switch, provider wiring, runApp
  firebase_options.dart          → generated by flutterfire (public config, committed)
  config/                        → dependency wiring (providers), constants (thresholds, URLs)
  domain/
    models/                      → plain Dart models: FoodCategory, StorageLocation, Unit, Quantity,
                                   InventoryItem, GroceryItem, HistoryEntry, StockLevel, Recipe, …
    *.dart                       → pure logic: item_key, units, suggestions, recipe_availability,
                                   mealdb_measure_parser (no Flutter, no Firebase imports)
  data/
    repositories/                → <feature>_repository.dart: Firestore reads/writes → domain models
    services/                    → themealdb_service.dart (HTTP)
  ui/
    core/                        → app shell, theme, shared widgets (quantity field, date field, badges)
    <feature>/view_models/       → <feature>_view_model.dart (ChangeNotifier)
    <feature>/widgets/           → <feature>_screen.dart + feature widgets
  l10n/
    app_en.arb, app_es.arb       → every user-facing string
assets/
  seed_recipes.json              → starter recipes (EN + ES)
test/                            → mirrors lib/ (domain/, data/, ui/)
firebase/
  firebase.json, .firebaserc     → emulator config, project alias
  firestore.rules                → security rules (the trust boundary)
  firestore.indexes.json
  test/*.test.js                 → rules tests (node --test)
  seed/                          → emulator seed export (committed)
  package.json, package-lock.json
.github/workflows/ci.yml         → CI
.claude/
  SPEC.md, SPEC-<module-id>.md   → specs
  REVIEW.md                      → per-slice change summary (overwritten each slice)
  tasks/plan.md, tasks/todo.md   → plan and tasks for the current stage (committed)
```

Feature folders under `lib/ui/` are `auth`, `household`, `inventory`, `grocery`, `suggestions`, `recipes`, `discover`.

## Code Style

`flutter_lints` + `dart format` (CI-enforced), following Effective Dart. One real example of the house style:

```dart
// lib/data/repositories/inventory_repository.dart
class InventoryRepository {
  InventoryRepository(this._db, this._householdId);

  final FirebaseFirestore _db;
  final String _householdId;

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('households').doc(_householdId).collection('inventory');

  Stream<List<InventoryItem>> watchAll() => _items.snapshots().map(
        (snap) => snap.docs.map(InventoryItem.fromFirestore).toList(),
      );
}

// lib/ui/inventory/view_models/inventory_view_model.dart
class InventoryViewModel extends ChangeNotifier {
  InventoryViewModel(this._repo) {
    _sub = _repo.watchAll().listen(
      (items) {
        _items = items;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e;
        notifyListeners();
      },
    );
  }

  final InventoryRepository _repo;
  late final StreamSubscription<List<InventoryItem>> _sub;
  List<InventoryItem>? _items; // null = still loading
  Object? _error;

  List<InventoryItem>? get items => _items;
  Object? get error => _error;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
```

Conventions:
- **Files** use `snake_case.dart`, **types** use `PascalCase`, and **members** use `camelCase`. One screen per file: `<feature>_screen.dart`.
- **Layers only call downward**: widgets → view models → repositories → Firebase/HTTP. Widgets never touch Firestore. Repositories return domain models, never snapshots.
- **Pure logic** lives in `lib/domain/` with no Flutter/Firebase imports, so it is unit-testable without fakes.
- **Firestore** field names are `camelCase`. Date-only fields are `yyyy-MM-dd` strings. Instants are `Timestamp`. Enums are stored by `name`.
- **Strings**: every user-facing string goes through `AppLocalizations.of(context)` and exists in both ARB files.
- **Comments** only explain *why*. Known shortcuts get `// shortcut: <limit>, <when to upgrade>`.
- **Keep it small**: no abstraction, option or config until a second caller needs it.

## Testing Strategy

| Level | What | Tool | Where |
|---|---|---|---|
| Unit | Pure logic: `itemKey`, unit conversion, suggestions, recipe availability, TheMealDB measure parsing, Finish-trip defaults | `flutter test` | `test/domain/` |
| Repository / view model | Firestore reads/writes, batches, transactions, auth flows | `fake_cloud_firestore`, `firebase_auth_mocks` | `test/data/`, `test/ui/**/view_models/` |
| Widget | Each screen renders states (loading/empty/data/error), validation, key interactions, EN + ES | `WidgetTester` with fake repositories | `test/ui/` |
| Security rules | Every allow **and** deny path (membership, invites, usernames, user docs) | Firestore emulator + `@firebase/rules-unit-testing` | `firebase/test/` |
| Manual | Two accounts in one household, Android ↔ web, real-time + offline | Emulator, then prod | Each `REVIEW.md` "How to verify" |

- There's no percentage coverage target. Every pure function, every repository write path and every rule must have a test.
- Logic that depends on time takes `today`/`now` as a parameter, so tests are deterministic.
- A bug fix starts with a failing test that reproduces it.
- `integration_test` is not used in v1.

## Boundaries

- **Always**
  - Run the quality gate (format, analyze, test; plus rules tests when rules change) before handing over a slice.
  - End every slice with the `REVIEW.md` change summary (see [Collaboration protocol](#collaboration-protocol)).
  - Put every UI string in both `app_en.arb` and `app_es.arb`.
  - Keep household data only under `households/{hid}/…`, protected by membership rules.
  - Update the relevant spec *before* changing a decision it records.
  - Make schema changes additive only (new optional fields; readers default missing ones).
- **Ask first**
  - Adding a dependency not listed in [Tech Stack](#tech-stack).
  - Data-model or rules changes beyond the specs.
  - Any deploy to the real Firebase project.
  - Blaze plan / Cloud Functions.
  - New target platforms.
  - `go_router`.
  - Destructive data migrations (also need a backup first).
- **Never**
  - Run git writes (`commit`, `push`, `merge`, `tag`, `switch -c`) or `gh pr` commands. **The user owns all commits, PRs, merges and tags.**
  - Commit service-account/admin keys or tokens. The generated `firebase_options.dart` and `google-services.json` are public config and fine to commit.
  - Loosen rules to `allow read, write: if true`.
  - Delete or skip failing tests.
  - Force-push `main`.
  - Point tests at the production Firebase project.

## Capability Map

Approved 2026-11-12. Module ids are stable; specs, plans and tasks refer to them.

| Module id | Responsibility | Depends on | Spec |
|---|---|---|---|
| `app-foundation` | Firebase init (Android + web), emulator switch, app shell + navigation, theme, EN/ES l10n, shared models (FoodCategory, StorageLocation, Unit, Quantity, `itemKey`), `firebase/` rules + emulator test harness | — | [SPEC-app-foundation.md](SPEC-app-foundation.md) |
| `identity` | Email + Google sign-in/out, password reset, unique username claim, user profile doc | app-foundation | [SPEC-identity.md](SPEC-identity.md) |
| `households` | Create household, invite by username, accept/decline/cancel, leave, members list; membership rules for all household data | identity | [SPEC-households.md](SPEC-households.md) |
| `inventory` | "Food Managing": items in fridge/freezer/cabinet with quantity, bought date, expiry; expiring-soon badges; add/edit/consume/delete; purchase + consumption history | households | [SPEC-inventory.md](SPEC-inventory.md) |
| `grocery-list` | Live shared list; manual add; check/uncheck while shopping; sort A–Z or group by category; category filter; Finish trip → inventory | households, inventory | [SPEC-grocery-list.md](SPEC-grocery-list.md) |
| `restock-suggestions` | Minimum stock levels + history-based suggestions, healthy-first, one-tap add to grocery list | inventory, grocery-list | [SPEC-restock-suggestions.md](SPEC-restock-suggestions.md) |
| `recipes` | Household recipes (CRUD) + seeded starter set; required/optional ingredients; sort/filter A–Z, by availability, by selected ingredients; add all/missing to grocery list | inventory, grocery-list | [SPEC-recipes.md](SPEC-recipes.md) |
| `recipe-discovery` | Browse TheMealDB (search, by ingredient, random); import into household recipes | recipes | [SPEC-recipe-discovery.md](SPEC-recipe-discovery.md) |

**Build order:** Stage 0 DevOps baseline → `app-foundation` → `identity` → `households` → `inventory` → `grocery-list` → `restock-suggestions` ∥ `recipes` → `recipe-discovery`

**Out of scope for v1:**
- Item position inside the fridge. Planned for later; Firestore is schemaless, so adding the field later needs no migration.
- Push/expiry notifications (need FCM + Cloud Functions/Blaze).
- Multiple households per user.
- Removing other members.
- iOS/Windows/macOS builds.
- Deep-link URLs/`go_router`.
- An in-app language switch (the app follows the device language).

## Data Model (Firestore)

Each collection is owned by exactly one module; that module's spec defines its fields, validation and rules in detail.

| Path | Fields | Owner |
|---|---|---|
| `users/{uid}` | username, displayName, householdId? | identity (householdId written by households) |
| `usernames/{username}` | uid | identity |
| `invites/{hid}_{toUid}` | householdId, householdName, fromUid, fromUsername, toUid, createdAt | households |
| `households/{hid}` | name, memberIds[], createdBy, recipesSeeded | households (recipesSeeded written by recipes) |
| `households/{hid}/inventory/{id}` | name, itemKey, category, location, quantity, unit, acquiredOn, expiresOn?, addedBy, updatedAt | inventory |
| `households/{hid}/history/{id}` | itemKey, name, category, type (purchased\|consumed), quantity, unit, at, by | inventory |
| `households/{hid}/grocery/{id}` | name, itemKey, category, quantity, unit, checked, checkedBy?, addedBy, createdAt, source (manual\|suggestion\|recipe) | grocery-list |
| `households/{hid}/stockLevels/{itemKey}` | name, category, minQuantity, unit | restock-suggestions |
| `households/{hid}/recipes/{id}` | title, servings?, steps, ingredients[{name, itemKey, quantity?, unit?, optional, note?}], source (own\|seed\|themealdb), externalId?, createdBy, updatedAt | recipes (themealdb imports via recipe-discovery) |

**Cross-module rules**
- **Item identity**: items match across inventory, grocery list and recipes by `itemKey(name)`: trimmed, lowercased, inner whitespace collapsed, diacritics stripped (`" Jalapeño  Peppers"` → `"jalapeno peppers"`). Name fields autocomplete from names already known in the household, so keys converge.
  - `shortcut:` there is no plural or language matching ("tomato" ≠ "tomatoes" ≠ "tomate"). Upgrade to a synonyms table if mismatches bother users.
- **Units**: `pcs`; mass `g`, `kg`; volume `ml`, `l`, `tsp` (5 ml), `tbsp` (15 ml), `cup` (240 ml). Quantities convert only within the same dimension. Comparing across dimensions (e.g. pcs vs g) gives "amount unknown".
- **Categories** (shared enum): see [SPEC-app-foundation.md](SPEC-app-foundation.md#food-categories). It defines each category's healthy flag, default storage location and default shelf life.
- **Dates**: date-only fields are `yyyy-MM-dd` strings in the device's local calendar. Instants are `Timestamp`.
- **Offline**: Firestore persistence is on for Android (default) and web (enabled explicitly). Writes made offline queue and sync on reconnect. Transactions need a connection; batches don't.

## DevOps & Delivery

Goals: **stable** (nothing reaches `dev`/`main` without green checks), **backtrackable** (every merge and release can be reverted or rebuilt), **reproducible** (same toolchain and locked dependencies locally, in Docker and in CI).

Starting point (2026-11-12): GitHub remote `origin`, branches `main` + `dev`, no tags, no CI. Local Flutter 3.47.6 matches the Dockerfile's `FLUTTER_VERSION`. `pubspec.lock` is committed.

### Collaboration protocol

- **The user owns every git write**: branches, commits, pushes, PRs, merges, tags, branch protection, GitHub releases. Claude only reads git state (`status`, `diff`, `log`), leaves changes uncommitted, and supplies commands and messages to paste.
- **Every slice ends with a change summary** in chat and in `.claude/REVIEW.md` (overwritten each slice):
  1. **What & why**: 2–3 lines tying the slice to its spec section and acceptance criteria.
  2. **Files changed**: clickable paths grouped by layer (models / repositories / view models / widgets / rules / tests / config), one line each on what changed.
  3. **What to look for**: the 2–5 places that most need human eyes (rules, data writes, tricky logic) as `file:line`, plus anything uncertain.
  4. **How to verify**: exact commands and manual steps with expected results, and anything that could not be verified.
  5. **Proposed commit message**: Conventional Commits, module-id scope.
- **Every stage end** adds a draft PR title and body for `dev` → `main` to `REVIEW.md`: what the stage delivers, acceptance criteria checked off, rules/data notes, and a rollback note. It also gives the exact version-bump and tag commands.
- The next slice starts only after the user has reviewed and committed the current one, so each commit maps to one reviewed summary.

### Stage 0: Baseline

One PR to `dev`, before any feature code.

- **Toolchain pin**: `environment: flutter: 3.47.6` in `pubspec.yaml`, so `flutter pub get` refuses any other Flutter version. The Dockerfile `ARG FLUTTER_VERSION` must match; a mismatch makes the Docker `pub get` fail, so the pin checks itself.
- **Locked deps**: CI runs `flutter pub get --enforce-lockfile`.
- **CI** (`.github/workflows/ci.yml`), on every PR and on pushes to `dev`/`main`, job `flutter`: `subosito/flutter-action` (`flutter-version-file: pubspec.yaml`, cache on) → `pub get --enforce-lockfile` → format check → `flutter analyze` → `flutter test` → `flutter build web --release`.
- **Local = CI**: the `test` service in `docker-compose.yml` runs the same commands.
- **Branch model**: `main` holds released stages only. `dev` is integration. Work happens on short-lived `feat/<module-id>-<slug>` branches off `dev`.
- **Commits**: Conventional Commits scoped by module id (`feat(inventory): consume item`, `docs(spec): …`, `ci: …`). Feature PRs are **squash-merged** into `dev` (one revertable commit per slice). `dev` → `main` uses a **merge commit** per stage.
- **Branch protection** (the user sets this in GitHub): on `main` and `dev`, require a PR, require the CI checks to pass, and block force-push and deletion.

Acceptance:
- [ ] A trivial PR to `dev` runs CI, and CI is green.
- [ ] A deliberately mis-formatted Dart file makes CI fail at the format step.
- [ ] Changing `environment.flutter` to another version makes `flutter pub get` fail locally.
- [ ] `docker compose run --rm test` runs the same checks as CI and passes.

### Stage 1: Environments

Delivered inside `app-foundation`.

- **Firebase Emulator Suite** (auth + firestore) in `firebase/`, project id `demo-fridge`. The `demo-` prefix means emulator runs can never reach real Firebase. `firebase-tools` and `@firebase/rules-unit-testing` are locked in `firebase/package-lock.json`. The Node version is in `.nvmrc`.
- **App ↔ emulator**: `--dart-define=USE_EMULATOR=true` connects Auth (9099) and Firestore (8085) to `localhost` on web and `10.0.2.2` from the Android emulator.
- **Seed data**: committed in `firebase/seed/` and loaded with `--import`, so every dev and test session starts from the same state. It has two users in one household and a few items per section.
- **Prod**: one real Firebase project, which the user creates and connects via `flutterfire configure --platforms=android,web`. There's no staging project in v1; adding one needs approval first.
- **CI job `rules`**: `actions/setup-node` (`node-version-file: .nvmrc`) + `actions/setup-java` (21) → `npm ci` → `npm test` (in `firebase/`).

Acceptance:
- [ ] `cd firebase && npm test` passes locally and in CI.
- [ ] The app run with `USE_EMULATOR=true` shows its reads and writes in the Emulator UI (http://localhost:4000), and the seed data is visible.
- [ ] Without `USE_EMULATOR`, the app uses the prod options from `firebase_options.dart`.

### Stages 2–8: Module loop

The order is `identity` → `households` → `inventory` → `grocery-list` → `restock-suggestions` ∥ `recipes` → `recipe-discovery`.

1. The user creates `feat/<module-id>-<slice>` off `dev` (Claude provides the command).
2. The module spec is reviewed, then a plan and tasks (`.claude/tasks/plan.md`, `.claude/tasks/todo.md`) are approved.
3. Claude implements one small slice that passes the quality gate, then writes the `REVIEW.md` summary. The user reviews and commits.
4. The user opens a PR → `dev`, CI is green, Claude can run `/review` on request, and the user squash-merges.
5. When the module is done, Claude bumps `version: 0.<stage>.0+<build>` in `pubspec.yaml` and drafts the stage PR and tag commands. The user merges `dev` → `main` and tags `v0.<stage>.0` (annotated).
6. Release from the tag (ask first, every time, until automated): deploy rules and indexes → deploy web → build the Android release APK from the tag and attach it to a GitHub Release (the user publishes it).

### Release & rollback

- **Code**: `git revert <squash-commit>` on `dev`. To rebuild any stage exactly: `git checkout v0.N.0 && docker compose run --rm test`.
- **Security rules**: redeploy `firebase/firestore.rules` from the previous tag. The rules history in the Firebase console is the backup path.
- **Web**: Firebase Hosting is recommended (free tier, release history, one-click rollback). The nginx Docker `web` target stays for local prod-like testing.
- **Android**: rebuild the previous tag with a higher `+build` number (versionCode must always increase).
- **Data**: schema changes are additive only, so older app versions keep working. Destructive migrations need approval first and a backup first.
- **Backups**: Firestore scheduled backups need the Blaze plan (see [Open Questions](#open-questions)).
- **Automated deploy** (later, ask first): a GitHub Action on `v*` tags deploys rules and hosting using a GitHub secret. Credentials are never committed.

Skipped in v1: Dependabot, Crashlytics/monitoring, staging Firebase project, Play Store tracks, CHANGELOG file (annotated tags and generated GitHub release notes cover it).

## Success Criteria

- [ ] Two accounts in the same household, one on Android and one on web, each see the other's inventory and grocery changes within ~2 s.
- [ ] A grocery item checked off while offline shows as checked immediately and syncs to the other member on reconnect.
- [ ] Rules tests prove that a non-member can neither read nor write any household data, and nobody can claim someone else's username.
- [ ] Every screen is fully usable in English and Spanish (no hard-coded strings).
- [ ] Finish trip, restock suggestions, recipe availability and "add missing" each meet their module's acceptance criteria.
- [ ] `flutter analyze` is clean, all tests pass, CI is green, and the Docker web release build serves the app.

## Open Questions

1. **Seed recipes**: which ~10 starter recipes (EN + ES)? Claude will propose a list during `recipes` planning.
2. **Shelf-life defaults** per category (proposed in [SPEC-app-foundation.md](SPEC-app-foundation.md#food-categories)): confirm or adjust.
3. **Suggestion thresholds**: ≥3 purchases in 60 days, "expiring" = within 2 days, "expiring soon" badge = within 3 days. Tune after real use?
4. **TheMealDB**: the free test key `1` is meant for development/education. Confirm the terms are acceptable for a personal app, and confirm web CORS during `recipe-discovery`.
5. **Firebase project**: the user creates it (needs their Google account) and runs `flutterfire configure` before `app-foundation` can finish.
6. **Web hosting**: Firebase Hosting (recommended, has rollback) vs self-hosted nginx?
7. **Backups**: enable the Blaze plan (≈ cents/month) for scheduled Firestore backups before real data matters?
8. **Branch protection**: the user applies it in GitHub during Stage 0.
