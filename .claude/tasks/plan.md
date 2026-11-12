# Implementation Plan: Stage 0, DevOps Baseline

> Source: [SPEC.md › Stage 0: Baseline](../SPEC.md#stage-0-baseline) · Status: **approved 2026-11-12** · 2026-11-12
> Tasks: [todo.md](todo.md)

## Overview

This is one PR into `dev`, before any feature code. It makes every later slice **stable** (CI must be green), **reproducible** (the same Flutter version and locked deps on the host, in Docker and in CI) and **backtrackable** (squash-merge per slice, a merge commit and tag per stage). The app itself doesn't change. The template `FridgePage` stays until `app-foundation`.

## Starting point (verified 2026-11-12)

- Local Flutter 3.47.6 / Dart 3.13.5, matching the Dockerfile's `ARG FLUTTER_VERSION=3.47.6`. Docker 29.9 and Compose v5.6 are installed.
- `pubspec.yaml` has no `environment.flutter` yet, `version: 1.0.0+1`, and `pubspec.lock` is committed.
- There's no `.github/`. The Compose `test` service runs only `flutter analyze && flutter test`, and the Dockerfile runs a plain `flutter pub get`.
- `dart format --set-exit-if-changed .` is already clean.
- Probe: an exact pin `flutter: 3.47.5` **and** `flutter: 3.48.0` both make `flutter pub get` fail on 3.47.6, so the pin rejects other versions in both directions.

## Architecture decisions

- **One version source for CI.** `environment.flutter: 3.47.6` (exact) in `pubspec.yaml`, which `subosito/flutter-action` reads through `flutter-version-file` (its README requires an exact version). The Dockerfile `ARG` stays the second copy. A mismatch fails `pub get` inside the Docker build, so it can't drift silently.
- **CI uses one named step per check** (pub get → format → analyze → test → build web), so a failure names its step (Stage 0 acceptance: "fails at the format step"). The Docker `test` service runs the same five commands in one `sh -c`. `shortcut:` the command list lives in two places. Extract a shared script if they ever drift.
- **Actions pinned by major tag** (`actions/checkout@v7`, `subosito/flutter-action@v2`), not by commit SHA. There's no Dependabot in v1, so nothing would ever bump a SHA pin. The workflow token gets `permissions: contents: read`.
- **The lockfile is enforced everywhere:** CI, the Docker `test` command, and both `pub get` lines in the Dockerfile.
- **Docker bind-mount isolation.** `dev` and `test` mount the repo at `/app`. Anonymous volumes over `/app/.dart_tool` and `/app/build` keep the container (which runs as root, with `/opt/flutter` and `/root/.pub-cache` paths) from overwriting the host's `package_config.json` or leaving root-owned files behind.
- **Branch:** `ci/stage-0-baseline` off `dev`. Stage 0 has no module id, and `ci:` is its commit type.
- **Stage version:** `version: 0.0.0+1` and tag `v0.0.0`, following the spec's `0.<stage>.0` scheme. The build number stays `1` because nothing has been released yet.
- **Skipped on purpose:** matrix builds, an Android APK in CI (built at release time from the tag), run-cancelling `concurrency`, caching beyond `cache: true`, actionlint. These are not in the spec.

## Task list

One slice, one squash commit. Details are in [todo.md](todo.md).

### Phase 1: Baseline (Claude, uncommitted for review)
- [x] Task 1: Pin Flutter, enforce the lockfile, set the stage version
- [x] Task 2: CI workflow, job `flutter`
- [x] Task 3: Docker `test` service = CI checks, with the bind-mount fix
- [x] Task 4: `REVIEW.md`: slice summary, commit message, PR bodies, tag commands, branch-protection steps

### Checkpoint A: Local gate (before handing over)
- [x] The host gate passes: pub get (enforced) → format → analyze → test → build web
- [x] `docker compose run --rm test` passes, and afterwards the host still works with no root-owned files
- [x] Negative checks: a mis-formatted file fails at the format step (host + Docker); a changed pin fails `pub get`
- [ ] The user reviews and commits

### Phase 2: GitHub (the user, with commands from REVIEW.md)
- [ ] Task 5: Push the branch, open a PR → `dev`, CI is green
- [ ] Task 6: A throwaway PR with a mis-formatted file goes red at the format step and is closed unmerged
- [ ] Task 7: Branch protection on `main` and `dev` (require a PR, require the `flutter` check, block force-push and deletion), then squash-merge
- [ ] Task 8: Merge `dev` → `main` with a merge commit, then tag `v0.0.0`

### Checkpoint B: Stage 0 done
- [ ] All four Stage 0 acceptance boxes in SPEC.md are ticked (Claude ticks them once the user confirms Phase 2)

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| A Docker run overwrites the host's `.dart_tool/package_config.json` with container paths or leaves root-owned files | Med: the host IDE/tests break until `pub get` or `sudo rm` | Anonymous volumes (Task 3). The check is that `find . -user root` is empty and host `flutter test` works right after a Docker run |
| Branch protection also blocks the user's own direct pushes to `dev`/`main` | Med: changes the workflow | That's the intent. The "Do not allow bypassing" setting decides whether admins can override. Set it consciously |
| The `flutter` check isn't selectable in protection settings until it has run once | Low | Order the steps: open the PR first (CI runs), then add protection |
| `dart format .` later flags generated files (`firebase_options.dart`, l10n) | Low: Stage 1 | Format them once after generating. Revisit in `app-foundation` |
| A web release build on every PR slows CI | Low | `cache: true`. Accept a few minutes per run |

## Open questions

All resolved 2026-11-12 (plan approved as proposed):
1. Stage 0 is released as `0.0.0+1`, tag `v0.0.0`.
2. The plan is committed with the slice. The user moved it to `.claude/tasks/`.
3. The pending 3-line `.claude/REVIEW.md` edit was superseded by the Task 4 overwrite.
