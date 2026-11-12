# Module Spec: `households`

> Depends on: `identity` · Used by: `inventory`, `grocery-list`, `restock-suggestions`, `recipes` · Delivery: Stage 3
> Status: draft, awaiting review

## Objective

Group people who share food: one household per user. Everyone in it sees and edits the same inventory, grocery list, stock levels and recipes. People join only by invitation, using their username.

## Scope

**In**
- **Household gate**, after identity: if the profile has no `householdId`, show Household setup; otherwise show the app shell.
  - The shell subtree is keyed by `householdId`, so changing household disposes every household-scoped view model.
- **Household setup** (no household):
  - Create a household (name, 1–40 chars). This runs one batch: `households/{hid}` with `memberIds: [uid]` + `users/{uid}.householdId = hid`.
  - List of received invites with Accept and Decline.
- **Household screen** (from the app-bar account action):
  - household name, editable by any member
  - members list: display name + `@username`
  - "Invite by username" field
  - sent invites, each with Cancel
  - received invites from other households, with Accept disabled and the hint "Leave your current household first"
  - Leave button
- **Invite**: look up the uid by username, then create `invites/{hid}_{toUid}`.
- **Accept**: one batch adds `memberIds` ∪ {uid}, sets `users/{uid}.householdId = hid`, and deletes the invite.
- **Decline / cancel**: delete the invite.
- **Leave**: one batch removes `memberIds` − {uid} and sets `users/{uid}.householdId = null`. The household's data stays with the remaining members.
  - The **last member cannot leave**: the button is disabled with an explanation. This prevents orphaned, unreachable data.
- Firestore rule helper `isMember(hid)`. All `households/{hid}/**` data is readable and writable only by members.

**Out:** multiple households per user, removing other members, transferring ownership, deleting a household, invite links/QR codes.

## Data owned

| Path | Fields |
|---|---|
| `households/{hid}` | `name`, `memberIds` (array of uid), `createdBy`, `recipesSeeded` (bool, written by `recipes`) |
| `invites/{hid}_{toUid}` | `householdId`, `householdName`, `fromUid`, `fromUsername`, `toUid`, `createdAt` |
| `users/{uid}.householdId` | written by this module only |

**Rules** (`isMember(hid)` = signed in and `request.auth.uid in get(households/hid).memberIds`)
- `households/{hid}`:
  - **get**: a member, or the holder of an invite `invites/{hid}_{auth.uid}`.
  - **list**: denied.
  - **create**: `memberIds == [auth.uid]`, `createdBy == auth.uid`, and the caller's `users` doc has no `householdId`.
  - **update by a member**:
    - only `name` / `recipesSeeded` change, **or**
    - `memberIds` loses exactly the caller (leave), and the old size was > 1.
  - **update by a non-member (join)**: only `memberIds` changes, and it gains exactly `auth.uid`. An invite `invites/{hid}_{auth.uid}` must exist, and the caller's `users.householdId` must be null.
  - **delete**: denied.
- `households/{hid}/{document=**}`: read and write if `isMember(hid)`. Owning modules add field validation.
- `invites/{id}`:
  - **create**:
    - `id == householdId + "_" + toUid`
    - `fromUid == auth.uid`, and the caller `isMember(householdId)`
    - `toUid != auth.uid`, and `toUid` is not already a member
  - **read**: `toUid == auth.uid` or `isMember(householdId)`. This allows the queries "my invites" (`where toUid == me`) and "sent invites" (`where householdId == hid`).
  - **delete**: `toUid == auth.uid` or `isMember(householdId)`.
  - **update**: denied.
- `users/{uid}.householdId`: the owner may set it to `hid` only if the caller is in `getAfter(households/hid).memberIds`, or to `null` only if the caller is no longer in the old household's `getAfter(...).memberIds`.

## Interface exposed to other modules

```dart
class HouseholdRepository {
  Stream<Household?> watchHousehold(String hid);
  Future<String> create(String name);                        // returns hid
  Future<void> rename(String hid, String name);
  Future<void> invite(String hid, String username);          // throws UserNotFound, AlreadyMember, AlreadyInvited, CannotInviteSelf
  Stream<List<Invite>> watchReceivedInvites(String uid);
  Stream<List<Invite>> watchSentInvites(String hid);
  Future<void> accept(Invite invite);                        // throws AlreadyInHousehold
  Future<void> decline(Invite invite);                       // also used for cancel
  Future<void> leave(String hid);                            // throws LastMember
}
```

`CurrentHousehold` (provided above the shell) exposes `hid` and `members` (uid → display name/username). Household-scoped repositories are constructed with `hid`.

## Acceptance criteria

1. **AC-HH-1**: A signed-in user with no household sees Household setup. Creating "Casa" puts them into the app shell, `households/{hid}.memberIds == [uid]`, and `users/{uid}.householdId == hid`.
2. **AC-HH-2**: An empty name or a name over 40 chars is rejected with a validation message, and nothing is written.
3. **AC-HH-3**: A (member of "Casa") invites `bea`. Bea's setup screen shows "Casa — invited by @a" within ~2 s, without a refresh.
4. **AC-HH-4**: Bea taps Accept and lands in the shell of "Casa". `memberIds` contains both uids, Bea's `householdId == hid`, and the invite doc is gone. A's members list shows Bea within ~2 s.
5. **AC-HH-5**: Inviting an unknown username → "User not found". Inviting yourself → "You can't invite yourself". Inviting a current member → "Already a member". Inviting twice → "Already invited". None of these write anything.
6. **AC-HH-6**: Decline removes the invite on both sides. Cancel by the sender removes it on both sides.
7. **AC-HH-7**: A user who already has a household sees received invites with Accept disabled and the hint to leave first.
8. **AC-HH-8**: Bea leaves "Casa": she returns to Household setup, A's members list drops her, and A still sees all household data.
9. **AC-HH-9**: The last remaining member cannot leave: the button is disabled with an explanation.
10. **AC-HH-10**: Rules (emulator):
    - a non-member cannot get the household or read/write any doc under `households/{hid}/**`
    - a non-member without an invite cannot add themselves to `memberIds`
    - an invitee cannot add anyone other than themselves, or change `name`
    - a member cannot remove another member
    - nobody can create an invite on behalf of another uid or for a household they're not in
    - a user cannot point `users/{uid}.householdId` at a household they're not a member of
    - a third user cannot read an invite between A and Bea
11. **AC-HH-11**: All household screens render in EN and ES.

## Tests

- `test/data/household_repository_test.dart` (`fake_cloud_firestore`): AC-HH-1, AC-HH-4, AC-HH-5, AC-HH-6, AC-HH-8, AC-HH-9 (write shapes and thrown errors).
- `test/ui/household/*_test.dart`: setup screen, household screen states, validation, EN/ES.
- `firebase/test/households.test.js`: every allow and deny path in AC-HH-10. This is the most important test file in the project.
- Manual: two accounts (web + Android) for AC-HH-3, AC-HH-4 and AC-HH-8 live updates.

## Open questions

- None blocking. Possible later additions: removing a member, multiple households.
