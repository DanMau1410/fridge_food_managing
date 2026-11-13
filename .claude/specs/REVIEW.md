# Review: Stage 0 complete (docs only)

## 1. What & why

This closes [SPEC.md › Stage 0](SPEC.md#stage-0-baseline). Every acceptance item is now ticked, and each one was checked on GitHub with read-only API calls on 2026-11-12:
- **PR into `dev`:** PR #2 was squash-merged into `dev`, with CI green on the PR and on the push.
- **Format probe:** PR #3 failed at **Format**; Analyze, Test and Build web were skipped. It was closed unmerged and its branch deleted.
- **Rulesets:** `Dev PR` (squash only) and `Main PR` (merge only) both require `flutter`.
- **Release:** `v0.0.0` is on `main`.

## 2. Files changed

**Docs**
- [SPEC.md](SPEC.md): acceptance item 2 is ticked (PR #3), and item 1's note now cites PR #2 into `dev`.
- [tasks/plan.md](../tasks/plan.md): status is "complete", and Task 6 and Checkpoint B are ticked.
- [tasks/todo.md](../tasks/todo.md): Task 6 (with the evidence), Task 2's GitHub proof, and Checkpoint B are ticked. Only "Next: plan `app-foundation`" stays open.

## 3. What to look for

1. [SPEC.md:298-301](SPEC.md:298): all four Stage 0 items, each with its evidence.

## 4. How to verify

```bash
git diff --stat
```
Expected: `.claude/specs/REVIEW.md`, `.claude/specs/SPEC.md`, `.claude/tasks/plan.md` and `.claude/tasks/todo.md`, docs only.

## 5. Proposed commit message

```
docs(spec): mark Stage 0 complete

Tick the last Stage 0 acceptance item (PR #3 failed at the Format step
and was closed unmerged) and cite PR #2 for the CI-on-PR item. Mark
the Stage 0 plan complete.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

---

# Landing it

`dev` only accepts PRs. Either open a small PR now:

```bash
git switch -c docs/stage-0-done dev
```
```bash
git add .claude/specs/REVIEW.md .claude/specs/SPEC.md .claude/tasks/plan.md .claude/tasks/todo.md && git commit
```
```bash
git push -u origin docs/stage-0-done
```
```bash
gh pr create --base dev --head docs/stage-0-done --title "docs(spec): mark Stage 0 complete" --web
```

…or keep the edits uncommitted and branch `feat/app-foundation-<slug>` off `dev` when Stage 1 starts, so they ride along with the first slice. Either way, nothing needs to go to `main` now: these docs reach `main` with the Stage 1 merge.

# Cleanup (optional)

The merged branch `docs/stage-0-close` still exists on GitHub and on your machine. Use `-D`, because a squash merge doesn't look "merged" to git:

```bash
git branch -D docs/stage-0-close
```
```bash
git push origin --delete docs/stage-0-close
```
```bash
git fetch --prune
```

To have GitHub delete merged branches for you, go to **Settings → General → Pull Requests** and tick **Automatically delete head branches**.

# Before Stage 1 (`app-foundation`)

These are from [SPEC-app-foundation.md](SPEC-app-foundation.md), and only you can do them:
1. Create the Firebase project, and enable Auth (Email/Password + Google) and Firestore.
2. Run `flutterfire configure --platforms=android,web` (needs the `flutterfire` CLI and your Google login).
3. Answer the spec's open questions: the shelf-life and default-location table, and whether to split `grainsBread`.
