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
  deleteField,
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

  // v1.1: optional `sex` for the growth charts.
  it('accepts a v1.0 profile with no sex field (existing users stay valid)', async () => {
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `users/${ALICE}`), validUser(ALICE)),
    );
    await seed((db) => setDoc(doc(db, `users/${ALICE}`), validUser(ALICE)));
    // And an edit that does not touch it still passes.
    await assertSucceeds(
      updateDoc(doc(asUser(ALICE), `users/${ALICE}`), { name: 'Lina M.' }),
    );
  });

  for (const sex of ['female', 'male']) {
    it(`accepts sex "${sex}"`, async () => {
      await assertSucceeds(
        setDoc(doc(asUser(ALICE), `users/${ALICE}`), {
          ...validUser(ALICE),
          sex,
        }),
      );
    });
  }

  it('accepts sex set back to null', async () => {
    await seed((db) =>
      setDoc(doc(db, `users/${ALICE}`), { ...validUser(ALICE), sex: 'female' }),
    );
    await assertSucceeds(
      updateDoc(doc(asUser(ALICE), `users/${ALICE}`), { sex: null }),
    );
  });

  for (const sex of ['F', 'other', '', 1, true]) {
    it(`denies sex ${JSON.stringify(sex)}`, async () => {
      await assertFails(
        setDoc(doc(asUser(ALICE), `users/${ALICE}`), {
          ...validUser(ALICE),
          sex,
        }),
      );
    });
  }

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

describe('users/{userId}/medical_dates/{id} — v1.1 dose record', () => {
  const path = (uid) => `users/${uid}/medical_dates`;
  const record = {
    givenDate: Timestamp.fromDate(new Date('2026-03-16T00:00:00Z')),
    clinic: 'Ramallah MCH clinic',
    lot: 'AB1234',
    note: 'Slight fever that evening.',
  };

  it('existing v1.0 doses (no record fields) still pass an update', async () => {
    await seed((db) =>
      setDoc(doc(db, `${path(ALICE)}/v1`), validMedicalDate()),
    );
    await assertSucceeds(
      updateDoc(doc(asUser(ALICE), `${path(ALICE)}/v1`), { state: 'Skipped' }),
    );
  });

  it('marking given with a full record passes', async () => {
    await seed((db) =>
      setDoc(doc(db, `${path(ALICE)}/v1`), validMedicalDate()),
    );
    await assertSucceeds(
      updateDoc(doc(asUser(ALICE), `${path(ALICE)}/v1`), {
        state: 'Completed',
        ...record,
      }),
    );
  });

  for (const field of Object.keys(record)) {
    it(`a record with only ${field} passes`, async () => {
      await assertSucceeds(
        setDoc(
          doc(asUser(ALICE), `${path(ALICE)}/v1`),
          validMedicalDate({ state: 'Completed', [field]: record[field] }),
        ),
      );
    });
  }

  it('undo removes the record in the same write', async () => {
    await seed((db) =>
      setDoc(
        doc(db, `${path(ALICE)}/v1`),
        validMedicalDate({ state: 'Completed', ...record }),
      ),
    );
    await assertSucceeds(
      updateDoc(doc(asUser(ALICE), `${path(ALICE)}/v1`), {
        state: 'Pending',
        givenDate: deleteField(),
        clinic: deleteField(),
        lot: deleteField(),
        note: deleteField(),
      }),
    );
  });

  it('a v1.0 client undoing a recorded dose (state only) is not rejected', async () => {
    // v1.0 builds write only { state }. The record stays behind on the
    // document; v1.1 ignores it on a pending dose and clears it next time.
    await seed((db) =>
      setDoc(
        doc(db, `${path(ALICE)}/v1`),
        validMedicalDate({ state: 'Completed', ...record }),
      ),
    );
    await assertSucceeds(
      updateDoc(doc(asUser(ALICE), `${path(ALICE)}/v1`), { state: 'Pending' }),
    );
  });

  it('denies a givenDate that is not a timestamp', async () => {
    await assertFails(
      setDoc(
        doc(asUser(ALICE), `${path(ALICE)}/v1`),
        validMedicalDate({ state: 'Completed', givenDate: '2026-03-16' }),
      ),
    );
  });

  for (const [field, max] of [['clinic', 120], ['lot', 60], ['note', 500]]) {
    it(`denies an oversized ${field}`, async () => {
      await assertFails(
        setDoc(
          doc(asUser(ALICE), `${path(ALICE)}/v1`),
          validMedicalDate({ state: 'Completed', [field]: 'x'.repeat(max + 1) }),
        ),
      );
    });

    it(`denies a non-string ${field}`, async () => {
      await assertFails(
        setDoc(
          doc(asUser(ALICE), `${path(ALICE)}/v1`),
          validMedicalDate({ state: 'Completed', [field]: 42 }),
        ),
      );
    });
  }

  it("denies writing a record on another user's dose", async () => {
    await seed((db) =>
      setDoc(doc(db, `${path(ALICE)}/v1`), validMedicalDate()),
    );
    await assertFails(
      updateDoc(doc(asUser(BOB), `${path(ALICE)}/v1`), {
        state: 'Completed',
        ...record,
      }),
    );
  });
});

describe('users/{userId}/measurements/{id} — v1.1 growth', () => {
  const path = (uid) => `users/${uid}/measurements`;
  const valid = (overrides = {}) => ({
    date: Timestamp.fromDate(new Date('2026-03-16T00:00:00Z')),
    weightKg: 4.2,
    heightCm: 55.5,
    headCm: 38,
    note: 'Clinic visit',
    ...overrides,
  });

  it('lets the owner add, read, list, edit and delete', async () => {
    const db = asUser(ALICE);
    await assertSucceeds(setDoc(doc(db, `${path(ALICE)}/m1`), valid()));
    await assertSucceeds(getDoc(doc(db, `${path(ALICE)}/m1`)));
    await assertSucceeds(getDocs(collection(db, path(ALICE))));
    await assertSucceeds(updateDoc(doc(db, `${path(ALICE)}/m1`), { weightKg: 4.3 }));
    await assertSucceeds(deleteDoc(doc(db, `${path(ALICE)}/m1`)));
  });

  for (const only of ['weightKg', 'heightCm', 'headCm']) {
    it(`accepts a measurement with only ${only}`, async () => {
      const m = { date: valid().date, [only]: valid()[only] };
      await assertSucceeds(setDoc(doc(asUser(ALICE), `${path(ALICE)}/m1`), m));
    });
  }

  it('accepts whole numbers (Firestore integers)', async () => {
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/m1`), valid({ weightKg: 4 })),
    );
  });

  it('denies a measurement with no values', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/m1`), { date: valid().date }),
    );
  });

  it('denies a measurement with no date', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/m1`), without(valid(), 'date')),
    );
  });

  it('denies a date that is not a timestamp', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/m1`), valid({ date: '2026-03-16' })),
    );
  });

  for (const [field, bad] of [
    ['weightKg', 3400], ['weightKg', 0], ['weightKg', '4.2'],
    ['heightCm', 2000], ['heightCm', 5],
    ['headCm', 100], ['headCm', -1],
  ]) {
    it(`denies ${field} = ${JSON.stringify(bad)}`, async () => {
      await assertFails(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/m1`), valid({ [field]: bad })),
      );
    });
  }

  it('denies an oversized note', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/m1`), valid({ note: 'x'.repeat(501) })),
    );
  });

  it('denies unknown fields', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/m1`), valid({ bmi: 14 })),
    );
  });

  it("denies reading or writing another user's measurements", async () => {
    await seed((db) => setDoc(doc(db, `${path(ALICE)}/m1`), valid()));
    await assertFails(getDoc(doc(asUser(BOB), `${path(ALICE)}/m1`)));
    await assertFails(getDocs(collection(asUser(BOB), path(ALICE))));
    await assertFails(setDoc(doc(asUser(BOB), `${path(ALICE)}/m2`), valid()));
    await assertFails(deleteDoc(doc(asUser(BOB), `${path(ALICE)}/m1`)));
  });

  it('denies a signed-out client', async () => {
    await assertFails(setDoc(doc(asAnon(), `${path(ALICE)}/m1`), valid()));
  });
});

describe('users/{userId}/milestones/{id} — v1.1 motor milestones', () => {
  const path = (uid) => `users/${uid}/milestones`;
  const ids = [
    'sitting', 'crawling', 'standingAssisted',
    'walkingAssisted', 'standingAlone', 'walkingAlone',
  ];
  const valid = (overrides = {}) => ({
    achievedAt: Timestamp.fromDate(new Date('2026-05-12T00:00:00Z')),
    note: 'Sat for a whole song',
    ...overrides,
  });

  it('lets the owner add, read, list, edit and delete', async () => {
    const db = asUser(ALICE);
    await assertSucceeds(setDoc(doc(db, `${path(ALICE)}/sitting`), valid()));
    await assertSucceeds(getDoc(doc(db, `${path(ALICE)}/sitting`)));
    await assertSucceeds(getDocs(collection(db, path(ALICE))));
    await assertSucceeds(
      updateDoc(doc(db, `${path(ALICE)}/sitting`), { note: 'Edited' }),
    );
    await assertSucceeds(
      updateDoc(doc(db, `${path(ALICE)}/sitting`), { note: deleteField() }),
    );
    await assertSucceeds(deleteDoc(doc(db, `${path(ALICE)}/sitting`)));
  });

  for (const id of ids) {
    it(`accepts the milestone id ${id}`, async () => {
      await assertSucceeds(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/${id}`), { achievedAt: valid().achievedAt }),
      );
    });
  }

  it('accepts a note for the doctor visit without a date', async () => {
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/walkingAlone`), { note: 'Ask at the 18-month visit' }),
    );
  });

  it('accepts a date of today (now)', async () => {
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/sitting`), {
        achievedAt: Timestamp.fromMillis(Date.now() - 60 * 1000),
      }),
    );
  });

  for (const id of ['running', 'Sitting', 'sitting2', 'm1']) {
    it(`denies an unknown milestone id ${id}`, async () => {
      await assertFails(setDoc(doc(asUser(ALICE), `${path(ALICE)}/${id}`), valid()));
    });
  }

  it('denies a date in the future', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/sitting`), {
        achievedAt: Timestamp.fromMillis(Date.now() + 2 * 24 * 3600 * 1000),
      }),
    );
  });

  for (const bad of ['2026-05-12', 1715472000, null, true]) {
    it(`denies achievedAt = ${JSON.stringify(bad)}`, async () => {
      await assertFails(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/sitting`), valid({ achievedAt: bad })),
      );
    });
  }

  it('denies an empty document, and an empty or non-text note alone', async () => {
    const db = asUser(ALICE);
    await assertFails(setDoc(doc(db, `${path(ALICE)}/sitting`), {}));
    await assertFails(setDoc(doc(db, `${path(ALICE)}/sitting`), { note: '' }));
    await assertFails(setDoc(doc(db, `${path(ALICE)}/sitting`), { note: null }));
    await assertFails(setDoc(doc(db, `${path(ALICE)}/sitting`), { note: 42 }));
  });

  it('denies a note over 300 characters', async () => {
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/sitting`), valid({ note: 'x'.repeat(300) })),
    );
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/sitting`), valid({ note: 'x'.repeat(301) })),
    );
  });

  it('denies unknown fields', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/sitting`), valid({ ageMonths: 6 })),
    );
  });

  it("denies reading or writing another user's milestones", async () => {
    await seed((db) => setDoc(doc(db, `${path(ALICE)}/sitting`), valid()));
    await assertFails(getDoc(doc(asUser(BOB), `${path(ALICE)}/sitting`)));
    await assertFails(getDocs(collection(asUser(BOB), path(ALICE))));
    await assertFails(setDoc(doc(asUser(BOB), `${path(ALICE)}/crawling`), valid()));
    await assertFails(deleteDoc(doc(asUser(BOB), `${path(ALICE)}/sitting`)));
  });

  it('denies a signed-out client', async () => {
    await assertFails(setDoc(doc(asAnon(), `${path(ALICE)}/sitting`), valid()));
    await assertFails(getDocs(collection(asAnon(), path(ALICE))));
  });
});

describe('users/{userId}/reminders/{id} — v1.1 custom reminders', () => {
  const path = (uid) => `users/${uid}/reminders`;
  const valid = (overrides = {}) => ({
    title: 'Vitamin D drops',
    note: '1 drop with the morning feed',
    dateTime: Timestamp.fromDate(new Date('2026-12-01T08:30:00Z')),
    repeat: 'daily',
    enabled: true,
    ...overrides,
  });

  it('lets the owner add, read, list, edit and delete', async () => {
    const db = asUser(ALICE);
    await assertSucceeds(setDoc(doc(db, `${path(ALICE)}/r1`), valid()));
    await assertSucceeds(getDoc(doc(db, `${path(ALICE)}/r1`)));
    await assertSucceeds(getDocs(collection(db, path(ALICE))));
    await assertSucceeds(updateDoc(doc(db, `${path(ALICE)}/r1`), { enabled: false }));
    await assertSucceeds(deleteDoc(doc(db, `${path(ALICE)}/r1`)));
  });

  for (const repeat of ['none', 'daily', 'weekly', 'monthly']) {
    it(`accepts repeat "${repeat}"`, async () => {
      await assertSucceeds(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/r1`), valid({ repeat })),
      );
    });
  }

  it('accepts a reminder without a note', async () => {
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/r1`), without(valid(), 'note')),
    );
  });

  for (const field of ['title', 'dateTime', 'repeat', 'enabled']) {
    it(`denies a reminder without ${field}`, async () => {
      await assertFails(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/r1`), without(valid(), field)),
      );
    });
  }

  for (const [field, bad] of [
    ['title', ''], ['title', 'x'.repeat(101)], ['title', 7],
    ['note', 'x'.repeat(501)],
    ['dateTime', '2026-12-01'],
    ['repeat', 'yearly'], ['repeat', 1],
    ['enabled', 'yes'],
  ]) {
    it(`denies ${field} = ${JSON.stringify(bad).slice(0, 20)}`, async () => {
      await assertFails(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/r1`), valid({ [field]: bad })),
      );
    });
  }

  it('denies unknown fields', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/r1`), valid({ sound: 'loud' })),
    );
  });

  it("denies reading or writing another user's reminders", async () => {
    await seed((db) => setDoc(doc(db, `${path(ALICE)}/r1`), valid()));
    await assertFails(getDoc(doc(asUser(BOB), `${path(ALICE)}/r1`)));
    await assertFails(getDocs(collection(asUser(BOB), path(ALICE))));
    await assertFails(setDoc(doc(asUser(BOB), `${path(ALICE)}/r2`), valid()));
    await assertFails(deleteDoc(doc(asUser(BOB), `${path(ALICE)}/r1`)));
  });

  it('denies a signed-out client', async () => {
    await assertFails(setDoc(doc(asAnon(), `${path(ALICE)}/r1`), valid()));
  });
});

describe('users/{userId} — v1.1 health profile', () => {
  it('accepts the four health fields, each optional', async () => {
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `users/${ALICE}`), {
        ...validUser(ALICE),
        allergies: 'Penicillin',
        conditions: 'None known',
        bloodType: 'O+',
        emergencyContact: { name: 'Mum', phone: '0599000000', relation: 'mother' },
      }),
    );
    await assertSucceeds(
      updateDoc(doc(asUser(ALICE), `users/${ALICE}`), { allergies: null }),
    );
  });

  for (const contact of [
    { name: 'Mum', phone: '0599000000' },
    { name: 'جدة سارة', phone: '+970599000000', relation: 'grandparent' },
    { name: 'Omar', phone: '123456', relation: 'other' },
    { name: 'x'.repeat(60), phone: '1'.repeat(15), relation: 'guardian' },
  ]) {
    it(`accepts emergency contact ${JSON.stringify(contact).slice(0, 40)}`, async () => {
      await assertSucceeds(
        setDoc(doc(asUser(ALICE), `users/${ALICE}`), {
          ...validUser(ALICE), emergencyContact: contact,
        }),
      );
    });
  }

  it('clears the emergency contact with null', async () => {
    await seed((db) => setDoc(doc(db, `users/${ALICE}`), {
      ...validUser(ALICE), emergencyContact: { name: 'Mum', phone: '0599000000' },
    }));
    await assertSucceeds(
      updateDoc(doc(asUser(ALICE), `users/${ALICE}`), { emergencyContact: null }),
    );
  });

  for (const bloodType of ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']) {
    it(`accepts blood type ${bloodType}`, async () => {
      await assertSucceeds(
        setDoc(doc(asUser(ALICE), `users/${ALICE}`), { ...validUser(ALICE), bloodType }),
      );
    });
  }

  for (const [field, bad] of [
    ['allergies', 'x'.repeat(301)], ['conditions', 'x'.repeat(301)],
    ['bloodType', 'O'], ['bloodType', 'o+'], ['bloodType', 1],
    ['allergies', 5],
    // The emergency contact is a map, not free text.
    ['emergencyContact', 'Mum 0599 000 000'],
    ['emergencyContact', { name: 'Mum' }],
    ['emergencyContact', { phone: '0599000000' }],
    ['emergencyContact', { name: '', phone: '0599000000' }],
    ['emergencyContact', { name: 'x'.repeat(61), phone: '0599000000' }],
    ['emergencyContact', { name: 'Mum', phone: '0599 000 000' }],
    ['emergencyContact', { name: 'Mum', phone: '12345' }],
    ['emergencyContact', { name: 'Mum', phone: '1'.repeat(16) }],
    ['emergencyContact', { name: 'Mum', phone: '05990000+0' }],
    ['emergencyContact', { name: 'Mum', phone: 599000000 }],
    ['emergencyContact', { name: 'Mum', phone: '0599000000', relation: 'aunt' }],
    ['emergencyContact', { name: 'Mum', phone: '0599000000', email: 'a@b.c' }],
  ]) {
    it(`denies ${field} = ${JSON.stringify(bad).slice(0, 20)}`, async () => {
      await assertFails(
        setDoc(doc(asUser(ALICE), `users/${ALICE}`), { ...validUser(ALICE), [field]: bad }),
      );
    });
  }
});

describe('users/{userId}/health_log/{id} — v1.1 Health tab', () => {
  const path = (uid) => `users/${uid}/health_log`;
  const at = Timestamp.fromDate(new Date('2027-03-10T09:20:00Z'));
  const valid = {
    temperature: { kind: 'temperature', at, tempC: 38.4, method: 'armpit', note: 'after the bath' },
    symptoms: { kind: 'symptoms', at, symptoms: ['feelsHot', 'feedingPoorly'], doseId: 'dose1' },
    medicine: { kind: 'medicine', at, medicine: 'Paracetamol', amount: '2.5 ml' },
    note: { kind: 'note', at, note: 'Slept well after the vaccine' },
  };

  it('lets the owner add, read, list, edit and delete', async () => {
    const db = asUser(ALICE);
    await assertSucceeds(setDoc(doc(db, `${path(ALICE)}/e1`), valid.temperature));
    await assertSucceeds(getDoc(doc(db, `${path(ALICE)}/e1`)));
    await assertSucceeds(getDocs(collection(db, path(ALICE))));
    await assertSucceeds(updateDoc(doc(db, `${path(ALICE)}/e1`), { tempC: 37.9 }));
    await assertSucceeds(deleteDoc(doc(db, `${path(ALICE)}/e1`)));
  });

  for (const [kind, data] of Object.entries(valid)) {
    it(`accepts a ${kind} entry`, async () => {
      await assertSucceeds(setDoc(doc(asUser(ALICE), `${path(ALICE)}/e1`), data));
    });
  }

  it('accepts every sign the app offers, together', async () => {
    const all = ['feelsHot', 'feedingPoorly', 'unableToFeed', 'vomiting',
      'vomitsEverything', 'diarrhoea', 'bloodInStool', 'cough', 'runnyNose',
      'fastBreathing', 'difficultBreathing', 'convulsions', 'lethargic',
      'lessActive', 'feelsCold', 'yellowSkin', 'rash', 'injectionSite', 'crying'];
    await assertSucceeds(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/e1`), { kind: 'symptoms', at, symptoms: all }),
    );
  });

  for (const method of ['armpit', 'rectal', 'other']) {
    it(`accepts method "${method}"`, async () => {
      await assertSucceeds(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/e1`), { ...valid.temperature, method }),
      );
    });
  }

  for (const [kind, field] of [
    ['temperature', 'tempC'], ['symptoms', 'symptoms'],
    ['medicine', 'medicine'], ['note', 'note'],
  ]) {
    it(`denies a ${kind} entry without ${field}`, async () => {
      await assertFails(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/e1`), without(valid[kind], field)),
      );
    });
  }

  for (const field of ['kind', 'at']) {
    it(`denies an entry without ${field}`, async () => {
      await assertFails(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/e1`), without(valid.note, field)),
      );
    });
  }

  for (const [base, field, bad] of [
    ['note', 'kind', 'diaper'],
    ['note', 'at', '2027-03-10'],
    ['temperature', 'tempC', 31.9], ['temperature', 'tempC', 44.1],
    ['temperature', 'tempC', '38'],
    ['temperature', 'method', 'forehead'],
    ['symptoms', 'symptoms', []], ['symptoms', 'symptoms', ['sneezing']],
    ['symptoms', 'symptoms', 'feelsHot'],
    ['medicine', 'medicine', ''], ['medicine', 'medicine', 'x'.repeat(81)],
    ['medicine', 'amount', 'x'.repeat(41)],
    ['note', 'note', ''], ['note', 'note', 'x'.repeat(501)],
    ['note', 'doseId', 'x'.repeat(129)],
  ]) {
    it(`denies ${base}.${field} = ${JSON.stringify(bad).slice(0, 20)}`, async () => {
      await assertFails(
        setDoc(doc(asUser(ALICE), `${path(ALICE)}/e1`), { ...valid[base], [field]: bad }),
      );
    });
  }

  it('denies unknown fields', async () => {
    await assertFails(
      setDoc(doc(asUser(ALICE), `${path(ALICE)}/e1`), { ...valid.note, dose: '5 ml' }),
    );
  });

  it("denies reading or writing another user's log", async () => {
    await seed((db) => setDoc(doc(db, `${path(ALICE)}/e1`), valid.note));
    await assertFails(getDoc(doc(asUser(BOB), `${path(ALICE)}/e1`)));
    await assertFails(getDocs(collection(asUser(BOB), path(ALICE))));
    await assertFails(setDoc(doc(asUser(BOB), `${path(ALICE)}/e2`), valid.note));
    await assertFails(deleteDoc(doc(asUser(BOB), `${path(ALICE)}/e1`)));
  });

  it('denies a signed-out client', async () => {
    await assertFails(setDoc(doc(asAnon(), `${path(ALICE)}/e1`), valid.note));
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
