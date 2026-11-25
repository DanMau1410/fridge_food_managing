# firebase/

Firestore rules, indexes and the local emulators (project `demo-fridge`; `--project prod` is the real one). Needs Node (`.nvmrc`) and Java 21+.

- `npm test`: rules tests against the Firestore emulator.
- `npm run emulators`: Auth + Firestore emulators with `seed/` loaded; UI at http://localhost:4000.

## Seed accounts (emulator only)

`ana@fridge.test` (username `ana`, Ana) and `bea@fridge.test` (username `bea`, Bea), password `fridge-test-123` for both. Both have a profile, so they sign in straight to the shell. Never reuse them on the real project.

To change the seed, run `npx firebase emulators:start --only auth,firestore --import=seed --export-on-exit=seed`, edit in the UI, and stop with Ctrl+C. The export replaces everything in `seed/`, so keep notes here, not there.
