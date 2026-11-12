# Review: Stage 0, DevOps baseline (single slice)

## 1. What & why

This delivers [SPEC.md › Stage 0](SPEC.md#stage-0-baseline) per the approved [plan](tasks/plan.md):
- Flutter is pinned to exactly 3.47.6 and `pubspec.lock` is enforced everywhere.
- A CI job `flutter` runs on every PR and on pushes to `dev`/`main`.
- `docker compose run --rm test` runs the same five checks as CI.

The app itself is unchanged. It also fixes a bind-mount problem: Docker runs could overwrite the host's `.dart_tool` or leave root-owned files behind.

## 2. Files changed

**CI**
- [.github/workflows/ci.yml](../.github/workflows/ci.yml) (new): job `flutter` with a read-only token. Steps: checkout → flutter-action (version read from `pubspec.yaml`, cache on) → locked pub get → format → analyze → test → web release build.

**Config**
- [pubspec.yaml](../pubspec.yaml): `environment.flutter: 3.47.6` (exact) and `version: 0.0.0+1` (was `1.0.0+1`).
- [pubspec.lock](../pubspec.lock): only `sdks.flutter` changes, to `"3.47.6"`. No package versions changed.
- [Dockerfile](../Dockerfile): both `pub get` lines use `--enforce-lockfile`.
- [docker-compose.yml](../docker-compose.yml): `test` runs the five CI commands. `dev` and `test` keep `.dart_tool/` and `build/` in container-only anonymous volumes.

**Docs**
- [tasks/plan.md](tasks/plan.md), [tasks/todo.md](tasks/todo.md) (new): the approved Stage 0 plan, with Phase 1 ticked.
- [SPEC.md](SPEC.md): plan paths now point to `.claude/tasks/` (Project Structure + module loop step 2).

## 3. What to look for

1. **The pin**, [pubspec.yaml:24](../pubspec.yaml:24). Every Flutter install (host, Docker, CI) must now be exactly 3.47.6. A Flutter upgrade becomes one commit that changes this line, the [Dockerfile:3](../Dockerfile:3) `ARG` and `pubspec.lock` together.
2. **Triggers and permissions**, [ci.yml:3-9](../.github/workflows/ci.yml:3). `pull_request` fires for PRs into *any* branch. Actions are pinned by major tag (`checkout@v7` is v7.0.1 today, `flutter-action@v2` is v2.23.0), not by SHA, because there's no Dependabot to bump SHAs.
3. **Anonymous volumes**, [docker-compose.yml:12-14](../docker-compose.yml:12) and [:40-41](../docker-compose.yml:40). This changes behaviour: a `build/web` produced inside `dev`/`test` no longer appears on the host. The `web` service is unaffected (it builds inside the image).
4. **Duplicated command list**, [docker-compose.yml:32](../docker-compose.yml:32) vs [ci.yml:20-30](../.github/workflows/ci.yml:20). Keep them identical. A comment in `ci.yml` says so.

## 4. How to verify

What I ran (all as expected):

```bash
flutter pub get --enforce-lockfile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test && flutter build web --release
```
Expected: "No issues found!", "All tests passed!", "✓ Built build/web".

```bash
docker compose build test && docker compose run --rm test
```
Expected: exit 0, ending in "✓ Built build/web". Afterwards, this prints nothing:
```bash
find . -user root -not -path './.git/*'
```

Negative checks (revert each afterwards):
- Set `flutter: 3.48.0` in `pubspec.yaml`, then run `flutter pub get`. Expected: "requires Flutter SDK version 3.48.0, version solving failed".
- Append `void   misformatted( ){}` to `lib/main.dart`, then run `docker compose run --rm test`. Expected: exit 1 with "Changed lib/main.dart", and analyze/build never start.
- `docker compose up -d dev` served HTTP 200 on :8080, and the host `.dart_tool/package_config.json` stayed byte-identical.

Not verified (GitHub side, your steps below): the workflow running on Actions, the format-probe PR, and branch protection.

```bash
git status --short
```
Expected: `M` for `.claude/REVIEW.md`, `.claude/SPEC.md`, `Dockerfile`, `docker-compose.yml`, `pubspec.lock`, `pubspec.yaml`; `??` for `.claude/tasks/` and `.github/`.

## 5. Proposed commit message

```
ci: add Stage 0 baseline (pinned Flutter, locked deps, CI, Docker parity)

Pin Flutter 3.47.6 exactly in pubspec.yaml (CI reads it through
flutter-version-file; pub get fails on any other version) and set
version 0.0.0+1. Enforce pubspec.lock in CI, the Docker test service
and both Dockerfile pub get steps.

Add the CI workflow: job `flutter` (locked pub get, format, analyze,
test, web release build) on every PR and on pushes to dev and main,
with a read-only token.

Make `docker compose run --rm test` run the same checks, and keep the
container's .dart_tool/ and build/ in anonymous volumes so Docker runs
no longer leave root-owned or container-path files on the host.

Add the Stage 0 plan under .claude/tasks/ and point SPEC.md at it.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

---

# Stage 0 close-out (your GitHub steps)

## Task 5: Branch, commit, PR → `dev`

```bash
git switch -c ci/stage-0-baseline dev
```
```bash
git add .github/workflows/ci.yml Dockerfile docker-compose.yml pubspec.yaml pubspec.lock .claude/REVIEW.md .claude/SPEC.md .claude/tasks
```
```bash
git commit
```
```bash
git push -u origin ci/stage-0-baseline
```
```bash
gh pr create --base dev --head ci/stage-0-baseline --title "ci: Stage 0 baseline (pinned Flutter, locked deps, CI, Docker parity)" --web
```

PR body to paste:

```markdown
## Stage 0: DevOps baseline

Spec: `.claude/SPEC.md` › Stage 0 · Plan: `.claude/tasks/plan.md`

- Flutter pinned to exactly 3.47.6 (`pubspec.yaml`, read by CI); `pub get` fails on any other version
- `pubspec.lock` enforced in CI, the Docker `test` service and the Dockerfile
- CI job `flutter`: locked pub get → format → analyze → test → web release build, on every PR and on pushes to dev/main
- `docker compose run --rm test` = the same checks; `.dart_tool/` and `build/` stay inside the container
- Version `0.0.0+1`; no app changes

Verified locally: host gate green, Docker gate green, mis-format fails at Format (exit 1), pin mismatch fails `pub get`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Expected: the **flutter** check goes green on the PR.

## Task 6: Prove CI fails at the format step (throwaway, never merged)

```bash
git switch -c ci/format-probe ci/stage-0-baseline
```
```bash
echo 'void   misformatted( ){}' >> lib/main.dart && git commit -am "test: deliberately mis-formatted (do not merge)"
```
```bash
git push -u origin ci/format-probe
```
```bash
gh pr create --draft --base ci/stage-0-baseline --head ci/format-probe --title "DO NOT MERGE: CI format probe" --body "Stage 0 acceptance: CI must fail at the Format step."
```

Expected: the `flutter` check fails at **Format**, and Analyze/Test/Build are skipped. Then clean up:

```bash
git switch ci/stage-0-baseline
```
```bash
gh pr close ci/format-probe --delete-branch
```

## Task 7: Branch protection, then merge the Task 5 PR

Do this after Task 5's CI has run once, so `flutter` can be selected as a required check. On a **private** repo, rulesets and branch protection need a paid GitHub plan; on a public repo they're free.

GitHub → **Settings → Rules → Rulesets → New branch ruleset**. Create two, because each branch has a different merge method:

| Ruleset | Target | Rules |
|---|---|---|
| `dev` | branch `dev` | Restrict deletions · Block force pushes · Require a pull request (required approvals **0**, allowed merge method **Squash**) · Require status checks: `flutter` |
| `main` | branch `main` | Same, but allowed merge method **Merge** |

Enforcement: **Active**. Bypass list: leave it empty for strict protection, or add yourself as an emergency override (a conscious choice; see the plan's risks). Approvals must be **0**, or you can't merge your own PRs.

Then squash-merge the Task 5 PR on GitHub.

## Task 8: Stage PR `dev` → `main`, then tag

```bash
gh pr create --base main --head dev --title "Stage 0: DevOps baseline" --web
```

PR body to paste:

```markdown
## Stage 0: DevOps baseline → main

Delivers SPEC.md › Stage 0. No app or data changes.

Acceptance (SPEC.md › Stage 0):
- [x] A trivial PR to `dev` runs CI and it's green (Task 5)
- [x] A mis-formatted Dart file fails CI at the format step (Task 6, PR closed unmerged)
- [x] Changing `environment.flutter` makes `flutter pub get` fail locally
- [x] `docker compose run --rm test` runs the same checks as CI and passes

Rules/data: none (no Firebase yet).

Rollback: `git revert -m 1 <merge-commit>` on `main`, or `git revert <squash-commit>` on `dev`. Nothing is deployed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Merge it with **Create a merge commit**. Then:

```bash
git switch main && git pull --ff-only
```
```bash
git tag -a v0.0.0 -m "Stage 0: DevOps baseline"
```
```bash
git push origin v0.0.0
```

```bash
git switch dev && git pull --ff-only
```

Once Tasks 5–8 are done, tell me. I'll tick the Stage 0 acceptance boxes in SPEC.md (Checkpoint B), and that change goes into the first `app-foundation` slice.
