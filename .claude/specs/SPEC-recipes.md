# Module Spec: `recipes`

> Depends on: `inventory`, `grocery-list` · Used by: `recipe-discovery` · Delivery: Stage 7 (in parallel with `restock-suggestions`)
> Status: draft, awaiting review

## Objective

Give the household a recipe book: their own recipes plus a small starter set. Each recipe lists required and optional ingredients with quantities. The list can be filtered by name, by what can be cooked with what's at home, or by chosen ingredients. Missing ingredients (or all of them) go onto the grocery list in one tap.

## Scope

**In**
- **Recipes screen** (list) with these controls:
  - **Sort** dropdown: *A–Z* or *Availability* (fewest missing required ingredients first, then A–Z).
  - **Show** dropdown: *All recipes* or *Can cook now*.
  - **Ingredient filter**: multi-select chips built from the item names in inventory and in recipes. A recipe is shown only if it contains **all** selected ingredients (required or optional).
  - Each row shows the title and an availability badge: **Can cook**, or **Missing N**.
- **Recipe detail**: title, servings, steps.
  - **Required ingredients**, each marked ✓ have / ◐ short by X / ✗ missing / ✓? have (amount unknown).
  - **Optional ingredients**, with the same marks and a **+** button each to add that one to the list.
  - Actions: **Add missing to list** and **Add all to list**. Also Edit and Delete (with confirmation).
- **Recipe form** (create/edit):
  - title (required, ≤ 80 chars); servings (optional, 1–50); steps (multiline text)
  - ingredients (≥ 1): name (required, autocomplete); quantity (optional, > 0 if given); unit (required when a quantity is given); optional flag; note (optional, e.g. "finely chopped" or an imported measure)
- **Starter set**: about 10 recipes bundled in `assets/seed_recipes.json` with English and Spanish text.
  - The first time any member opens Recipes, a **transaction** checks `households/{hid}.recipesSeeded`. If it isn't true, the transaction copies the seeds (in that member's app language, `source: seed`) and sets the flag.
  - Seeded recipes are ordinary household recipes: they can be edited and deleted.
  - If the device is offline the transaction fails silently and is retried on the next open.
- Recipes are shared live across household members.

**Out:** scaling by servings, photos, nutrition info, meal planning, sharing recipes outside the household, unit-aware merging of optional ingredients.

## Availability rules (pure, `lib/domain/recipe_availability.dart`)

For each ingredient, using `onHand(itemKey, unit)` from `inventory`:

| Condition | Status |
|---|---|
| Recipe quantity is null (e.g. "to taste") and any lot exists | **have** |
| Recipe quantity is null and there are no lots | **missing** |
| `onHand == null` (lots exist but the units don't convert) | **haveUnknown** (counts as available) |
| `onHand ≥ quantity` | **have** |
| `0 < onHand < quantity` | **short**, shortfall = quantity − onHand |
| `onHand == 0` | **missing** |

- **Recipe status**: *Can cook* if every **required** ingredient is have or haveUnknown. Otherwise, *Missing N*, where N = the number of required ingredients that are short or missing.
- Optional ingredients never affect the status.

**Add to list** (calls `GroceryRepository.addAll`, `source: recipe`, merge rule applies):
- **Add missing** adds every required ingredient that is short (shortfall quantity) or missing (full quantity).
- **Add all** adds every required ingredient at full quantity.
- An ingredient with no quantity is added as 1 pcs.
- Each item's category is the one last used for that `itemKey` in inventory or history, else Other.
- After adding, a snackbar says "Added N items to Groceries".

## Data owned

| Path | Fields |
|---|---|
| `households/{hid}/recipes/{id}` | `title`, `servings?`, `steps`, `ingredients` (list of `{name, itemKey, quantity?, unit?, optional, note?}`), `source` (`own`\|`seed`\|`themealdb`), `externalId?`, `createdBy`, `updatedAt` |
| `households/{hid}.recipesSeeded` | bool, written only by the seeding transaction |

**Rules** (on top of `isMember`): `title` is a non-empty string ≤ 80 chars; `ingredients` is a list of size 1–50; `source` is in the enum.

## Interface exposed to other modules

```dart
class RecipeRepository {            // constructed with hid
  Stream<List<Recipe>> watchAll();
  Future<String> save(Recipe recipe);                 // create or update, returns id
  Future<void> delete(String id);
  Future<Recipe?> findByExternalId(String source, String externalId); // used by recipe-discovery
  Future<void> seedIfNeeded(String languageCode);
}

RecipeAvailability availability(Recipe r, List<InventoryItem> inventory);
List<GroceryItem> groceryItemsFor(Recipe r, RecipeAvailability a, {required bool onlyMissing, required CategoryLookup lookup});
```

`recipe-discovery` opens the Recipe form prefilled with an unsaved `Recipe` (`source: themealdb`, `externalId`).

## Acceptance criteria

Fixture recipe "Fried rice", which needs:
- required: rice 200 g, eggs 2 pcs, soy sauce 2 tbsp
- optional: spring onion 1 pcs

1. **AC-RC-1**: Inventory has rice 1 kg, eggs 1 pcs and soy sauce 250 ml. Fried rice shows rice ✓, eggs ◐ short by 1 pcs, soy sauce ✓ (30 ml needed ≤ 250 ml), and the badge reads **Missing 1**.
2. **AC-RC-2**: With eggs 2 pcs, the badge reads **Can cook**. Having or lacking the spring onion doesn't change it.
3. **AC-RC-3**: With soy sauce stored as "1 pcs" (a bottle), soy sauce shows ✓? (amount unknown) and still counts as available.
4. **AC-RC-4**: *Add missing* with the inventory from AC-RC-1 adds only "eggs 1 pcs" to Groceries. *Add all* adds rice 200 g, eggs 2 pcs and soy sauce 2 tbsp. An existing unchecked "Eggs 6 pcs" becomes 7 pcs (merge rule).
5. **AC-RC-5**: Sort *A–Z* orders by title (case- and accent-insensitive). Sort *Availability* lists Can cook recipes first, then Missing 1, Missing 2, …
6. **AC-RC-6**: *Show: Can cook now* hides every recipe with Missing ≥ 1.
7. **AC-RC-7**: Selecting the chips [eggs, rice] shows only recipes containing both. Adding [salmon] narrows the list further. Clearing shows everything.
8. **AC-RC-8**: The first open of Recipes by a member using Spanish creates the ~10 seed recipes in Spanish and sets `recipesSeeded = true`. Later opens, or two members opening at the same time, create no duplicates.
9. **AC-RC-9**: Saving with an empty title, zero ingredients, a quantity ≤ 0, or a quantity without a unit is blocked with field messages.
10. **AC-RC-10**: Member B sees A's create, edit and delete within ~2 s. Deleting asks for confirmation first.
11. **AC-RC-11**: All UI text is in EN and ES. Seed content is in the language used at seeding time.
12. **AC-RC-12**: Rules: a non-member is denied; an empty title or an empty ingredient list is denied; a non-member cannot set `recipesSeeded`.

## Tests

- `test/domain/recipe_availability_test.dart`: AC-RC-1 to AC-RC-4 (statuses and the grocery items produced).
- `test/domain/recipe_filter_test.dart`: AC-RC-5 to AC-RC-7.
- `test/data/recipe_repository_test.dart`: seeding transaction runs only once (AC-RC-8), save/delete.
- `test/assets/seed_recipes_test.dart`: every seed recipe parses, has `en` and `es`, and has ≥ 1 required ingredient with valid units.
- `test/ui/recipes/*_test.dart`: form validation (AC-RC-9), badges, dropdowns, EN/ES.
- `firebase/test/recipes.test.js`: AC-RC-12.

## Open questions

- Which ~10 starter recipes? I'll propose a list of everyday dishes with common ingredients (e.g. omelette, fried rice, pasta with tomato sauce, lentil soup, chicken & rice, salad, pancakes, guacamole, stir-fried vegetables, tuna sandwich) for approval during planning.
- Should *Add all* also include optional ingredients? Proposed: no; each optional ingredient has its own +.
