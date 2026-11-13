# Review: Stage 0 close-out (docs only)

## 1. What & why

This records the Stage 0 status as checked on GitHub on 2026-11-12, and fixes the paths broken by moving the specs to `.claude/specs/`. Only verified items are ticked. One Stage 0 item, the format probe, is still open; your steps are below.

What GitHub showed:
- **Merge and tag:** PR #1 (`dev` → `main`) was merged with a merge commit, and CI is green on all 5 runs. `v0.0.0` is on the merge commit.
- **Rulesets:** `Dev PR` (squash only) and `Main PR` (merge only) are active, with 0 approvals and no bypass.
- **Required check:** both rulesets now require `flutter` (step A, verified).
- **Still open:** there's no format-probe PR (no failed run exists).
- **Kept as is:**
  - `v0.0.0` is lightweight (made on GitHub), not annotated.
  - Your "Task Completion" commit (`9dee216`) only exists on the deleted `ci` branch. Its ticks are redone here, limited to what's verified.

## 2. Files changed

**Docs**
- [SPEC.md](SPEC.md):
  - The project structure lists `.claude/specs/`.
  - The REVIEW.md path is now `.claude/specs/REVIEW.md`.
  - Stage 0 acceptance items 1, 3 and 4 are ticked. Item 1 notes that PR #1 went into `main`, not `dev`.
- [tasks/plan.md](../tasks/plan.md), [tasks/todo.md](../tasks/todo.md):
  - The spec links point to `../specs/SPEC.md`.
  - Tasks 5 and 8 are ticked, with notes on how they were done.
  - Task 7 is ticked (rulesets verified), and Task 6 is marked open, with the reason.

## 3. What to look for

1. **Acceptance item 1**, [SPEC.md:298](SPEC.md:298): ticked on the strength of PR #1 (into `main`). If you want it proven literally, the PR for this slice goes into `dev` and proves it.
2. **Task 6 is still open**, [todo.md:79](../tasks/todo.md:79). Acceptance item 2 stays unticked until the probe PR fails at Format.

## 4. How to verify

```bash
git status --short
```
Expected: `M` for `.claude/specs/REVIEW.md`, `.claude/specs/SPEC.md`, `.claude/tasks/plan.md` and `.claude/tasks/todo.md`.

Docs only, so there's no Dart to check. The links resolve from each file's own folder.

## 5. Proposed commit message

```
docs(spec): record Stage 0 status and fix paths after specs move

Point plan links, the REVIEW.md location and the project structure at
.claude/specs/. Tick the verified Stage 0 acceptance items (CI green on
a PR, version pin, Docker parity) and Task 7 (both rulesets require the
`flutter` check). The format-probe PR is still open.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

---

# Closing Stage 0 (your steps, in this order)

## A. Require the `flutter` check (Task 7): done, verified 2026-11-12

GitHub → **Settings → Rules → Rulesets → `Dev PR`** → tick **Require status checks to pass** → **Add checks** → `flutter` (source: GitHub Actions) → **Save changes**. Repeat for **`Main PR`**.

## B. Land this slice through a PR into `dev` (also proves acceptance item 1)

`dev` now refuses direct pushes, so:

```bash
git switch -c docs/stage-0-close dev
```
```bash
git add .claude/specs/REVIEW.md .claude/specs/SPEC.md .claude/tasks/plan.md .claude/tasks/todo.md && git commit
```
```bash
git push -u origin docs/stage-0-close
```
```bash
gh pr create --base dev --head docs/stage-0-close --title "docs(spec): record Stage 0 status and fix paths after specs move" --web
```

Wait for `flutter` to go green, then squash-merge.

## C. Format probe (Task 6, never merged)

```bash
git switch -c ci/format-probe dev
```
```bash
echo 'void   misformatted( ){}' >> lib/main.dart && git commit -am "test: deliberately mis-formatted (do not merge)"
```
```bash
git push -u origin ci/format-probe
```
```bash
gh pr create --draft --base dev --head ci/format-probe --title "DO NOT MERGE: CI format probe" --body "Stage 0 acceptance: CI must fail at the Format step."
```

Expected: `flutter` fails at **Format**, and the PR shows merging **blocked** by the required check (this proves A too). Then:

```bash
git switch dev && git pull --ff-only
```
```bash
gh pr close ci/format-probe --delete-branch
```

Optional cleanup of the stale `origin/ci` ref:
```bash
git fetch --prune
```

Tell me once A–C are done. I'll tick acceptance item 2 and Checkpoint B in the first `app-foundation` slice.
