# Review: Stage 1 · Slice 3, shared domain vocabulary

## 1. What & why

This delivers Slice 3 of the [Stage 1 plan](../tasks/plan.md) (Tasks 6–7): the pure-Dart vocabulary every later module shares ([SPEC-app-foundation](SPEC-app-foundation.md#interface-exposed-to-other-modules)).
- `itemKey(name)`: how items match across inventory, grocery list and recipes (AC-AF-4)
- `toDateKey` / `fromDateKey`: the `yyyy-MM-dd` strings for date-only fields (AC-AF-7)
- `FoodCategory`, `StorageLocation`, `Unit`, `Quantity`: the category table, locations, units and conversions (AC-AF-5, and the values half of AC-AF-6)

There's no UI and no Firebase yet. The EN/ES labels for these enums come in Slice 4.

## 2. Files changed

**Domain** (`lib/domain/`, all new, no Flutter or Firebase imports)
- [item_key.dart](../../lib/domain/item_key.dart): `itemKey`
- [date_key.dart](../../lib/domain/date_key.dart): `toDateKey`, `fromDateKey`
- [models/food_category.dart](../../lib/domain/models/food_category.dart): the 13 categories with healthy flag, default location and shelf life
- [models/storage_location.dart](../../lib/domain/models/storage_location.dart): fridge, freezer, cabinet
- [models/unit.dart](../../lib/domain/models/unit.dart): `Dimension`, `Unit` (with base factors), `Quantity`

**Tests** (`test/domain/`, all new, 45 tests)
- [item_key_test.dart](../../test/domain/item_key_test.dart): AC-AF-4 plus `ñ`, `ü`, `ç`, decomposed accents, tabs/newlines/non-breaking spaces, and blank inputs
- [date_key_test.dart](../../test/domain/date_key_test.dart): AC-AF-7, padding, leap days, and ten malformed keys
- [units_test.dart](../../test/domain/units_test.dart): AC-AF-5 plus subtraction, comparison, and mass/volume isolation
- [food_category_test.dart](../../test/domain/food_category_test.dart): all 13 categories against the spec table

**Plan**
- [tasks/plan.md](../tasks/plan.md): Security lines for Slices 3 and 4 (per [dev_rules §9](../dev_rules.md)), and Slice 3 ticked
- [tasks/todo.md](../tasks/todo.md): Tasks 6–7 ticked

## 3. What to look for

1. **The accent map**, [item_key.dart:1-3](../../lib/domain/item_key.dart:1). It covers Spanish, Portuguese, French and German vowels, plus `ñ`, `ç` and `ý`/`ÿ`, and it strips decomposed accents. Letters like `ø`, `ł`, `œ` and `ß` pass through unchanged. That's fine for matching, since they stay consistent, but say if you want them mapped.
2. **Strict date parsing**, [date_key.dart:11-19](../../lib/domain/date_key.dart:11). `2026-02-30` throws, where a plain `DateTime` would roll it into March 2. Keys come back from Firestore, so a bad one should fail loudly.
3. **`toDateKey` uses the date's own fields**, [date_key.dart:4](../../lib/domain/date_key.dart:4). It doesn't call `.toLocal()`, so callers pass local times. `DateTime.now()` and Firestore's `Timestamp.toDate()` both already are.
4. **`null` rather than exceptions across dimensions**, [unit.dart:36-46](../../lib/domain/models/unit.dart:36). `+`, `-` and `compareTo` return `null` for `g` vs `pcs`, the same way `convertTo` does, and callers show "amount unknown". Because of that, `Quantity` isn't `Comparable` and can't be passed straight to `sort()`. Subtraction can go negative, and inventory decides what that means.
5. **Security:** no security-relevant change. It's pure Dart, with no I/O, rules, dependencies or personal data. Both secret scans print nothing. **Reported for later (not fixed):** `restock-suggestions` uses `itemKey` as a doc id (`stockLevels/{itemKey}`). A name like "Salt/Pepper" gives `salt/pepper`, which Firestore reads as a path, and `.` or `..` are invalid ids. That module's spec needs to handle it, by encoding the id or rejecting those names, when we plan it. The Firestore rules still deny anything outside known paths, so this is a crash risk, not a data leak.

## 4. How to verify

What I ran (all as expected):

```bash
flutter test test/domain/
```
Expected: "All tests passed!" (45).

```bash
flutter pub get --enforce-lockfile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test && flutter build web --release
```
Expected: "No issues found!", "All tests passed!" (46 with the template's widget test), "✓ Built build/web".

The secret scans from dev_rules §9 both print nothing.

The tests are real: each file failed to compile before its implementation existed. The decomposed-accent case fails if the combining-mark strip is removed.

```bash
git status --short
```
Expected:
- `M`: `.claude/specs/REVIEW.md`, `.claude/tasks/plan.md`, `.claude/tasks/todo.md`
- `??`: `lib/domain/`, `test/domain/`

**Not verified:** nothing in this slice runs on a device; it's covered by unit tests only.

## 5. Proposed commit message

```
feat(app-foundation): add shared domain vocabulary

Add the pure-Dart types and helpers every module shares:

- itemKey(name): trimmed, lowercased, whitespace collapsed, Latin
  accents (precomposed or decomposed) stripped; blank names give ''.
- toDateKey/fromDateKey: yyyy-MM-dd keys; malformed or impossible
  dates such as 2026-02-30 throw FormatException instead of rolling
  over.
- FoodCategory with each category's healthy flag, default location
  and shelf life from the spec table (fruit defaults to the cabinet).
- StorageLocation, Unit with dimension and base factor, and Quantity
  with convertTo, +, - and compareTo, which return null across
  dimensions.

Table tests cover AC-AF-4, AC-AF-5, AC-AF-6 (values) and AC-AF-7,
plus abuse cases for blank names and bad date keys.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

## 6. PR handoff

**What was done**
- `itemKey`, the date-key helpers, and the category, location, unit and quantity types in `lib/domain/`
- 45 table tests in `test/domain/` for AC-AF-4 to AC-AF-7, including abuse cases
- Security lines added to the plan for Slices 3 and 4

**Branch (`--head`):** `feat/app-foundation-domain`

**PR title:** `feat(app-foundation): add shared domain vocabulary`

**PR description:**
```markdown
Slice 3 of Stage 1 (`app-foundation`): the shared, pure-Dart vocabulary later modules build on. No UI or Firebase changes.

## What's in it
- `itemKey(name)`: how items match across inventory, groceries and recipes (trim, lowercase, collapse whitespace, strip Latin accents). Blank names give `''`.
- `toDateKey` / `fromDateKey`: `yyyy-MM-dd` for date-only fields. Malformed or impossible keys (e.g. `2026-02-30`) throw.
- `FoodCategory` (13 values with healthy flag, default location, shelf life), `StorageLocation`, `Unit` and `Quantity` (conversion, `+`/`-`/compare within a dimension, `null` across dimensions).

## Acceptance criteria
- [x] AC-AF-4: `itemKey` table, plus ñ/ü/ç, decomposed accents, odd whitespace
- [x] AC-AF-5: conversions, cross-dimension `null`, `500 g + 1 kg`
- [x] AC-AF-6 (values): all 13 categories match the spec table (labels come in Slice 4)
- [x] AC-AF-7: date keys round-trip; malformed keys throw

## Security
No security-relevant change: pure Dart, no I/O, rules, dependencies or personal data. Noted for `restock-suggestions`: `stockLevels/{itemKey}` needs doc-id-safe keys (names containing `/`).

## Checks
- `flutter test test/domain/`: 45 passed
- Quality gate green locally (format, analyze, test, web build)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Commands**

```bash
git switch -c feat/app-foundation-domain dev
```
```bash
git add .claude/specs/REVIEW.md .claude/tasks lib/domain test/domain && git commit
```
```bash
git push -u origin feat/app-foundation-domain
```
```bash
gh pr create --base dev --head feat/app-foundation-domain --title "feat(app-foundation): add shared domain vocabulary" --web
```
Paste the description above into the browser form. Once `flutter` and `rules` are green, squash-merge. Then:

```bash
git switch dev && git pull --ff-only && git branch -D feat/app-foundation-domain
```
```bash
git push origin --delete feat/app-foundation-domain
```

**Next:** Slice 4, the English/Spanish shell and the Stage 1 close. It needs an Android AVD for its last manual check.
