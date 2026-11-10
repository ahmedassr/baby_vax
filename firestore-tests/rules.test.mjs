// Security-rules tests for ../firestore.rules, run against the Firestore
// emulator. Nothing here touches the live project.
//
// Run with: npm test   (from this directory)

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

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
  Timestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const ALICE = 'alice_uid';
const BOB = 'bob_uid';

/** A user document that satisfies the rules. */
const validUser = (uid) => ({
  uid,
  email: 'parent@example.com',
  birthday: '2026-01-15 09:00:00',
  name: 'Lina',
  height: '52',
  weight: '3.4',
  bloodPercentage: '12',
  headSize: '35',
});

/** A medical_dates document that satisfies the rules. */
const validMedicalDate = (overrides = {}) => ({
  name: 'BCG and Hepatitis B (1st dose)',
  description: 'Protects against tuberculosis and hepatitis B.',
  date: Timestamp.fromDate(new Date('2026-01-15T00:00:00Z')),
  state: 'Pending',
  code: 'bcg_hepb_birth',
  ...overrides,
});

/** A copy of [obj] without [key]. */
const without = (obj, key) =>
  Object.fromEntries(Object.entries(obj).filter(([k]) => k !== key));

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'baby-vax-rules-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

/** Firestore handle for a signed-in user. */
const asUser = (uid) => testEnv.authenticatedContext(uid).firestore();
/** Firestore handle for a signed-out client. */
const asAnon = () => testEnv.unauthenticatedContext().firestore();

/** Seeds data with the rules bypassed. */
const seed = (fn) => testEnv.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

describe('users/{userId}', () => {
  it('lets the owner read their own profile', async () => {
    await seed((db) => setDoc(doc(db, `users/${ALICE}`), validUser(ALICE)));
    await assertSucceeds(getDoc(doc(asUser(ALICE), `users/${ALICE}`)));
  });

  it("denies reading another user's profile", async () => {
    await seed((db) => setDoc(doc(db, `users/${ALICE}`), validUser(ALICE)));
    await assertFails(getDoc(doc(asUser(BOB), `users/${ALICE}`)));
  });

  it('denies a signed-out client', async () => {
    await seed((db) => setDoc(doc(db, `users/${ALICE}`), validUser(ALICE)));
    await assertFails(getDoc(doc(asAnon(), `users/${ALICE}`)));
  });

  it('lets the owner create their own profile', async () => {
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `users/${ALICE}`), validUser(ALICE)),
    );
  });

  it("denies creating a profile at another user's id", async () => {
    await assertFails(
      setDoc(doc(asUser(BOB), `users/${ALICE}`), validUser(ALICE)),
    );
  });

  it('denies a profile whose uid field does not match the document id', async () => {
    // Otherwise a profile could claim to belong to someone else.
    await assertFails(
      setDoc(doc(asUser(ALICE), `users/${ALICE}`), validUser(BOB)),
    );
  });

  it('denies unknown fields', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `users/${ALICE}`), {
        ...validUser(ALICE),
        isAdmin: true,
      }),
    );
  });

  it('denies a non-string email', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `users/${ALICE}`), {
        ...validUser(ALICE),
        email: 12345,
      }),
    );
  });

  it('denies an oversized name', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `users/${ALICE}`), {
        ...validUser(ALICE),
        name: 'x'.repeat(101),
      }),
    );
  });

  it('lets the owner delete their profile, as account deletion needs', async () => {
    await seed((db) => setDoc(doc(db, `users/${ALICE}`), validUser(ALICE)));
    await assertSucceeds(deleteDoc(doc(asUser(ALICE), `users/${ALICE}`)));
  });

  it("denies deleting another user's profile", async () => {
    await seed((db) => setDoc(doc(db, `users/${ALICE}`), validUser(ALICE)));
    await assertFails(deleteDoc(doc(asUser(BOB), `users/${ALICE}`)));
  });
});

describe('users/{userId}/medical_dates/{id}', () => {
  const path = (uid) => `users/${uid}/medical_dates`;

  it('lets the owner list their schedule', async () => {
    await seed((db) =>
      setDoc(doc(db, `${path(ALICE)}/v1`), validMedicalDate()),
    );
    await assertSucceeds(getDocs(collection(asUser(ALICE), path(ALICE))));
  });

  it("denies listing another user's schedule", async () => {
    await seed((db) =>
      setDoc(doc(db, `${path(ALICE)}/v1`), validMedicalDate()),
    );
    await assertFails(getDocs(collection(asUser(BOB), path(ALICE))));
  });

  it('lets the owner create a valid record', async () => {
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/v1`), validMedicalDate()),
    );
  });

  it('accepts a record without the optional code', async () => {
    await assertSucceeds(
      setDoc(
        doc(asUser(ALICE), `${path(ALICE)}/v1`),
        without(validMedicalDate(), 'code'),
      ),
    );
  });

  it('denies a record with an unknown state', async () => {
    await assertFails(
      setDoc(
        doc(asUser(ALICE), `${path(ALICE)}/v1`),
        validMedicalDate({ state: 'Whatever' }),
      ),
    );
  });

  it('denies a record whose date is not a timestamp', async () => {
    await assertFails(
      setDoc(
        doc(asUser(ALICE), `${path(ALICE)}/v1`),
        validMedicalDate({ date: '2026-01-15' }),
      ),
    );
  });

  it('denies a record with no name', async () => {
    await assertFails(
      setDoc(
        doc(asUser(ALICE), `${path(ALICE)}/v1`),
        without(validMedicalDate(), 'name'),
      ),
    );
  });

  it('denies an oversized description', async () => {
    await assertFails(
      setDoc(
        doc(asUser(ALICE), `${path(ALICE)}/v1`),
        validMedicalDate({ description: 'x'.repeat(1001) }),
      ),
    );
  });

  it('denies unknown fields', async () => {
    await assertFails(
      setDoc(
        doc(asUser(ALICE), `${path(ALICE)}/v1`),
        validMedicalDate({ injected: 'value' }),
      ),
    );
  });

  it("denies writing into another user's schedule", async () => {
    await assertFails(
      setDoc(doc(asUser(BOB), `${path(ALICE)}/v1`), validMedicalDate()),
    );
  });

  it('lets the owner delete a record, as account deletion needs', async () => {
    await seed((db) =>
      setDoc(doc(db, `${path(ALICE)}/v1`), validMedicalDate()),
    );
    await assertSucceeds(deleteDoc(doc(asUser(ALICE), `${path(ALICE)}/v1`)));
  });

  it('denies a signed-out client', async () => {
    await assertFails(
      setDoc(doc(asAnon(), `${path(ALICE)}/v1`), validMedicalDate()),
    );
  });

  // The app's state changes write only { state } (FirestoreDoseStateWriter).
  // Every transition the app allows must pass the deployed rules.
  for (const [from, to] of [
    ['Pending', 'Completed'],
    ['Pending', 'Skipped'],
    ['Completed', 'Pending'],
    ['Skipped', 'Pending'],
  ]) {
    it(`lets the owner change state ${from} -> ${to}`, async () => {
      await seed((db) =>
        setDoc(
          doc(db, `${path(ALICE)}/v1`),
          validMedicalDate({ state: from }),
        ),
      );
      await assertSucceeds(
        updateDoc(doc(asUser(ALICE), `${path(ALICE)}/v1`), { state: to }),
      );
    });
  }

  it('allows a state change on a record without a code', async () => {
    await seed((db) =>
      setDoc(doc(db, `${path(ALICE)}/v1`), without(validMedicalDate(), 'code')),
    );
    await assertSucceeds(
      updateDoc(doc(asUser(ALICE), `${path(ALICE)}/v1`), {
        state: 'Completed',
      }),
    );
  });

  it('denies a state update to Overdue, which is display-only', async () => {
    await seed((db) =>
      setDoc(doc(db, `${path(ALICE)}/v1`), validMedicalDate()),
    );
    await assertFails(
      updateDoc(doc(asUser(ALICE), `${path(ALICE)}/v1`), { state: 'Overdue' }),
    );
  });

  it("denies changing the state of another user's record", async () => {
    await seed((db) =>
      setDoc(doc(db, `${path(ALICE)}/v1`), validMedicalDate()),
    );
    await assertFails(
      updateDoc(doc(asUser(BOB), `${path(ALICE)}/v1`), { state: 'Skipped' }),
    );
  });
});

describe('sign-up batch', () => {
  // Sign-up writes the profile and the whole generated schedule in one
  // batch with client-generated ids (FireStoreHelperService.commitSets).
  it('lets a new user write profile and schedule in one batch', async () => {
    const db = asUser(ALICE);
    const batch = writeBatch(db);
    batch.set(doc(db, `users/${ALICE}`), validUser(ALICE));
    for (let i = 0; i < 12; i++) {
      batch.set(
        doc(collection(db, `users/${ALICE}/medical_dates`)),
        validMedicalDate({ code: `code_${i}` }),
      );
    }
    await assertSucceeds(batch.commit());
  });

  it('rejects the whole batch if one record is invalid', async () => {
    const db = asUser(ALICE);
    const batch = writeBatch(db);
    batch.set(doc(db, `users/${ALICE}`), validUser(ALICE));
    batch.set(
      doc(collection(db, `users/${ALICE}/medical_dates`)),
      validMedicalDate({ state: 'Overdue' }),
    );
    await assertFails(batch.commit());
  });
});

describe('tips content', () => {
  for (const coll of ['tips', 'tips_en']) {
    it(`lets a signed-in user read ${coll}`, async () => {
      await seed((db) => setDoc(doc(db, `${coll}/t1`), { title: 'Sleep' }));
      await assertSucceeds(getDoc(doc(asUser(ALICE), `${coll}/t1`)));
    });

    it(`denies a signed-out client reading ${coll}`, async () => {
      await seed((db) => setDoc(doc(db, `${coll}/t1`), { title: 'Sleep' }));
      await assertFails(getDoc(doc(asAnon(), `${coll}/t1`)));
    });

    it(`denies any client writing ${coll}`, async () => {
      // Tips are authored in the console; no client may write them.
      await assertFails(
        setDoc(doc(asUser(ALICE), `${coll}/t1`), { title: 'Injected' }),
      );
    });
  }
});

describe('default deny', () => {
  it('denies reading an undeclared collection', async () => {
    await seed((db) => setDoc(doc(db, 'admin_settings/s1'), { x: 1 }));
    await assertFails(getDoc(doc(asUser(ALICE), 'admin_settings/s1')));
  });

  it('denies writing an undeclared collection', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), 'admin_settings/s1'), { x: 1 }),
    );
  });

  it('denies writing a collection group that merely looks owned', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `users/${ALICE}/secrets/s1`), { x: 1 }),
    );
  });
});
