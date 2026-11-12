# Module Spec: `inventory` ("Food Managing")

> Depends on: `households` · Used by: `grocery-list` (Finish trip), `restock-suggestions`, `recipes` (availability) · Delivery: Stage 4
> Status: draft, awaiting review

## Objective

Show the household what food it has, where it is (fridge, freezer, cabinet), how much, when it was bought and when it expires. Food that is about to go bad stands out. Every change is shared live with the household, and purchases and consumption are recorded as history for restock suggestions.

## Scope

**In**
- **Food screen**: tabs **Fridge | Freezer | Cabinet**.
  - Each tab lists its items sorted by expiry (soonest first; items without expiry last), then by name.
  - Each row shows the name, quantity + unit, "Bought <date>", and "Expires <date>" with a badge:
    - **Expired**: expiry date before today (error color)
    - **Expiring soon**: expiry within the next 3 days, today included (warning color)
  - Each tab title shows its count of expiring and expired items.
- **Add item** (FAB):
  - name, required, with autocomplete from names known in the household (inventory + history)
  - category; location (defaults from category)
  - quantity > 0 + unit
  - bought date (defaults to today)
  - expiry date (optional; defaults to bought date + the category's shelf life when it has one)
  - The defaults update when the category changes, until the user edits that field themselves.
- **Edit item**: every field.
- **Consume**: enter an amount (default = the whole item) and the quantity drops by that amount. Reaching 0 deletes the item. Records a `consumed` history entry.
- **Discard / delete**: removes the item with no history entry (thrown away or entered by mistake). Confirmed with an undo snackbar.
- **History**: every add (manual or from Finish trip) writes a `purchased` entry; every consume writes a `consumed` entry.
- **Live sync** across members; works offline (queued writes).

**Out:**
- Position inside the fridge. Planned for later: add an optional `spot` field, no migration needed.
- Barcode scanning, photos, expiry notifications, merging lots of the same item.

## Data owned

| Path | Fields |
|---|---|
| `households/{hid}/inventory/{id}` | `name`, `itemKey`, `category`, `location`, `quantity` (num > 0), `unit`, `acquiredOn` (`yyyy-MM-dd`), `expiresOn?` (`yyyy-MM-dd`), `addedBy` (uid), `updatedAt` (Timestamp) |
| `households/{hid}/history/{id}` | `itemKey`, `name`, `category`, `type` (`purchased`\|`consumed`), `quantity`, `unit`, `at` (Timestamp), `by` (uid) |

**Rules** (on top of `isMember`)
- **inventory**: `name` is a non-empty string ≤ 60 chars; `itemKey` is a string; `category`, `location` and `unit` are valid enum names; `quantity` is a number > 0; `acquiredOn`/`expiresOn` match `^\d{4}-\d{2}-\d{2}$`.
- **history**: create-only (no update or delete); `type` ∈ {purchased, consumed}; `by == auth.uid`.

The same item bought twice is stored as two docs ("lots"), each with its own dates. Stock of an item = the sum of its lots, converted to a common unit.

## Interface exposed to other modules

```dart
class InventoryRepository {          // constructed with hid
  Stream<List<InventoryItem>> watchAll();
  Future<void> add(InventoryItem item);                       // + purchased history, one batch
  void addToBatch(WriteBatch batch, InventoryItem item);      // used by Finish trip (+ history)
  Future<void> update(InventoryItem item);
  Future<void> consume(String id, Quantity amount);           // decrement or delete + consumed history
  Future<void> delete(String id);
  Stream<List<HistoryEntry>> watchHistory({required DateTime since});
  Stream<List<String>> watchKnownNames();                     // autocomplete source
}

// lib/domain/stock.dart — pure
Quantity? onHand(List<InventoryItem> items, String itemKey, Unit unit);
// null = has lots whose units can't convert to `unit` (amount unknown); Quantity(0) = none
bool isExpiringSoon(InventoryItem item, DateTime today);      // expiresOn in [today, today+3d]
bool isExpired(InventoryItem item, DateTime today);           // expiresOn < today
InventoryItem withCategoryDefaults(String name, FoodCategory c, DateTime today); // location + expiry defaults
```

## Acceptance criteria

1. **AC-INV-1**: Adding "Milk" with category Dairy & eggs on 2026-11-12 prefills location **Fridge**, bought **2026-11-12** and expiry **2026-11-19**. All are editable before saving, and the saved doc has `itemKey: "milk"`.
2. **AC-INV-2**: An empty name, quantity ≤ 0, a non-numeric quantity, or an expiry earlier than the bought date blocks saving with a field message, and nothing is written.
3. **AC-INV-3**: Under the Fridge tab, items appear in this order: expiry 11-13 → 11-20 → no expiry. Items in other locations don't appear.
4. **AC-INV-4**: With today = 2026-11-12:
   - expiry 2026-11-15 → "Expiring soon"
   - expiry 2026-11-16 → no badge
   - expiry 2026-11-11 → "Expired"
5. **AC-INV-5**: Consuming 2 of "Eggs 6 pcs" leaves 4 pcs and writes `history {type: consumed, quantity: 2, unit: pcs}`.
6. **AC-INV-6**: Consuming the whole amount removes the item and writes a consumed history entry. Consuming more than is on hand is rejected.
7. **AC-INV-7**: Delete removes the item with no history entry. Undo within the snackbar restores it.
8. **AC-INV-8**: Every add writes exactly one `purchased` history entry in the same batch as the item.
9. **AC-INV-9**: `onHand` for itemKey `rice` with lots 1 kg + 500 g:
   - in g → 1500 g
   - with an extra lot of "rice 2 pcs", in g → `null` (amount unknown)
   - with no lots → 0
10. **AC-INV-10**: Member B sees A's add, edit, consume and delete within ~2 s, without a refresh. Edits made offline apply on reconnect.
11. **AC-INV-11**: Dates display in locale format (EN "Nov 12, 2026", ES "12 nov 2026"). Category, location and unit labels are localized.
12. **AC-INV-12**: Rules: a non-member is denied; invalid field values (quantity 0, unknown category, bad date format) are denied; a history entry cannot be updated or deleted.

## Tests

- `test/domain/stock_test.dart`: AC-INV-4, AC-INV-9, and `withCategoryDefaults` (AC-INV-1).
- `test/data/inventory_repository_test.dart`: AC-INV-5 to AC-INV-8 (batch contents, history entries).
- `test/ui/inventory/*_test.dart`: form validation (AC-INV-2), ordering (AC-INV-3), badges, EN/ES (AC-INV-11).
- `firebase/test/inventory.test.js`: AC-INV-12.
- Manual: two devices (AC-INV-10).

## Open questions

- "Expiring soon" window: 3 days (proposed).
- Should the Food screen also have an **All** tab or a search box? Not requested; out of scope unless asked.
