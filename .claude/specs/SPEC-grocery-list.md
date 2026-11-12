# Module Spec: `grocery-list`

> Depends on: `households`, `inventory` · Used by: `restock-suggestions`, `recipes` (add to list) · Delivery: Stage 5
> Status: draft, awaiting review

## Objective

One live grocery list per household for the next shopping trip. Members add items, then check them off as they shop. When members split up in the store, each phone shows the others' checks within seconds, even with poor signal. When the trip is over, the bought items move into the inventory.

## Scope

**In**
- **Groceries screen**
  - Unchecked items first. Checked items go below, struck through, with the initial of whoever checked them.
  - **Sort** dropdown: *A–Z* (case- and accent-insensitive) or *By category* (section headers in `FoodCategory` order, A–Z inside each).
  - **Category filter** chips (multi-select; none selected = all).
  - Checkbox toggles `checked` and `checkedBy`. Swipe to delete, with an undo snackbar. Tap to edit.
  - Header area reserved for `restock-suggestions` (that module fills it).
- **Add item**: name (required, autocomplete from known names), category (defaults to the category last used for that `itemKey`, else Other), quantity + unit (default 1 pcs).
  - **Merge rule**: if an *unchecked* item with the same `itemKey` and a convertible unit exists, its quantity is increased instead of creating a duplicate.
- **Finish trip** button (enabled when ≥ 1 item is checked):
  - Opens a confirmation sheet listing the checked items with their default location and expiry.
  - On confirm, **one batch** does all of this for each checked item:
    - creates an inventory lot (bought today, location and expiry from category defaults) via `InventoryRepository.addToBatch`, which also writes `purchased` history
    - deletes the grocery item
  - Unchecked items stay on the list.
- Live sync and offline support for every action. Finish trip is a batch, so it works offline too.

**Out:**
- Multiple lists or stores, prices, aisle ordering, sharing outside the household.
- Per-item location or expiry prompts at Finish trip (edit them later in inventory, as decided).

## Data owned

| Path | Fields |
|---|---|
| `households/{hid}/grocery/{id}` | `name`, `itemKey`, `category`, `quantity` (> 0), `unit`, `checked` (bool), `checkedBy?` (uid), `addedBy`, `createdAt`, `source` (`manual`\|`suggestion`\|`recipe`) |

**Rules** (on top of `isMember`): the same field validation as inventory for name, category, unit and quantity; `source` must be in the enum; `checkedBy` is either null or `auth.uid` when `checked` changes to true.

Check and uncheck write only `checked` and `checkedBy` (`update()`, not `set()`). Two members checking different items at the same moment never overwrite each other.

## Interface exposed to other modules

```dart
class GroceryRepository {           // constructed with hid + InventoryRepository
  Stream<List<GroceryItem>> watchAll();
  Future<void> add(GroceryItem item);                 // applies merge rule
  Future<void> addAll(List<GroceryItem> items);       // merge rule per item, one batch; used by suggestions + recipes
  Future<void> setChecked(String id, bool checked);
  Future<void> update(GroceryItem item);
  Future<void> delete(String id);
  Future<int> finishTrip(List<GroceryItem> checked, DateTime today); // returns moved count
}
```

## Acceptance criteria

1. **AC-GL-1**: Adding "Eggs, 12 pcs, Dairy & eggs" shows it on the list. Member B sees it within ~2 s.
2. **AC-GL-2**: Adding "eggs, 6 pcs" while an unchecked "Eggs 12 pcs" exists leaves one entry of 18 pcs. Adding "Milk 500 ml" while "Milk 1 l" exists gives 1.5 l (or 1500 ml). If the only matching entry is checked, a new entry is created.
3. **AC-GL-3**: *A–Z* puts "álgebra bread", "Apples", "bananas" in that order (accents and case ignored). *By category* shows Vegetables, then Fruit, … with headers.
4. **AC-GL-4**: Selecting the chips Vegetables + Fruit shows only those categories. Clearing the chips shows everything.
5. **AC-GL-5**: Checking an item moves it below the unchecked items, struck through, with the checker's initial. Unchecking moves it back.
6. **AC-GL-6**: A checks "Apples" while B checks "Bread" at the same time. Within ~2 s both devices show both items checked.
7. **AC-GL-7**: An item checked while offline shows as checked immediately and appears on the other member's device after reconnecting.
8. **AC-GL-8**: Finish trip with 3 checked items (Milk, Bananas, Frozen peas) and 2 unchecked, on 2026-11-12:
   - The inventory gains Milk (Fridge, expiring 11-19), Bananas (Fridge, expiring 11-19) and Frozen peas (Freezer, expiring 2027-02-10), all bought 11-12.
   - There are 3 `purchased` history entries.
   - The list holds only the 2 unchecked items.
   - Either everything is written or nothing is (one batch).
9. **AC-GL-9**: Finish trip is disabled when nothing is checked. Cancelling the confirmation sheet changes nothing.
10. **AC-GL-10**: Validation (empty name, quantity ≤ 0) blocks saving. All texts are in EN and ES.
11. **AC-GL-11**: Rules: a non-member is denied; invalid fields are denied; `checkedBy` can't be set to another user's uid.

## Tests

- `test/data/grocery_repository_test.dart`: merge rule (AC-GL-2), field-only check updates, Finish trip batch contents and atomicity (AC-GL-8), cancel (AC-GL-9).
- `test/domain/grocery_sort_test.dart`: sort and filter (AC-GL-3, AC-GL-4) as pure functions.
- `test/ui/grocery/*_test.dart`: ordering of checked/unchecked items, chips, disabled Finish trip, EN/ES.
- `firebase/test/grocery.test.js`: AC-GL-11.
- Manual: two devices, simultaneous checks (AC-GL-6), airplane mode (AC-GL-7).

## Known v1 limit

`shortcut:` if two members tap Finish trip at the same moment, both batches may add the same items to the inventory. Upgrade to a transaction (which requires being online) if this happens in practice.

## Open questions

- Should Finish trip move only the items *I* checked (useful when splitting up and finishing separately), or all checked items (proposed)?
