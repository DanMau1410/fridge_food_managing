# Implementation Plan: Stage 1, `app-foundation`

> Source: [SPEC-app-foundation.md](../specs/SPEC-app-foundation.md), [SPEC.md › Stage 1](../specs/SPEC.md#stage-1-environments) · Status: **approved 2026-11-14**
> Tasks: [todo.md](todo.md) · Stage 0's plan is in git history (tag `v0.0.0`)

## Overview

This replaces the template with the shell every module plugs into:
- Firebase on Android and web, with an emulator switch
- the security-rules test harness, plus its CI job
- the shared food vocabulary (categories, locations, units, item keys)
- English/Spanish navigation between Food, Groceries and Recipes

The work is four slices. Each slice gets its own `feat/app-foundation-*` branch and is squash-merged into `dev`. The stage ends with a merge of `dev` → `main` and the tag `v0.1.0`.

## Starting point (verified 2026-11-14)

- **Uncommitted on `dev`:**
  - `flutterfire configure` output: `lib/firebase_options.dart`, `android/app/google-services.json`, a top-level `firebase.json`, and the Google Services Gradle plugin pinned at **4.3.15** (the latest is 4.6.0), next to Android build tooling (AGP) 9.1
  - `firebase_core` 5.1.0 and `flutter_web_plugins` (sdk)
  - the spec edits with your answers folded in
- **Quality gate:** green with all of the above (format, analyze, test, web build). **The Android build hasn't been tried.**
- **Flutter tooling:**
  - Flutter 3.47.6. Its default Android minSdk is 24, which matches `firebase_core` 5's minimum.
  - gen-l10n writes its output into `lib/l10n/` (the synthetic package was removed), and `flutter pub get` regenerates it.
- **Firebase and Node:** Node 26.13, firebase-tools 15.36 (installed globally), `@firebase/rules-unit-testing` 6.0.0 (needs `firebase` ^13).
- **Java 17 — but firebase-tools 15 refuses Java below 21 for the emulators** (`MIN_SUPPORTED_JAVA_MAJOR_VERSION = 21`).
- **Devices:**
  - Android SDK 36, but no emulator image (AVD) and no phone connected
  - no Chrome, so web runs use `-d web-server` and any browser

## Architecture decisions

- **Slices run in risk order.**
  1. Firebase in the app: this lands the pending FlutterFire files and proves the Android build.
  2. The emulator and rules harness.
  3. The pure domain code.
  4. Localization and the shell.
- **Gradle plugin:** build a debug APK with FlutterFire's 4.3.15 first, and bump to 4.6.0 only if that fails.
- **The emulator switch lives in `main.dart`.** One `const bool.fromEnvironment('USE_EMULATOR')`, with host `localhost` on web and `10.0.2.2` on Android. Firestore settings (web persistence) are set before connecting to the emulator. A `debugPrint` names the emulator host.
- **AC-AF-3 can't be fully checked in Stage 1.** Its "visible in the Emulator UI" part needs a Firestore or Auth call, and Stage 1 makes none. So:
  - Stage 1 checks that startup is clean with and without the flag.
  - The end-to-end check happens at Stage 2's first sign-up (AC-ID-1).
- **`.firebaserc` defaults to `demo-fridge`, with the alias `prod` → `fridge-food-managing`.**
  - A bare `firebase` command in `firebase/` can only reach the emulator project.
  - Deploys must name the project (`--project prod`), so the spec's deploy command gets updated.
- **Two `firebase.json` files:**
  - FlutterFire's, at the top level, used only by `flutterfire configure`.
  - The emulator and rules config, in `firebase/firebase.json` as the spec says. npm scripts always run from inside `firebase/`.
- **The seed (`firebase/seed/`) is two Auth test users, emulator only.** `identity`, `households` and `inventory` each add their own documents once those data shapes exist, rather than guessing them now.
- **Enum labels go in `lib/ui/core/labels.dart`, not `lib/domain/`.** They need `AppLocalizations`, which is Flutter code, and the spec keeps `domain/` free of Flutter imports.
- **`lib/config/dependencies.dart` and `provider` move to Stage 2 (`identity`)**, where the first repository gets registered. In Stage 1, the `MultiProvider` would have nothing to provide. The spec scope gets updated in Slice 1.
- **Generated localization files are committed**, with `format: true` in `l10n.yaml` so the CI format check passes.
- **`Quantity`:**
  - The amount is a `double`, and each `Unit` has a dimension (count, mass or volume) and a factor to its base unit.
  - Comparing two quantities returns `int?`, where `null` means "not comparable".
  - Tests use `closeTo` to allow for floating-point rounding.
- **`itemKey` strips accents** with a small built-in map of Latin accented letters; no new package. A `// shortcut:` comment marks that limit.
- **Version:** `0.1.0+2` at the end of the stage, tagged `v0.1.0`.

## Task list

The details are in [todo.md](todo.md).

### Slice 1: `feat/app-foundation-firebase`, Firebase in the app
- [x] Task 1: Android debug build with FlutterFire's Gradle setup
- [x] Task 2: Initialize Firebase, emulator switch, web persistence

**Checkpoint 1:**
- [x] The gate is green and a debug APK builds
- [x] A `web-server` run is clean with and without `USE_EMULATOR`
- [x] REVIEW written → you commit, open a PR, squash-merge

### Slice 2: `feat/app-foundation-emulator`, rules harness (needs JDK 21)
- [x] Task 3: `firebase/` project with default-deny rules and the AC-AF-8 test
- [x] Task 4: CI job `rules`
- [x] Task 5: Seed two Auth users, plus `npm run emulators`

**Checkpoint 2:**
- [x] `cd firebase && npm test` is green locally and in CI
- [x] The Emulator UI shows the seed users
- [x] You add `rules` as a required check in both rulesets

### Slice 3: `feat/app-foundation-domain`, shared vocabulary
- [ ] Task 6: `itemKey` and date keys
- [ ] Task 7: `FoodCategory`, `StorageLocation`, `Unit`, `Quantity`

**Checkpoint 3:**
- [ ] AC-AF-4, 5, 6 (values) and 7 pass as table tests
- [ ] The gate is green

### Slice 4: `feat/app-foundation-shell`, English/Spanish shell and stage close
- [ ] Task 8: Localization setup and enum labels
- [ ] Task 9: App shell and theme, replacing the template
- [ ] Task 10: Stage close: version `0.1.0+2`, spec ticks, stage PR and tag commands

**Checkpoint 4: Stage 1 done:**
- [ ] The gate is green, `docker compose run --rm test` is green, and both CI jobs are green (AC-AF-9)
- [ ] Manual checks: web in English, Spanish and a fallback language; the Android emulator (needs an AVD); a narrow and a wide window
- [ ] You merge `dev` → `main` and tag `v0.1.0`

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Java 17 locally, but the emulators need 21 | High: Slice 2 can't run locally | You install JDK 21 before Slice 2 (see Prerequisites). CI already uses 21 |
| Google Services plugin 4.3.15 with AGP 9.1 | Med: the Android build may fail | Task 1 builds first, then bumps to 4.6.0 if needed |
| No Android emulator image or phone | Med: the Android half of AC-AF-1 can't be checked | You create an AVD before Checkpoint 4. `10.0.2.2` only works from the emulator; a physical phone would need the PC's LAN IP (out of scope for v1) |
| `firebase` run from the repo root picks FlutterFire's `firebase.json` | Low | Always use the npm scripts in `firebase/` (the spec's commands already `cd firebase`) |
| Generated code fails the format check | Low | `format: true` for gen-l10n. `firebase_options.dart` is already formatted |
| A dev run without the flag talks to production | Low: production Firestore currently denies everything | Always pass the flag in development. Tests never point at production (spec) |

## Prerequisites (you)

1. **Before Slice 2:** install JDK 21 and make it the default. On CachyOS: `sudo pacman -S jdk21-openjdk`, then `sudo archlinux-java set java-21-openjdk`. Android builds work on 21 too.
2. **Before Checkpoint 4:** an Android emulator image (Android Studio → Device Manager → Create device), or a phone with USB debugging for the non-emulator checks.

## Open questions

All resolved 2026-11-14 (plan approved as proposed):
1. Fruit defaults to the cabinet. Confirmed.
2. The seed is two Auth users in Stage 1, and later modules add their own data.
3. `dependencies.dart` and `provider` move to Stage 2.
