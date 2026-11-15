// AC-AF-8: with no module rules yet, every read and write is denied.
import { readFileSync } from 'node:fs';
import { after, before, test } from 'node:test';
import { assertFails, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-fridge',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(() => env.cleanup());

const callers = {
  unauthenticated: () => env.unauthenticatedContext(),
  authenticated: () => env.authenticatedContext('ana'),
};

for (const [who, context] of Object.entries(callers)) {
  test(`${who} read of /anything/x is denied`, async () => {
    await assertFails(getDoc(doc(context().firestore(), 'anything/x')));
  });

  test(`${who} write of /anything/x is denied`, async () => {
    await assertFails(setDoc(doc(context().firestore(), 'anything/x'), { a: 1 }));
  });
}
