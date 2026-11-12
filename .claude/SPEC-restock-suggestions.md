# Module Spec: `restock-suggestions`

> Depends on: `inventory`, `grocery-list` · Used by: — · Delivery: Stage 6 (in parallel with `recipes`)
> Status: draft, awaiting review

## Objective

Suggest what to buy before it runs out, using two signals: **minimum stock levels** the household sets ("always have 6 eggs") and **regular purchases** inferred from history. Healthy items are ranked first, and any suggestion goes onto the grocery list in one tap.

## Scope

**In**
- A **Suggestions panel** at the top of the Groceries screen (collapsible). Each suggestion shows the name, suggested quantity, reason ("Below minimum 6 pcs", "You buy this often") and a healthy marker, with an **Add** button.
  - Panel actions: **Add all**, **Healthy only** toggle.
- **Minimum stock** screen (opened from the panel): list, add, edit and delete minimum levels (item name with autocomplete, category, min quantity + unit). There is also a shortcut "Set minimum…" in an inventory item's menu.
- A pure function computes suggestions from inventory, history, stock levels, the grocery list and today's date.

**Out:** dismissing or snoozing a suggestion, machine learning, nutrition data, notifications.

## Rules for suggestions (pure, `lib/domain/suggestions.dart`)

Inputs: `inventory`, `history` (last 60 days), `stockLevels`, `grocery`, `today`.

1. **Below minimum**: for each stock level, compute `onHand(itemKey, level.unit)`.
   - If it is known and less than `minQuantity`, suggest `minQuantity − onHand` in `level.unit`.
   - If it is `null` (amount unknown), don't suggest.
2. **Regular purchase**: an `itemKey` with **≥ 3** `purchased` history entries whose `at` is within the last **60 days**.
   - Suggest it if `onHand == 0`, **or** every lot of it has `expiresOn ≤ today + 2 days`.
   - Suggested quantity = the quantity and unit of the most recent purchase.
3. **Exclude** any `itemKey` that has an **unchecked** grocery item.
4. **One suggestion per item**: if both rules match, keep the below-minimum quantity and list both reasons.
5. **Order**: healthy first (from `FoodCategory.healthy`), then below-minimum before regular, then name A–Z.

Thresholds (3 purchases, 60 days, 2 days) are constants in `lib/config/`.

## Data owned

| Path | Fields |
|---|---|
| `households/{hid}/stockLevels/{itemKey}` | `name`, `category`, `minQuantity` (> 0), `unit` |

Doc id = `itemKey`, so there is one minimum per item. **Rules**: on top of `isMember`, the doc id must equal `itemKey(name)` as written (checked by the client; rules check that the field types are valid and `minQuantity > 0`).

## Interface

```dart
class StockLevelRepository {        // constructed with hid
  Stream<List<StockLevel>> watchAll();
  Future<void> set(StockLevel level);
  Future<void> delete(String itemKey);
}

List<Suggestion> computeSuggestions({
  required List<InventoryItem> inventory,
  required List<HistoryEntry> history,
  required List<StockLevel> stockLevels,
  required List<GroceryItem> grocery,
  required DateTime today,
});
```

`SuggestionsViewModel` combines the four streams (inventory, history since today − 60 d, stock levels, grocery) and recomputes on any change. Add and Add all call `GroceryRepository.add`/`addAll` with `source: suggestion`.

## Acceptance criteria

All dates assume today = 2026-11-12.

1. **AC-RS-1**: Minimum eggs 6 pcs, inventory 2 pcs → suggestion "Eggs 4 pcs — Below minimum".
2. **AC-RS-2**: Minimum milk 2 l, inventory 1500 ml → suggestion "Milk 0.5 l".
3. **AC-RS-3**: Minimum rice 1 kg, inventory has only "rice 2 pcs" (unconvertible) → no suggestion.
4. **AC-RS-4**: Bananas bought on 10-01, 10-20 and 11-05 (last purchase 6 pcs), none in inventory → "Bananas 6 pcs — You buy this often".
5. **AC-RS-5**: The same purchases but the first was on 09-12 (61 days ago) → no suggestion, since only 2 fall in the window.
6. **AC-RS-6**: Bananas are regular and their only lot expires 11-14 → suggested. A second lot expiring 11-17 → not suggested.
7. **AC-RS-7**: Eggs are below minimum **and** on the grocery list unchecked → not suggested. If the grocery entry is checked → suggested.
8. **AC-RS-8**: Eggs match both rules → one suggestion with both reasons, using the below-minimum quantity.
9. **AC-RS-9**: With Spinach (vegetables), Chips (snacks) and Salmon (fish) suggested, the order is Salmon, Spinach, Chips (healthy A–Z, then the rest). *Healthy only* hides Chips.
10. **AC-RS-10**: Tapping Add on Eggs adds it to the grocery list with `source: suggestion` (merge rule applies), and it disappears from suggestions within ~2 s. Add all adds every visible suggestion in one batch.
11. **AC-RS-11**: Minimum stock screen: creating, editing and deleting a level updates the suggestions live. A min quantity ≤ 0 is rejected.
12. **AC-RS-12**: All texts, including the reasons, are in EN and ES. Rules: a non-member is denied; `minQuantity ≤ 0` is denied.

## Tests

- `test/domain/suggestions_test.dart`: table tests for AC-RS-1 to AC-RS-9 with a fixed `today`. This is the core test file of the module.
- `test/data/stock_level_repository_test.dart`: AC-RS-11 writes.
- `test/ui/suggestions/*_test.dart`: panel rendering, Healthy only toggle, Add/Add all calls (AC-RS-10), EN/ES.
- `firebase/test/stock_levels.test.js`: AC-RS-12 rules.

## Open questions

- Thresholds (3 purchases / 60 days / 2 days): keep them as proposed?
- Should there be a way to say "stop suggesting this" (snooze/ignore)? Out of scope unless requested.
