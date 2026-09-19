import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let testEnv;

const passwordUser = (uid) =>
  testEnv.authenticatedContext(uid, {
    email: `${uid}@example.com`,
    firebase: { sign_in_provider: 'password' },
  });

const anonymousUser = (uid) =>
  testEnv.authenticatedContext(uid, {
    firebase: { sign_in_provider: 'anonymous' },
  });

const validProfile = (email = 'owner@example.com') => ({
  email,
  authProvider: 'password',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  onboardingCompleted: false,
  resumeStep: 1,
});

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-resq-rules',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

beforeEach(async () => testEnv.clearFirestore());
after(async () => testEnv.cleanup());

test('registered user can create and read only their own profile', async () => {
  const uid = 'owner';
  const db = passwordUser(uid).firestore();
  const ownProfile = doc(db, 'users', uid);
  await assertSucceeds(setDoc(ownProfile, validProfile()));
  await assertSucceeds(getDoc(ownProfile));
  await assertFails(getDoc(doc(db, 'users', 'someone-else')));
});

test('signed-out and anonymous users cannot access profiles', async () => {
  await assertFails(
    setDoc(
      doc(testEnv.unauthenticatedContext().firestore(), 'users', 'guest'),
      validProfile(),
    ),
  );
  await assertFails(
    setDoc(
      doc(anonymousUser('guest').firestore(), 'users', 'guest'),
      validProfile(),
    ),
  );
});

test('profile collection cannot be enumerated', async () => {
  const db = passwordUser('owner').firestore();
  await assertFails(getDocs(collection(db, 'users')));
});

test('unknown fields and invalid resume steps are rejected', async () => {
  const db = passwordUser('owner').firestore();
  await assertFails(
    setDoc(doc(db, 'users', 'owner'), {
      ...validProfile(),
      admin: true,
    }),
  );
  await assertFails(
    setDoc(doc(db, 'users', 'owner'), {
      ...validProfile(),
      resumeStep: 9,
    }),
  );
});

test('createdAt is immutable but onboarding fields may be updated', async () => {
  const db = passwordUser('owner').firestore();
  const profile = doc(db, 'users', 'owner');
  await assertSucceeds(setDoc(profile, validProfile()));
  await assertSucceeds(
    updateDoc(profile, {
      resumeStep: 2,
      personalInfo: { fullName: 'Owner' },
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(updateDoc(profile, { createdAt: serverTimestamp() }));
});

test('undeclared future collections are denied by default', async () => {
  const db = passwordUser('owner').firestore();
  await assertFails(setDoc(doc(db, 'sosEvents', 'event-1'), { ownerId: 'owner' }));
});
