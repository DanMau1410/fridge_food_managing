# Module Spec: `identity`

> Depends on: `app-foundation` · Used by: `households` and every household-scoped module · Delivery: Stage 2
> Status: approved · open questions answered 2026-11-19

## Objective

Let each person have their own account (email/password or Google) and a unique username, which is how friends find and invite them.

## Scope

**In**
- `lib/config/dependencies.dart` (moved here from `app-foundation`): the `MultiProvider` that registers this module's repositories and view models. Later modules extend it.
- Sign up and sign in with email + password. The minimum password length is Firebase's default, **6 characters**. The app checks it at sign-up, so the message is localized and shows before any call.
- Sign in with Google: popup on web, `signInWithProvider` on Android.
- Password reset email.
- Sign out.
- **Auth gate** in front of the shell:
  - signed out → Sign-in screen
  - signed in, no username → Choose-username screen
  - otherwise → `households` gate
- **Username claim**: one per account, permanent in v1.
  - The input is trimmed, then lowercased. It must match `^[a-z0-9_]{3,20}$`.
  - Claimed in one transaction: create `usernames/{username}` = `{uid}` and set `users/{uid}` = `{username, displayName}`.
- **Display name**: the friendly name shown next to `@username`.
  - It comes from Google or from an optional field at sign-up, and it's prefilled and editable on Choose-username.
  - It's trimmed. Empty becomes the username. It's 1–30 characters, any characters (accents, emoji, inner spaces), and not unique.
  - The user can change it any time from the Account screen.
- **Account screen** section:
  - shows username, display name (with an edit action) and email
  - a Sign out button. Sign out first pops back to the first route, so no screen stays above Sign-in, then signs out.
  - The offline cache isn't wiped yet: see [KI-3](SPEC.md#ki-3-the-offline-cache-survives-sign-out).

**Out:** changing a username, deleting an account, email verification enforcement, other providers (Apple, phone).

## Data owned

| Path | Fields | Notes |
|---|---|---|
| `users/{uid}` | `username`, `displayName`, `householdId?` | `householdId` is written by `households` |
| `usernames/{username}` | `uid` | Doc id = lowercased username; this is the uniqueness lock |

**Classification** (see [dev_rules.md §9](../dev_rules.md#personal-data))

| Data | Class | Stored in | Purpose | Deleted by |
|---|---|---|---|---|
| email | personal | Firebase Auth only, never Firestore | sign-in, password reset | deleting the Auth user |
| username | personal (public handle) | `usernames/{username}`, `users/{uid}.username` | finding and inviting people | deleting both docs; `users/{uid}` names the `usernames` doc |
| display name | personal | `users/{uid}.displayName` | showing members to each other | deleting `users/{uid}` |
| uid | pseudonymous id | doc ids, `usernames/{u}.uid` | linking the docs | with the docs above |

Nothing else is collected: no Google photo, no phone number. Deleting an account is out of v1, but everything above is reachable from the uid, so a later delete flow can remove all of it.

**Rules**
- `usernames/{u}`:
  - `get`: any signed-in user (needed for invites). `list` is denied.
  - `create`:
    - `u` matches `^[a-z0-9_]{3,20}$`
    - the data is exactly `{uid}`, with `uid == request.auth.uid`
    - `getAfter(users/{auth.uid}).username == u`: the profile written in the same transaction names this username. Usernames never change on update, so this also limits each account to one name.
  - `update` and `delete`: denied.
- `users/{uid}`:
  - `get`: any signed-in user (shows member names). `list` is denied.
  - `create`:
    - only the owner (`uid == request.auth.uid`)
    - exactly `username` and `displayName`
    - `username` matches the regex
    - `displayName` is valid: a string of 1–30 characters, not just spaces
    - `getAfter(usernames/{username}).uid == uid`
  - `update`:
    - only the owner
    - only `displayName` changes (`diff().affectedKeys().hasOnly(['displayName'])`), and it stays valid. So `username` is immutable
    - `householdId` changes are added by `households` rules.
  - `delete`: denied.

## Interface exposed to other modules

```dart
class AuthRepository {
  Stream<AppUser?> watchAuthUser();               // uid, email, displayName from Firebase Auth
  Future<void> signUpWithEmail(String email, String password, {String? displayName});
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class UserRepository {
  Stream<UserProfile?> watchProfile(String uid);  // null until a username is claimed
  Future<UserProfile?> getProfile(String uid);
  Future<String?> uidForUsername(String username);
  Future<void> claimUsername(String uid, String username, String displayName); // throws UsernameTaken
  Future<void> updateDisplayName(String uid, String displayName);
}
```

The gate exposes the current `UserProfile` via `provider`. Downstream modules read `uid`, `username`, `displayName` and `householdId` from it.

## Acceptance criteria

1. **AC-ID-1**: Signing up with a new email and a ≥ 6-char password lands on Choose-username.
2. **AC-ID-2**: Signing in with a wrong password, an unknown email or a malformed email shows a localized error and stays on Sign-in. No crash, no raw Firebase error codes.
3. **AC-ID-3**: "Continue with Google" signs in on web (popup) and on Android. A first-time Google user lands on Choose-username with the display name prefilled.
4. **AC-ID-4**: Claiming `Dan_M` stores `dan_m`: `usernames/dan_m.uid` equals the caller's uid and `users/{uid}.username == "dan_m"`.
5. **AC-ID-5**: A second account claiming `dan_m` (any casing) gets "Username already taken". No document is created or changed for it.
6. **AC-ID-6**: `ab`, a 21-character name, `dan m` and `dan-m` are rejected with a validation message before any network call.
7. **AC-ID-7**: Signing out returns to Sign-in. Signing back in skips Choose-username and goes straight to the household gate.
8. **AC-ID-8**: "Forgot password" sends a reset email (in the emulator, the reset link appears in the Auth emulator log) and shows a confirmation, without revealing whether the email exists.
9. **AC-ID-9**: Rules (emulator):
   - user A cannot write `users/B` or change B's display name
   - A cannot create `usernames/x` with `uid: B`
   - A cannot overwrite or delete an existing `usernames/x`
   - A cannot claim a second username
   - neither doc can be created without the other
   - A cannot change their `username` after it's set, or add fields
   - a display name that's empty or over 30 characters is denied
   - a signed-in user cannot `list` `users` or `usernames`
   - an unauthenticated user cannot `get` either
10. **AC-ID-10**: All identity screens render in EN and ES.
11. **AC-ID-11**: On the Account screen, a user changes their display name:
    - `"  Ana María "` is stored as `Ana María`
    - an empty name stores the username
    - 31 characters shows a validation message, and nothing is written
    - only `displayName` changes

## Tests

- `test/domain/username_test.dart`: the regex table for AC-ID-6, plus the display-name rule.
- `test/data/user_repository_test.dart` (`fake_cloud_firestore`): AC-ID-4, AC-ID-5, AC-ID-11.
- `test/ui/auth/view_models/*_test.dart` (`firebase_auth_mocks`): AC-ID-1, AC-ID-2, AC-ID-7.
- `test/ui/auth/*_screen_test.dart`: validation messages and EN/ES (AC-ID-10, AC-ID-11).
- `firebase/test/identity.test.js`: AC-ID-9.
- Manual: Google on web and on Android (AC-ID-3); password reset via the emulator log (AC-ID-8).

## Open questions

None. Answered 2026-11-19:
- Minimum password length: Firebase's default, 6.
- Display name: 1–30 characters, editable from the Account screen.
- Wiping the offline cache on sign-out: deferred to `households` as KI-3.
