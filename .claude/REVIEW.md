# Review: spec slice (docs only)

## 1. What & why

This adds the project spec, which is the first step of spec-driven development before any code. [SPEC.md](SPEC.md) holds the project-wide rules: stack, commands, structure, style, testing, boundaries, the approved capability map, the Firestore data model, a stage-by-stage **DevOps & Delivery** plan, and how we work together. There is one `SPEC-<module-id>.md` per module, each with numbered, testable acceptance criteria. No app code changed.

## 2. Files changed

**Specs (new)**
- [SPEC.md](SPEC.md): project spec and the index of module specs (capability map, data model, DevOps stages 0–8, release and rollback, success criteria, open questions)
- [SPEC-app-foundation.md](SPEC-app-foundation.md): Firebase and emulator wiring, app shell, EN/ES, shared categories, units, `itemKey`, rules harness
- [SPEC-identity.md](SPEC-identity.md): email + Google sign-in, unique username claim, user and username rules
- [SPEC-households.md](SPEC-households.md): create household, invite by username, accept/decline/leave, membership rules
- [SPEC-inventory.md](SPEC-inventory.md): Food Managing (fridge/freezer/cabinet, quantities, dates, expiry badges, consume, history)
- [SPEC-grocery-list.md](SPEC-grocery-list.md): live shared list, merge rule, sort/filter, check-off, Finish trip → inventory
- [SPEC-restock-suggestions.md](SPEC-restock-suggestions.md): minimum stock levels + regular-purchase suggestions, healthy first
- [SPEC-recipes.md](SPEC-recipes.md): recipe book, starter set seeding, availability, filters, add all/missing to list
- [SPEC-recipe-discovery.md](SPEC-recipe-discovery.md): TheMealDB browse and import, measure parser

**Config**
- [.gitignore](.gitignore): ignores `/REVIEW.md`, and adds the missing final newline

## 3. What to look for

1. **Capability map and build order**, [SPEC.md:215](SPEC.md:215). Module ids are permanent once approved. Check the boundaries and order.
2. **Data model**, [SPEC.md:241](SPEC.md:241). Changing it later costs migrations. In particular, check that items match across sections only by normalized name, and the stated limit that "tomato" ≠ "tomatoes" ≠ "tomate".
3. **Membership rules**, [SPEC-households.md:42](SPEC-households.md:42). This is the security core: who can join, leave and read household data.
4. **Collaboration protocol + DevOps stages**, [SPEC.md:271](SPEC.md:271) and [SPEC.md:283](SPEC.md:283). Check that they match how you want to work: you own all git writes, squash-merge into `dev`, and a merge commit for `dev` → `main` per stage.
5. **Proposed defaults to confirm**:
   - shelf life and default locations per category, [SPEC-app-foundation.md:47](SPEC-app-foundation.md:47)
   - suggestion thresholds, [SPEC-restock-suggestions.md:20](SPEC-restock-suggestions.md:20)
   - Finish trip "all checked items" vs "only mine", in the open questions of [SPEC-grocery-list.md](SPEC-grocery-list.md)

I'm unsure of two technical points, which are flagged as open questions to verify at implementation: TheMealDB CORS on web, and Google sign-in on Android through `signInWithProvider` without the `google_sign_in` package.

## 4. How to verify

There's nothing to run; this slice is documentation only.
- Read [SPEC.md](SPEC.md) top to bottom, then each module spec in build order.
- Check each part of your original request against a spec:
  - Food Managing (fridge/freezer/cabinet, quantity, bought date, expiry) → inventory
  - grocery list, manual add, suggestions (healthy/regular), A–Z/category filter, to-do check-off → grocery-list + restock-suggestions
  - recipes with required/optional quantities, A–Z/availability dropdowns, ingredient selection, add all/missing → recipes
  - public recipe ideas and import → recipe-discovery
  - sharing with your girlfriend by username, live → households
  - "where in the fridge" → listed as out of scope (future)
- Answer the **Open Questions** in [SPEC.md:349](SPEC.md:349). Your answers will be folded back into the specs.

```bash
git status --short
```

Expected: `M .gitignore` plus the 9 new `SPEC*.md` files. `REVIEW.md` isn't listed (it's ignored).

## 5. Proposed commit message

```
docs(spec): add project spec, capability map and module specs

Add SPEC.md (objective, tech stack, commands, structure, code style,
testing strategy, boundaries, capability map, Firestore data model,
DevOps & delivery stages, success criteria, open questions) and one
SPEC-<module-id>.md per module: app-foundation, identity, households,
inventory, grocery-list, restock-suggestions, recipes, recipe-discovery.

Ignore REVIEW.md (per-slice review notes, never committed).
```
