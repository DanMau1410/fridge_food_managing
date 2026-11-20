// AC-ID-9: the username lock (`usernames/{u}`) and profiles (`users/{uid}`).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-fridge',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(() => env.cleanup());

/** Writes a claimed username and its profile, bypassing the rules. */
function seedUser(uid, username, displayName) {
  return env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `usernames/${username}`), { uid });
    await setDoc(doc(db, `users/${uid}`), { username, displayName });
  });
}

// Every test starts with B owning `bea`, and A signed up but without a username.
beforeEach(async () => {
  await env.clearFirestore();
  await seedUser('B', 'bea', 'Bea');
});

const as = (uid) => env.authenticatedContext(uid).firestore();

/** The app's claim: both docs in one write, as its transaction commits them. */
function claim(db, uid, username, profile = { username, displayName: 'Ana' }) {
  const batch = writeBatch(db);
  batch.set(doc(db, `usernames/${username}`), { uid });
  batch.set(doc(db, `users/${uid}`), profile);
  return batch.commit();
}

// Allowed paths.

test('A claims a username with both docs in one write', async () => {
  await assertSucceeds(claim(as('A'), 'A', 'ana'));
});

test('A reads B by username and by uid', async () => {
  const db = as('A');
  await assertSucceeds(getDoc(doc(db, 'usernames/bea')));
  await assertSucceeds(getDoc(doc(db, 'users/B')));
});

test('A changes their own display name', async () => {
  await seedUser('A', 'ana', 'Ana');
  await assertSucceeds(updateDoc(doc(as('A'), 'users/A'), { displayName: 'Ana María' }));
});

test('a display name of 30 UTF-16 units (accents and emoji) is allowed', async () => {
  // Dart's String.length counts like JS: 5 emoji × 2 + 20 accented letters = 30.
  const name = '😀'.repeat(5) + 'é'.repeat(20);
  if (name.length !== 30) throw new Error(`fixture length ${name.length}`);
  await assertSucceeds(claim(as('A'), 'A', 'ana', { username: 'ana', displayName: name }));
});

// Taking or squatting names.

test('A cannot create a username for B', async () => {
  const db = as('A');
  await assertFails(setDoc(doc(db, 'usernames/zed'), { uid: 'B' }));
  await assertFails(claim(db, 'B', 'zed'));
});

test('A cannot overwrite or delete a taken username', async () => {
  const db = as('A');
  await assertFails(setDoc(doc(db, 'usernames/bea'), { uid: 'A' }));
  await assertFails(claim(db, 'A', 'bea'));
  await assertFails(deleteDoc(doc(db, 'usernames/bea')));
});

test('neither doc can be created without the other', async () => {
  const db = as('A');
  await assertFails(setDoc(doc(db, 'usernames/ana'), { uid: 'A' }));
  await assertFails(setDoc(doc(db, 'users/A'), { username: 'ana', displayName: 'Ana' }));
});

test('the profile must name the username it claims', async () => {
  await assertFails(claim(as('A'), 'A', 'ana', { username: 'other', displayName: 'Ana' }));
});

test('A cannot claim a second username', async () => {
  await seedUser('A', 'ana', 'Ana');
  await assertFails(claim(as('A'), 'A', 'ana2'));
});

test('usernames that fail the regex are refused', async () => {
  const db = as('A');
  for (const name of ['Ana', 'an', 'an-a', 'a'.repeat(21)]) {
    await assertFails(claim(db, 'A', name));
  }
});

// Profiles.

test('A cannot write or rename B', async () => {
  const db = as('A');
  await assertFails(setDoc(doc(db, 'users/B'), { username: 'bea', displayName: 'Hacked' }));
  await assertFails(updateDoc(doc(db, 'users/B'), { displayName: 'Hacked' }));
  await assertFails(setDoc(doc(db, 'users/C'), { username: 'cid', displayName: 'Cid' }));
});

test('A cannot change their username after it is set', async () => {
  await seedUser('A', 'ana', 'Ana');
  await assertFails(updateDoc(doc(as('A'), 'users/A'), { username: 'other' }));
});

test('extra fields are refused on create and on update', async () => {
  const db = as('A');
  const profile = { username: 'ana', displayName: 'Ana', householdId: 'h1' };
  await assertFails(claim(db, 'A', 'ana', profile));
  await seedUser('A', 'ana', 'Ana');
  await assertFails(updateDoc(doc(db, 'users/A'), { isAdmin: true }));
  await assertFails(updateDoc(doc(db, 'users/A'), { householdId: 'h1' }));
});

test('a missing, empty, blank, too long or non-string display name is refused', async () => {
  const db = as('A');
  await assertFails(claim(db, 'A', 'ana', { username: 'ana' }));
  for (const displayName of ['', '   ', 'x'.repeat(31), 42]) {
    await assertFails(claim(db, 'A', 'ana', { username: 'ana', displayName }));
  }
  await seedUser('A', 'ana', 'Ana');
  await assertFails(updateDoc(doc(db, 'users/A'), { displayName: 'x'.repeat(31) }));
  await assertFails(updateDoc(doc(db, 'users/A'), { displayName: ' ' }));
});

test('profiles cannot be deleted', async () => {
  await seedUser('A', 'ana', 'Ana');
  await assertFails(deleteDoc(doc(as('A'), 'users/A')));
});

// Reading.

test('a signed-in user cannot list users or usernames', async () => {
  const db = as('A');
  await assertFails(getDocs(collection(db, 'users')));
  await assertFails(getDocs(collection(db, 'usernames')));
});

test('a signed-out user cannot get users or usernames', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/B')));
  await assertFails(getDoc(doc(db, 'usernames/bea')));
});
