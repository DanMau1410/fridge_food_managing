# Module Spec: `identity`

> Depends on: `app-foundation` · Used by: `households` and every household-scoped module · Delivery: Stage 2
> Status: draft, awaiting review

## Objective

Let each person have their own account (email/password or Google) and a unique username, which is how friends find and invite them.

## Scope

**In**
- Sign up and sign in with email + password.
- Sign in with Google: popup on web, `signInWithProvider` on Android.
- Password reset email.
- Sign out.
- **Auth gate** in front of the shell:
  - signed out → Sign-in screen
  - signed in, no username → Choose-username screen
  - otherwise → `households` gate
- **Username claim**: one per account, permanent in v1.
  - Input is lowercased; it must match `^[a-z0-9_]{3,20}$`.
  - Claimed in one transaction: create `usernames/{username}` = `{uid}` and set `users/{uid}` = `{username, displayName}`.
- **Display name**: from Google, or an optional field at sign-up; defaults to the username.
- **Account screen** section: shows username, display name and email, with a Sign out button.

**Out:** changing a username, deleting an account, email verification enforcement, other providers (Apple, phone).

## Data owned

| Path | Fields | Notes |
|---|---|---|
| `users/{uid}` | `username`, `displayName`, `householdId?` | `householdId` is written by `households` |
| `usernames/{username}` | `uid` | Doc id = lowercased username; this is the uniqueness lock |

**Rules**
- `usernames/{u}`:
  - `get`: any signed-in user (needed for invites). `list` is denied.
  - `create`: only if the doc doesn't exist, `request.resource.data.uid == request.auth.uid`, the id matches the regex, and the caller's `users/{uid}` has no username yet (checked with `getAfter` on the same transaction).
  - `update` and `delete`: denied.
- `users/{uid}`:
  - `get`: any signed-in user (shows member names). `list` is denied.
  - `create`/`update`: only the owner.
  - `username` is immutable once set, and must equal the doc id of a `usernames` entry owned by this uid.
  - `householdId` changes are governed by `households` rules.

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
   - user A cannot write `users/B`
   - A cannot create `usernames/x` with `uid: B`
   - A cannot overwrite or delete an existing `usernames/x`
   - A cannot change their `username` after it's set
   - a signed-in user cannot `list` `users` or `usernames`
   - an unauthenticated user cannot `get` either
10. **AC-ID-10**: All identity screens render in EN and ES.

## Tests

- `test/data/user_repository_test.dart` (`fake_cloud_firestore`): AC-ID-4, AC-ID-5.
- `test/ui/auth/view_models/*_test.dart` (`firebase_auth_mocks`): AC-ID-1, AC-ID-2, AC-ID-7.
- `test/domain/username_test.dart`: the regex table for AC-ID-6.
- `test/ui/auth/*_screen_test.dart`: validation messages and EN/ES (AC-ID-10).
- `firebase/test/identity.test.js`: AC-ID-9.
- Manual: Google on web and on the Android emulator (AC-ID-3); password reset via the emulator log (AC-ID-8).

## Open questions

- Minimum password length: Firebase's default (6), or require 8?
