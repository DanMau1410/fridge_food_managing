# Module Spec: `app-foundation`

> Depends on: — · Used by: every module · Delivery: DevOps Stage 1 (see [SPEC.md](SPEC.md#stage-1-environments))
> Status: draft, awaiting review

## Objective

Replace the template app with a runnable shell that every feature plugs into. It covers:
- Firebase connected on Android and web, with a switch to the local emulator
- navigation between the three sections
- EN/ES localization
- the shared food vocabulary: categories, storage locations, units, item keys
- the security-rules test harness

No user-visible feature yet beyond the empty, navigable shell.

## Scope

**In**
- `lib/main.dart`: `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
  - If `const bool.fromEnvironment('USE_EMULATOR')`, connect Auth to `:9099` and Firestore to `:8085`. The host is `localhost` on web and `10.0.2.2` on Android.
  - Enable Firestore persistence on web.
- `lib/config/dependencies.dart`: the `MultiProvider` that later modules extend.
- `lib/ui/core/app_shell.dart`: three destinations: **Food** (inventory), **Groceries**, **Recipes**.
  - `NavigationBar` below 840 px wide, `NavigationRail` at 840 px and above.
  - App-bar action for **Household & account** (placeholder screen until `identity` and `households`).
  - Each destination shows a localized empty placeholder.
- `lib/ui/core/theme.dart`: Material 3, `ColorScheme.fromSeed(seedColor: Colors.teal)` (kept from the template), light and dark following the system.
- Localization: `l10n.yaml`, `lib/l10n/app_en.arb` and `app_es.arb`, `generate: true`. The locale follows the device; unsupported locales fall back to English.
- Shared domain (pure Dart, `lib/domain/`):
  - `itemKey(String name)`
  - `FoodCategory`, `StorageLocation`, `Unit`, `Quantity` (amount + unit; `convertTo(Unit) → Quantity?`; `+`/`-`/compare within a dimension)
  - date helpers `toDateKey(DateTime) → 'yyyy-MM-dd'` / `fromDateKey`
  - localized labels for each enum
- `firebase/`:
  - `firebase.json` (emulator ports, `demo-fridge`) and `.firebaserc`
  - `firestore.rules`: default deny; modules add their own `match` blocks
  - `firestore.indexes.json`
  - `package.json` / `package-lock.json`, `.nvmrc`
  - `test/foundation.test.js`
  - `seed/` (emulator export)
- Remove the template `FridgePage` and its `test/widget_test.dart`, replacing them with shell tests.
- Add the CI `rules` job (DevOps Stage 1).

**Out:** sign-in (identity), any Firestore collection (later modules), iOS/desktop Firebase config.

## Food categories

`FoodCategory` is the single source of truth for each category's healthy flag, default location and default shelf life. The defaults below are proposals; see Open Questions.

| Value | EN | ES | Healthy | Default location | Default shelf life |
|---|---|---|---|---|---|
| `vegetables` | Vegetables | Verduras | yes | fridge | 7 d |
| `fruit` | Fruit | Fruta | yes | fridge | 7 d |
| `meat` | Meat | Carne | no | fridge | 3 d |
| `fish` | Fish & seafood | Pescado y mariscos | yes | fridge | 2 d |
| `dairyEggs` | Dairy & eggs | Lácteos y huevos | no | fridge | 7 d |
| `grainsBread` | Grains & bread | Cereales y pan | no | cabinet | 4 d |
| `legumes` | Legumes | Legumbres | yes | cabinet | — |
| `frozen` | Frozen | Congelados | no | freezer | 90 d |
| `canned` | Canned & jarred | Conservas | no | cabinet | — |
| `snacks` | Snacks & sweets | Snacks y dulces | no | cabinet | — |
| `beverages` | Beverages | Bebidas | no | cabinet | — |
| `condimentsSpices` | Condiments & spices | Condimentos y especias | no | cabinet | — |
| `other` | Other | Otros | no | cabinet | — |

`StorageLocation`: `fridge` (Fridge / Nevera), `freezer` (Freezer / Congelador), `cabinet` (Cabinet / Despensa).

`Unit`: `pcs`; mass `g`, `kg` (1000 g); volume `ml`, `l` (1000 ml), `tsp` (5 ml), `tbsp` (15 ml), `cup` (240 ml).

## Interface exposed to other modules

- `itemKey`, `FoodCategory` (+ `healthy`, `defaultLocation`, `defaultShelfLifeDays`), `StorageLocation`, `Unit`, `Quantity`, `toDateKey`/`fromDateKey`
- `AppShell` with slots for each section's screen, and the account action
- `dependencies.dart`, the place where each module registers its repositories and view models
- `firestore.rules` helpers: `signedIn()` and `isMember(hid)`. `isMember` is a stub until `households` fills it in.

## Acceptance criteria

1. **AC-AF-1**: On Android and web the app launches into the shell. It shows Food, Groceries and Recipes labels in the device language (English or Spanish), and English on any other device language.
2. **AC-AF-2**: Window width < 840 px shows a bottom `NavigationBar`; ≥ 840 px shows a `NavigationRail`. Switching destinations keeps each tab's state.
3. **AC-AF-3**: With `--dart-define=USE_EMULATOR=true`, Firestore and Auth calls hit the emulator (visible in the Emulator UI). Without the flag the app uses the prod `firebase_options.dart`.
4. **AC-AF-4**: `itemKey`:
   - `"  Tomates "` → `"tomates"`
   - `"Jalapeño"` → `"jalapeno"`
   - `"CAFÉ  con  Leche"` → `"cafe con leche"`
   - `""` and `"   "` → invalid (callers must reject empty names)
5. **AC-AF-5**: `Quantity`:
   - `1 kg → g` = 1000 g; `1.5 l → ml` = 1500 ml; `2 tbsp → ml` = 30 ml; `1 cup → l` = 0.24 l
   - `3 pcs → g` = `null`
   - `500 g + 1 kg` = 1500 g (or 1.5 kg)
   - comparing `500 g` with `2 pcs` returns "not comparable"
6. **AC-AF-6**: Every `FoodCategory`, `StorageLocation` and `Unit` has an EN and an ES label, and every category has the healthy flag, default location and shelf life from the table.
7. **AC-AF-7**: `toDateKey(DateTime(2026, 3, 5, 23, 59))` = `"2026-03-05"` and `fromDateKey("2026-03-05")` round-trips.
8. **AC-AF-8**: Rules default deny: an unauthenticated **and** an authenticated read or write to an arbitrary path (`/anything/x`) is denied in the emulator tests.
9. **AC-AF-9**: `docker compose run --rm test` and both CI jobs (`flutter`, `rules`) are green.

## Tests

- `test/domain/item_key_test.dart`, `units_test.dart`, `food_category_test.dart`, `date_key_test.dart`: tables for AC-AF-4 to AC-AF-7.
- `test/ui/core/app_shell_test.dart`: AC-AF-1 (EN + ES locales) and AC-AF-2 (two surface sizes).
- `firebase/test/foundation.test.js`: AC-AF-8.

## Prerequisites (user)

- Create the Firebase project, enable Auth (Email/Password + Google) and Firestore.
- Run `flutterfire configure --platforms=android,web`.
- Optional for Android Google sign-in later: add the debug SHA-1/SHA-256.

## Open questions

- Confirm or adjust the shelf-life defaults and default locations above. For example, should fruit default to the cabinet?
- Should `grainsBread` be split into "Bread" (short shelf life) and "Grains & pasta" (none)? Proposed: keep one category for v1.
