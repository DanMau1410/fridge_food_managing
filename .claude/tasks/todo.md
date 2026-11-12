# Stage 0 Tasks: DevOps Baseline

> Plan: [plan.md](plan.md) · Spec: [SPEC.md › Stage 0](../SPEC.md#stage-0-baseline)
> Before Task 1 (user): `git switch -c ci/stage-0-baseline dev`

## Task 1: Pin Flutter, enforce the lockfile, set the stage version

**Description:** Add `environment.flutter: 3.47.6` (exact) to `pubspec.yaml` so any other Flutter version fails `pub get`, and refresh `pubspec.lock` to match. Switch both Dockerfile `pub get` lines to `--enforce-lockfile`. Set `version: 0.0.0+1`.

**Acceptance criteria:**
- [x] `pubspec.yaml` has `flutter: 3.47.6` under `environment` and `version: 0.0.0+1`
- [x] `flutter pub get --enforce-lockfile` passes on the host with the refreshed lock
- [x] Temporarily pinning `3.48.0` makes `flutter pub get` fail with "requires Flutter SDK version 3.48.0" (then revert)

**Verification:**
- [x] `flutter pub get --enforce-lockfile && flutter test`
- [x] `docker compose build test` succeeds (the Dockerfile `pub get` respects the lock and the pin)

**Dependencies:** None
**Files:** `pubspec.yaml`, `pubspec.lock`, `Dockerfile`
**Scope:** XS

## Task 2: CI workflow, job `flutter`

**Description:** Add `.github/workflows/ci.yml`. It runs on every `pull_request`, and on `push` to `dev` and `main`, with `permissions: contents: read`. Job `flutter` on `ubuntu-latest` runs `actions/checkout@v7` → `subosito/flutter-action@v2` (`flutter-version-file: pubspec.yaml`, `cache: true`), then one named step each for `flutter pub get --enforce-lockfile`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test` and `flutter build web --release`.

**Acceptance criteria:**
- [x] The workflow has exactly the triggers, permissions, job name and step order above
- [x] The Flutter version comes only from `pubspec.yaml` (no hard-coded version in the workflow)

**Verification:**
- [x] The same five commands, run on the host in order, all exit 0
- [ ] The real proof is Tasks 5–6 on GitHub

**Dependencies:** Task 1 (`flutter-version-file` needs the pin)
**Files:** `.github/workflows/ci.yml`
**Scope:** XS

## Task 3: Docker `test` service = CI checks, with the bind-mount fix

**Description:** Change the Compose `test` command to the same five CI commands. On `dev` and `test`, add anonymous volumes `/app/.dart_tool` and `/app/build`, so the container never writes into the host's `.dart_tool`/`build` and leaves no root-owned files.

**Acceptance criteria:**
- [x] `docker compose run --rm test` runs pub get (enforced) → format → analyze → test → build web, and exits 0
- [x] Right after a Docker run, host `flutter test` passes with no `pub get` first, and `find . -user root -not -path './.git/*'` prints nothing
- [x] A deliberately mis-formatted line in `lib/main.dart` fails both the host gate and `docker compose run --rm test` at the format step (then revert)

**Verification:**
- [x] `docker compose build test && docker compose run --rm test`
- [x] The host checks above

**Dependencies:** Task 1
**Files:** `docker-compose.yml`
**Scope:** XS

## Checkpoint A: Local gate

- [x] Tasks 1–3 verifications all green; negative checks reverted, `git status` shows only the intended files
- [x] Task 4 written → user reviews and commits

## Task 4: REVIEW.md for the slice and the stage

**Description:** Overwrite `.claude/REVIEW.md` with the five-part slice summary. Add a draft PR title and body for `ci/stage-0-baseline` → `dev`, the throwaway mis-format PR commands (Task 6), branch-protection steps (Task 7), a draft `dev` → `main` PR with a rollback note, and the `v0.0.0` annotated-tag commands (Task 8).

**Acceptance criteria:**
- [x] Every git and GitHub step is a command or click path for the user. Claude runs none of them
- [x] There's a proposed commit message: `ci: add Stage 0 baseline (pinned Flutter, locked deps, CI, Docker parity)`

**Verification:**
- [x] The user reads REVIEW.md and can complete Phase 2 from it alone

**Dependencies:** Tasks 1–3
**Files:** `.claude/REVIEW.md`
**Scope:** XS

## Phase 2: GitHub (the user)

- [ ] **Task 5**: Push `ci/stage-0-baseline` and open a PR → `dev`. The `flutter` check is green.
- [ ] **Task 6**: A throwaway branch off `ci/stage-0-baseline` with one mis-formatted line, opened as a draft PR. CI fails at the **format** step. Close it unmerged and delete the branch.
- [ ] **Task 7**: Protect `dev` and `main`: require a PR, require status check `flutter`, block force-push and deletion. Then squash-merge the Task 5 PR.
- [ ] **Task 8**: PR `dev` → `main`, merged with a **merge commit**, then `git tag -a v0.0.0` and push the tag.

## Checkpoint B: Stage 0 done

- [ ] The user confirms Tasks 5–8, and Claude ticks the four Stage 0 acceptance boxes in `.claude/SPEC.md`
- [ ] Next: plan `app-foundation` (Stage 1), only when the user asks
