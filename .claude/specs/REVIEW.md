# Review: Known issues and phone dev setup (docs only)

## 1. What & why

The first Android run on a real phone (2026-11-17) worked, but the build printed a Kotlin Gradle Plugin (KGP) warning. This records the warning and one more deferred phone issue in the spec, so they get fixed on schedule instead of being forgotten. It also updates the Stage 1 plan for using a phone instead of an AVD. No code changes.

## 2. Files changed

**Spec**
- [SPEC.md](SPEC.md#known-issues): a new **Known Issues** section, placed before Open Questions:
  - **KI-1:** the FlutterFire KGP warning. Its cause, its risk, the available fix (firebase_core 5.2.0, firebase_auth 7.1.0), the steps to apply it, and when to do it.
  - **KI-2:** `10.0.2.2` host mapping on a physical phone. The fix (`adb reverse` plus `automaticHostMapping: false`) is due in Stage 2.

**Plan**
- [tasks/plan.md](../tasks/plan.md): the device note, Checkpoint 4's manual check and the risk row now describe the phone.
- [tasks/todo.md](../tasks/todo.md): Checkpoint 3 ticked (#8 squash-merged), and Task 10's Android check now reads "phone over USB, or an AVD".

## 3. What to look for

1. **The cause in KI-1**, [SPEC.md "KI-1"](SPEC.md#ki-1-flutterfire-plugins-apply-the-kotlin-gradle-plugin). The plugins only apply KGP while built-in Kotlin is off, but Flutter's check reads the build script's text, so a flag alone can't silence it.
   - I confirmed this by building a debug APK with `android.builtInKotlin=true`. The build passed and the warning still printed.
   - "The upgrade removes the warning" is inferred from the new plugin source, not tested. Step 2 of the fix is that test.
2. **When the fix lands:** at the next stage-end dependency check (Stage 1's close), and always before a Flutter bump. Say if you'd rather do it now as its own PR.
3. **Security:** no security-relevant change. It's docs only. Both secret scans print nothing. KI-2 records why the LAN-IP option was rejected: the emulators would be exposed to the network.

## 4. How to verify

```bash
git diff --stat
```
Expected: `.claude/specs/SPEC.md`, `.claude/specs/REVIEW.md`, `.claude/tasks/plan.md`, `.claude/tasks/todo.md`. Nothing else.

What I ran:
- `flutter build apk --debug --android-project-arg=android.builtInKotlin=true`: built, and the KGP warning still printed.
- `flutter pub outdated`: firebase_core 5.2.0, firebase_auth 7.1.0 and cloud_firestore 7.2.0 are available.
- Their `android/build.gradle` at the release tags no longer contains `apply plugin: 'kotlin-android'`.

The quality gate isn't needed, since no Dart, rules or config changed.

## 5. Proposed commit message

```
docs(spec): track Built-in Kotlin migration and phone dev setup

Add a Known Issues section to SPEC.md:

- KI-1: firebase_core 5.1.0 and firebase_auth 7.0.1 trigger Flutter's
  KGP warning on Android builds. Fix: upgrade to 5.2.0 / 7.1.0 at the
  next stage-end dependency check, and before any Flutter bump.
- KI-2: FlutterFire maps localhost to 10.0.2.2 on every Android
  device, so emulator runs from a phone need adb reverse and
  automaticHostMapping: false (Stage 2).

The Stage 1 plan now uses a USB-debugging phone instead of an AVD
for the Android check, and Checkpoint 3 is ticked (#8).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

## 6. PR handoff

**What was done**
- Recorded the KGP warning (KI-1) and the phone emulator-host issue (KI-2) in SPEC.md, each with a cause, a fix and a trigger
- Switched the Stage 1 plan's Android check from an AVD to the phone
- Ticked Checkpoint 3

**Branch (`--head`):** `docs/spec-known-issues`

**PR title:** `docs(spec): track Built-in Kotlin migration and phone dev setup`

**PR description:**
```markdown
Docs only. The first Android run on a phone worked, and these are the two deferred issues it surfaced.

## What's in it
- **SPEC.md → Known Issues**
  - **KI-1:** firebase_core 5.1.0 and firebase_auth 7.0.1 trigger Flutter's "plugins that apply Kotlin Gradle Plugin" warning. The APK builds fine today, but a future Flutter release will fail.
    - Fix: firebase_core 5.2.0 / firebase_auth 7.1.0, which have migrated.
    - Scheduled for the next stage-end dependency check, and before any Flutter bump.
  - **KI-2:** FlutterFire maps `localhost` to `10.0.2.2` on every Android device, so emulator-backed runs from a phone need `adb reverse` and `automaticHostMapping: false`. Due in Stage 2.
- **Stage 1 plan:** the Android check uses a USB-debugging phone instead of an AVD, and Checkpoint 3 is ticked (#8).

## Security
No security-relevant change. KI-2 records that exposing the emulators on the LAN was rejected.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Commands**

```bash
git switch -c docs/spec-known-issues dev
```
```bash
git add .claude/specs .claude/tasks && git commit
```
```bash
git push -u origin docs/spec-known-issues
```
```bash
gh pr create --base dev --head docs/spec-known-issues --title "docs(spec): track Built-in Kotlin migration and phone dev setup" --web
```
Paste the description above into the browser form. Once `flutter` and `rules` are green, squash-merge. Then:

```bash
git switch dev && git pull --ff-only && git branch -D docs/spec-known-issues
```
```bash
git push origin --delete docs/spec-known-issues
```

**Next:** Slice 4, the English/Spanish shell and the Stage 1 close. Its close runs `flutter pub outdated`, which picks up KI-1.
