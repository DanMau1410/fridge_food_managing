# Dev rules: how the developer and Claude work together

"The developer" is the human who owns this repo. "Claude" means Claude or any other AI assistant working on it.
Sections 7 and 8 mirror the Boundaries in [SPEC.md](specs/SPEC.md#boundaries); change both together.

## 1. Git and GitHub belong to the developer

Only the developer:
- stages changes (`git add`)
- makes commits
- creates, renames and deletes branches, locally and on GitHub
- pushes
- opens PRs
- approves, requests changes on, or closes PRs
- merges PRs
- creates tags and GitHub Releases
- changes rulesets, branch protection and repo settings

Claude (or any other AI):
- only reads git and GitHub state: `git status`, `diff`, `log`, `show`, `fetch`, and read-only `gh api` / `gh pr list` / `gh pr view` calls
- never runs `git add`, `commit`, `push`, `merge`, `tag`, `switch -c`, `branch -d`, or `gh pr create`, `merge`, `review` or `comment`
- leaves every change uncommitted in the working tree
- writes the git and GitHub commands for the developer to run
- checks a GitHub step the developer reports as done with a read-only call before ticking its box, and says so if the result doesn't match

## 2. Branches and PRs

- Feature work goes on a branch off `dev`, then through a PR that is **squash-merged into `dev`**.
- At the end of a stage, a PR from `dev` to `main` is **merged with a merge commit**, and the developer tags it `v0.<stage>.0`.
- The rulesets `Dev PR` and `Main PR` require the `flutter` and `rules` checks. Nothing merges while a check is red.
- Suggested branch names: `feat/<module-id>-<slice>` (e.g. `feat/app-foundation-domain`), `fix/…`, `docs/…`. The developer may choose another name; Claude reads the real one from git before writing cleanup commands.
- **When work is ready for a PR** (squash into `dev` or merge into `main`), Claude suggests:
  - a quick breakdown of what was done
  - a PR title
  - a PR description, ending with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`
  - a name for the `--head` branch
  - the commands to create the branch, commit, push, open the PR, and clean up after the merge
- Claude reviews a PR and reports the findings in chat. It doesn't approve or comment on GitHub.

## 3. How work moves

- Spec → plan → tasks → code. Specs live in `.claude/specs/`, the plan in `.claude/tasks/plan.md`, the task list in `.claude/tasks/todo.md`.
- Claude plans a stage only when the developer asks, and implements nothing until the developer approves the plan.
- Claude never overwrites a plan that still has unfinished tasks without asking.
- When a decision recorded in a spec changes, the spec is updated first.
- One slice at a time. The next slice starts only after the developer has reviewed and merged the current one.
- Claude ticks a box only after checking it, and lists anything it could not verify.

## 4. The handoff at the end of every slice

In chat **and** in `.claude/specs/REVIEW.md` (overwritten each slice):
1. **What & why**: the slice, tied to its spec section and acceptance criteria.
2. **Files changed**: clickable paths grouped by layer, one line each.
3. **What to look for**: the few places that need human eyes, as `file:line`, plus anything uncertain.
4. **How to verify**: exact commands with expected results, manual steps, and what wasn't verified.
5. **Proposed commit message**: Conventional Commits with the module id as scope, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
6. **PR handoff**: everything listed in section 2.

At the end of a stage, the handoff also gives the version bump in `pubspec.yaml`, the tag commands and a rollback note.

## 5. Quality bar

- Before handing over a slice, Claude runs the quality gate: `dart format`, `flutter analyze`, `flutter test`, `flutter build web`. When the rules change, it also runs `cd firebase && npm test`.
- Every UI string goes in both `app_en.arb` and `app_es.arb`.
- Schema changes are additive only (new optional fields, and readers default the missing ones).

## 6. Commands Claude gives the developer

- The developer's shell is **fish**. Commands never contain `<angle-bracket>` placeholders. They use real values or UPPER_CASE names like `PROJECT_ID`.
- Each command goes in its own code block, so it can be copied and run alone.
- Claude doesn't change the developer's machine (environment variables, `PATH`, system packages, anything that needs `sudo`). It gives the commands to run.

## 7. Ask first

- Adding a dependency that isn't in SPEC.md's Tech Stack
- Data-model or rules changes beyond the specs
- Any deploy to the real Firebase project (`fridge-food-managing`)
- The Blaze plan or Cloud Functions
- New target platforms
- `go_router`
- Destructive data migrations, which also need a backup first

## 8. Never

- Commit service-account or admin keys, or tokens. (`firebase_options.dart` and `google-services.json` are public config and fine to commit.)
- Loosen the rules to `allow read, write: if true`.
- Delete or skip failing tests.
- Force-push `main`.
- Point tests at the production Firebase project. Test accounts exist only in the emulator (`demo-fridge`).

## 9. Security

Security is part of every slice from the spec onward, not a pass at the end. This section adds to sections 7 and 8. SPEC.md's Boundaries point here instead of repeating it. For deeper patterns, Claude loads the `security-and-hardening` skill (or equivalent).

**The fact everything else follows from:** the app is a client talking straight to Firebase. Anyone can take the public config and call Firestore and Auth without our app. **Security rules are the only server-side boundary.** Everything in the app (Dart validation, hidden buttons, constants, assets, `--dart-define` values) can be read and bypassed by the user.

### In the workflow

- **Spec**: every new field is classified as non-personal, personal (email, name, household members) or sensitive (health or diet, location, photos), with its purpose and how it gets deleted with the account. A field with no purpose isn't collected.
- **Plan**: every slice in `plan.md` has a **Security** line: the trust boundaries it crosses (user input, Firestore, another user's data, an external API, a deep link), what's worth attacking, and 2–3 abuse cases ("how would I misuse this?"). "None: UI only" is a valid answer, but it's written down.
- **Build**: abuse cases are the first tests. Rules deny-tests in `firebase/` for data access, unit tests for parsers and validators.
- **Gate**: on top of section 5, Claude runs the secret scan below, and checks the advisories `flutter pub get` prints when `pubspec.yaml` changed.
- **Handoff**: "What to look for" (section 4) has a Security line: rules touched, new inputs, new personal data, new dependencies or permissions, or "no security-relevant change".
- **Findings**: a security problem outside the current slice is reported in chat and in the handoff, not fixed silently. If it exposes one user's data to another, or a secret is in the repo, Claude stops and reports it before anything else.

### Threat model in five minutes (STRIDE, for this app)

| Threat | What it looks like here | Default control |
|---|---|---|
| Spoofing | acting as another user | Firebase Auth; rules use `request.auth.uid`, never a uid the client wrote into a document |
| Tampering | bad shapes, changed owner or `createdAt` | rules check keys, types and sizes; immutable fields stay unchanged on update |
| Repudiation | "I didn't delete that" in shared data | where the spec has shared data, rules force `updatedBy == request.auth.uid` and timestamps to `request.time` |
| Information disclosure | reading someone else's fridge; PII in logs; raw errors | owner or member check on every read; generic errors; no PII in logs |
| Denial of service / cost | huge documents, endless writes, unbounded queries | size caps in rules, `limit()` on queries, budget alerts |
| Elevation of privilege | making yourself a member or admin | role and membership fields change only under rules that check the caller's current role |

### Firestore (and Storage) rules

- Deny by default. No `{document=**}` grants. Split `create`, `update` and `delete` when they need different checks.
- `request.auth != null` alone is never enough for user data. Compare `request.auth.uid` with the path or a stored owner or member field.
- Validate shape on create and update: `keys().hasOnly([...])` plus `hasAll` for required fields, a type check per field, a max length for every string, a max size for every list and map, allowed values for enums.
- Owner, `createdAt` and membership can't change on update (compare `request.resource.data` with `resource.data`). Server times use `request.time`.
- Schema changes are additive (section 5), so a new field updates the `hasOnly` list and its tests in the same slice.
- Every rule change ships with deny-tests for: signed out, another user, an extra field, a wrong type, an oversized string, a changed immutable field. Plus the allowed path.
- Cloud Storage, if ever added: per-user paths, a `request.resource.size` cap and a `contentType` allowlist.

### App code

- Client validation is for UX. Still validate at the edge (trim, length, ranges, dates) and pass typed values inward: the domain layer never sees raw form strings.
- Firestore data is untrusted too, since another client may have written it. Parse defensively, default missing fields, never crash on a bad document.
- User text renders only through Flutter text widgets. Never through `HtmlElementView`, `innerHTML` or a WebView.
- `url_launcher` with a URL from a user or an API: `https` only (plus `mailto` if a feature needs it). Never `javascript:` or `file:`.
- An ID in a deep link or web route never implies access. The rules decide.
- Users see a generic error from the arb files. Raw `FirebaseException` messages and stack traces go to debug logs only.
- No tokens, passwords, emails or whole documents in `print`, `debugPrint` or `log`. Log IDs and error codes.
- `shared_preferences` is plaintext: non-sensitive settings only. Auth tokens stay with the Firebase SDK.
- Sign-out must not leave the previous user's data readable on the device (Firestore offline cache, local storage). The spec says how.
- HTTPS only. No cleartext exceptions (Android `usesCleartextTraffic`, iOS ATS). Never a `badCertificateCallback` that returns `true`.
- Auth is Firebase Auth only: no home-made login, password storage or token handling.

### Secrets

- Public by design: `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist` and the Firebase API keys in them. Rules and API key restrictions protect them, not hiding.
- Anything shipped in the app is public. A key that must stay secret (paid API, LLM, admin) can't live in the app. It needs a server, which means Cloud Functions, which means ask first (section 7).
- Never in the repo: service-account JSON, `firebase login:ci` tokens, the Android upload keystore (`*.jks`, `*.keystore`, `key.properties`), iOS certificates and profiles (`*.p12`, `*.mobileprovision`), `.env` files with real values. Example files hold placeholders only.
- Before every handoff Claude runs both scans. Each must print nothing. They list file names only, so a hit never echoes the secret into chat or logs:

```
git grep --untracked -lIiE 'BEGIN [A-Z ]*PRIVATE KEY|"private_key"|client_secret|refresh_token|sk-[a-z0-9_-]{20,}|gh[pousr]_[a-z0-9]{30,}|github_pat_' -- ':!.claude/dev_rules.md'
```

```
git ls-files --cached --others --exclude-standard | grep -iE '\.(jks|keystore|p12|pem|mobileprovision)$|key\.properties$|service-?account|(^|/)\.env'
```

- A secret that reaches GitHub is compromised. The developer rotates it first, then cleans history. Claude writes the steps.

### Dependencies

- New packages are already ask-first (section 7). When asking, Claude reports the publisher (verified? `dart.dev`, `flutter.dev` and `firebase.google.com` preferred), last release date, pub points, license, what it pulls in, and whether a few lines of our own code would do. Check the exact name on pub.dev or npm: typosquats exist.
- `pubspec.lock` and `firebase/package-lock.json` stay committed. Installs follow them (`npm ci` in `firebase/`).
- At stage end Claude runs `flutter pub outdated` and `cd firebase && npm audit`, then triages by reachability: app runtime dependencies first, `firebase/` is test tooling. Never `npm audit fix --force`. Upgrade one package at a time and rerun the gate. Every deferred finding goes in `todo.md` with a reason and a review date.

### Personal data

- Collect the minimum the spec needs. "Might be useful later" isn't a purpose.
- A user's data stays findable by uid, so deleting the account removes all of it (Firestore, Storage, the Auth user) and export stays possible. Deletion is real deletion, not a flag.
- No PII in analytics, crash reports or logs.
- Tests, fixtures, seed data and screenshots use made-up data only, in the emulator.

### Before a stage merges into `main`

- Claude walks the security review checklist over `git diff main...dev` and reports the findings in the handoff, along with the dependency check above.
- Before the first public release, Claude lists what the developer checks in the consoles: API key restrictions (Android package and SHA-1, iOS bundle id, web referrers), Auth settings (authorized domains, email enumeration protection, password policy), budget alerts, App Check, and Hosting security headers if web is hosted (CSP, HSTS, `X-Content-Type-Options`, `frame-ancestors`).

### Ask first (security)

- Auth changes: new providers, account linking, sign-in, sign-out or account-deletion flows.
- A new category of personal data (photos, location, health or diet, contacts).
- A new external service or SDK that receives user data (analytics, crash reporting, food databases, LLMs).
- New platform permissions (camera, location, notifications, contacts).
- File uploads or Cloud Storage.
- Enabling or enforcing App Check, or changing Hosting headers or CORS.
- Any role, admin flag or cross-user access.

### Never (security)

- Treat client-side checks or hidden UI as access control.
- Loosen a rule, or weaken a deny-test, to make a test pass.
- Put a secret in the app, the repo, a log or a chat message.
- Show raw errors or stack traces to users.
- Disable TLS checks or allow cleartext traffic.
- Run `npm audit fix --force` or blanket-approve install scripts.
- Use real user data in tests, fixtures, seed data or screenshots.
