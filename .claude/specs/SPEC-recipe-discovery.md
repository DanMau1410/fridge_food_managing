# Module Spec: `recipe-discovery`

> Depends on: `recipes` · Used by: — · Delivery: Stage 8
> Status: draft, awaiting review

## Objective

A sub-screen of Recipes for finding new ideas in a public recipe catalog (TheMealDB). You can browse just for inspiration, or import a recipe into the household's recipe book, where it becomes editable and gets availability checks.

## Scope

**In**
- **Discover screen**, opened from the Recipes app bar:
  - search field with a mode toggle: **By name** (`search.php?s=`) or **By ingredient** (`filter.php?i=`, then `lookup.php?i=` when a result is opened)
  - **Surprise me** button (`random.php`)
  - results list: thumbnail (`Image.network`), title, category / cuisine
- **Discover detail**: title, thumbnail, ingredients with the original measures, instructions, and an **Import** button.
- **Import**:
  - If a recipe with `source: themealdb` and the same `externalId` already exists, show "Already in your recipes" with an **Open** button.
  - Otherwise, map the meal to a `Recipe` and open the **Recipe form** prefilled (unsaved). The user can mark optional ingredients and fix quantities, and **Save** stores it through `RecipeRepository.save`.
- `TheMealDbService` (`lib/data/services/`), using `http`:
  - base URL and test key `1` live in `lib/config/`
  - 10 s timeout; non-200 responses and malformed JSON become a typed error
- **Measure parser** (pure, `lib/domain/mealdb_measure_parser.dart`) turns `strMeasureN` into `quantity?` + `unit?` + `note?`.

**Out:**
- Translating recipe content (TheMealDB is English only; the UI around it is still EN/ES).
- Storing images, opening external source links (would need `url_launcher`, ask first), paid API features, offline caching of results.

## Mapping a meal to a `Recipe`

| TheMealDB | Recipe |
|---|---|
| `strMeal` | `title` |
| `strInstructions` | `steps` |
| `strIngredientN` + `strMeasureN` (N = 1–20, skip empty/blank ingredients) | `ingredients[]`: `name` = trimmed ingredient, `itemKey(name)`, parsed `quantity`/`unit`/`note`, `optional: false` |
| `idMeal` | `externalId`, with `source: themealdb` |
| — | `servings: null` |

**Measure parser rules**
- **Number forms**: an integer, a decimal (`1.5`), a fraction (`1/2`), or a mixed number (`1 1/2`). A unit may follow with or without a space (`200g`).
- **Unit tokens** (case-insensitive, a trailing `s` or `.` is allowed):
  - `g`, `gr`, `gram` → g
  - `kg`, `kilogram` → kg
  - `ml`, `millilitre`, `milliliter` → ml
  - `l`, `litre`, `liter` → l
  - `tsp`, `teaspoon` → tsp
  - `tbsp`, `tbs`, `tblsp`, `tablespoon` → tbsp
  - `cup` → cup
- **No unit token**, or a size word (`large`, `medium`, `small`, `whole`), after the number → **pcs**.
- **Anything else** (`1 lb`, `2 cloves`, `pinch`, `to taste`, empty) → `quantity: null`, `unit: null`, `note` = the original measure text trimmed (no note if it is empty).

## Acceptance criteria

1. **AC-RD-1**: Searching "chicken" by name lists matching meals (title + thumbnail). An empty result shows "No recipes found".
2. **AC-RD-2**: Searching "salmon" by ingredient lists meals. Opening one loads its full detail (lookup).
3. **AC-RD-3**: *Surprise me* opens the detail of a random meal.
4. **AC-RD-4**: Measure parser table:

   | Input | Parsed |
   |---|---|
   | `"200g"` | 200 g |
   | `"1 1/2 cups"` | 1.5 cup |
   | `"3/4 cup"` | 0.75 cup |
   | `"2 tbs"` | 2 tbsp |
   | `"1 tsp."` | 1 tsp |
   | `"2"` | 2 pcs |
   | `"3 large"` | 3 pcs |
   | `"1 lb"` | null, note "1 lb" |
   | `"2 cloves"` | null, note "2 cloves" |
   | `"to taste"` | null, note "to taste" |
   | `""` | null, no note |

5. **AC-RD-5**: Importing a meal opens the Recipe form with the title, steps and every non-empty ingredient (all required, quantities parsed per AC-RD-4). Nothing is saved until the user taps Save. After Save, the recipe appears in Recipes with `source: themealdb` and gets an availability badge.
6. **AC-RD-6**: Importing a meal that was already imported shows "Already in your recipes" with Open, and creates no duplicate.
7. **AC-RD-7**: Being offline, a timeout or a 5xx response shows a localized error with **Retry**. There's no crash or spinner forever.
8. **AC-RD-8**: Works on Android and **web**. If the browser blocks the API (CORS), it's recorded as a blocker before this stage is accepted.
9. **AC-RD-9**: All UI chrome is in EN and ES. Recipe content stays in English.

## Tests

- `test/domain/mealdb_measure_parser_test.dart`: the AC-RD-4 table.
- `test/data/themealdb_service_test.dart` (`http` `MockClient` from `package:http/testing.dart`, no extra dependency): parsing of recorded sample JSON for search, filter, lookup and random; error mapping (AC-RD-7).
- `test/domain/meal_to_recipe_test.dart`: mapping, including skipping blank ingredients (AC-RD-5).
- `test/ui/discover/*_test.dart`: results, empty, error/retry, duplicate import (AC-RD-6), EN/ES.
- Manual: real API on web and Android (AC-RD-1 to AC-RD-3, AC-RD-8).

## Open questions

- TheMealDB's free test key `1` is meant for development and education. Is that acceptable for a personal app, or should we become a supporter for a production key? Check the terms before this stage ships.
- Confirm that browser requests aren't blocked by CORS (it's believed to be allowed; verify at implementation).
