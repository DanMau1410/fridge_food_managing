# Review: Stage 1 · Slice 2, emulators and rules harness

## 1. What & why

This delivers Slice 2 of the [Stage 1 plan](../tasks/plan.md) (Tasks 3–5):
- A `firebase/` project for rules, indexes and the local emulators, defaulting to the safe `demo-fridge` project.
- Default-deny Firestore rules, with the AC-AF-8 test proving every read and write is refused.
- A second CI job, `rules`, that runs those tests on every PR and push.
- A seed of two Auth test users, which `npm run emulators` loads.

Nothing in the app changes. Later modules add their rules and tests here.

## 2. Files changed

**Firebase project** (all new, in `firebase/`)
- [firebase.json](../../firebase/firebase.json): emulator ports (Auth 9099, Firestore 8085, UI 4000), matching `lib/main.dart`
- [.firebaserc](../../firebase/.firebaserc): `default` = `demo-fridge`, `prod` = `fridge-food-managing`
- [firestore.rules](../../firebase/firestore.rules), [firestore.indexes.json](../../firebase/firestore.indexes.json)
- [package.json](../../firebase/package.json), [package-lock.json](../../firebase/package-lock.json), [.nvmrc](../../firebase/.nvmrc) (Node 26): `firebase-tools`, `@firebase/rules-unit-testing`, `firebase`, all dev-only
- [test/foundation.test.js](../../firebase/test/foundation.test.js): AC-AF-8, four denied cases
- [seed/](../../firebase/seed/): the emulator export (two users, empty Firestore)
- [README.md](../../firebase/README.md): commands, the seed accounts, how to regenerate the seed

**CI and tooling**
- [.github/workflows/ci.yml](../../.github/workflows/ci.yml): the new `rules` job
- [analysis_options.yaml](../../analysis_options.yaml): excludes `firebase/node_modules/**`
- [.gitignore](../../.gitignore), [.dockerignore](../../.dockerignore): `firebase/node_modules`

**Specs and plan**
- [SPEC.md](SPEC.md): the emulator command is `npm run emulators`, the deploy command needs `--project prod`, and the CI note's `.nvmrc` path is `firebase/.nvmrc`.
- [tasks/plan.md](../tasks/plan.md), [tasks/todo.md](../tasks/todo.md): Slice 1's checkpoint and Tasks 3–5 ticked. Task 5's README moved (see 3.4).

## 3. What to look for

1. **The rules**, [firestore.rules:9-14](../../firebase/firestore.rules:9). Nothing grants access. `signedIn()` and the `isMember()` stub (always `false`) are there for `households` to fill in.
2. **The safe default**, [.firebaserc:3](../../firebase/.firebaserc:3). A bare `firebase` command targets `demo-fridge`, which the emulators treat as offline-only. Reaching the real project takes `--project prod`, which is spelled out in SPEC.md's deploy command.
3. **Java 21 in CI**, [ci.yml:44-48](../../.github/workflows/ci.yml:44). firebase-tools 15 refuses to start the emulators on Java < 21. That's the only pinned version; Node comes from `firebase/.nvmrc`.
4. **The seed README moved to `firebase/README.md`.** The plan put it in `seed/README.md`, but I proved that every `--export-on-exit=seed` replaces the whole folder and would delete it.
5. **The analyzer exclude**, [analysis_options.yaml:21](../../analysis_options.yaml:21). firebase-tools ships a Dart Functions template in `node_modules`, which gave 6 analyzer errors locally after `npm ci`. CI's `flutter` job never installs it, so only local runs were affected.
6. **Test password in plain text** in `firebase/README.md` and `seed/auth_export/accounts.json`. These accounts exist only in the emulator, and the export stores the password readably by design.
7. **npm 12 skips install scripts** for `protobufjs` and `re2` (its new default). The tests pass both after `npm install` and after a clean `npm ci`.

## 4. How to verify

**First, fix Java in fish.** `archlinux-java` changed the system default, but your fish still points at JDK 17, in two universal variables. Flutter's Android builds aren't affected, because `flutter config` pins its own `jdk-dir`.
```bash
set -Ux JAVA_HOME /usr/lib/jvm/java-21-openjdk
```
```bash
set -U fish_user_paths (string match -v /home/danmau/development/jdk/bin $fish_user_paths)
```
Open a new terminal, and then `java -version` should say 21.

What I ran (all as expected):

```bash
cd firebase && npm ci && npm test
```
Expected: `ℹ pass 4`, `ℹ fail 0`, "Script exited successfully (code 0)". With a temporary `match /{document=**} { allow read: if true; }`, both read tests fail with exit code 1 (I reverted it).

```bash
cd firebase && npx firebase use
```
Expected: `demo-fridge`.

```bash
cd firebase && npm run emulators
```
Open http://localhost:4000/auth. Expected: Ana and Bea are listed. Stop with Ctrl+C. The seed files stay unchanged, because this command only imports.

```bash
dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test
```
Expected: "No issues found!" and "All tests passed!", even with `firebase/node_modules` installed.

```bash
git status --short
```
Expected:
- `M`: `.claude/specs/SPEC.md`, `.claude/specs/REVIEW.md`, `.claude/tasks/plan.md`, `.claude/tasks/todo.md`, `.dockerignore`, `.github/workflows/ci.yml`, `.gitignore`, `analysis_options.yaml`
- `??`: `firebase/`, 13 files (no `node_modules`, no logs)

**Not verified:** the `rules` job on GitHub. It runs for the first time on this PR.

## 5. Proposed commit message

```
feat(app-foundation): add emulator and rules test harness

Add firebase/ with firestore.rules (default deny, plus signedIn() and
an isMember() stub for households), indexes, and emulator config
(Auth 9099, Firestore 8085, UI 4000). .firebaserc defaults to the
offline demo-fridge project; the real one needs --project prod.

Test the rules with @firebase/rules-unit-testing under node --test:
AC-AF-8 checks that signed-in and anonymous reads and writes are all
denied. A new CI job, rules, runs them on Node from firebase/.nvmrc
and Java 21, which firebase-tools 15 requires.

Seed the Auth emulator with two test users (ana@fridge.test,
bea@fridge.test), loaded by npm run emulators and documented in
firebase/README.md. Keep firebase-tools' bundled Dart template out
of flutter analyze.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

## Landing it

```bash
git switch -c feat/app-foundation-emulator dev
```
```bash
git add .claude/specs .claude/tasks .dockerignore .gitignore .github/workflows/ci.yml analysis_options.yaml firebase && git commit
```
```bash
git push -u origin feat/app-foundation-emulator
```
```bash
gh pr create --base dev --head feat/app-foundation-emulator --title "feat(app-foundation): add emulator and rules test harness" --web
```

Once `flutter` and `rules` are both green, squash-merge. Then:

```bash
git switch dev && git pull --ff-only && git branch -D feat/app-foundation-emulator
```

**Then make `rules` required.** GitHub only offers checks that have already run. Go to Settings → Rules → Rulesets, open `Dev PR`, find "Require status checks to pass", and add `rules` next to `flutter`. Do the same for `Main PR`. When you tell me it's done, I'll confirm it with a read-only `gh api` call.

**Next:** Slice 3 (`itemKey`, date keys, and the category, location and unit enums), pure Dart, once you've reviewed and merged this.
