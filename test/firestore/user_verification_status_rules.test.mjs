import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp, updateDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-verification-status-rules-test';
const VERIFIED_USER_ID = 'verified-user';
const SUBMITTED_USER_ID = 'submitted-user';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const now = Timestamp.now();

    await setDoc(doc(db, 'users', VERIFIED_USER_ID), {
      uid: VERIFIED_USER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      firstName: 'Verified',
      lastName: 'Resident',
      updatedAt: now,
    });
    await setDoc(doc(db, 'users', SUBMITTED_USER_ID), {
      uid: SUBMITTED_USER_ID,
      role: 'resident',
      verificationStatus: 'submitted',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      firstName: 'Submitted',
      lastName: 'Resident',
      updatedAt: now,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('verificationStatus client writes', () => {
  test('verified resident cannot reset verificationStatus to pending', async () => {
    const db = testEnv.authenticatedContext(VERIFIED_USER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'users', VERIFIED_USER_ID), {
        verificationStatus: 'pending',
        updatedAt: Timestamp.now(),
      }),
    );
  });

  test('verified resident cannot set verificationStatus to submitted', async () => {
    const db = testEnv.authenticatedContext(VERIFIED_USER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'users', VERIFIED_USER_ID), {
        verificationStatus: 'submitted',
        updatedAt: Timestamp.now(),
      }),
    );
  });

  test('submitted resident cannot set verificationStatus directly', async () => {
    const db = testEnv.authenticatedContext(SUBMITTED_USER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'users', SUBMITTED_USER_ID), {
        verificationStatus: 'pending',
        updatedAt: Timestamp.now(),
      }),
    );
  });

  test('verified resident can change community with verification reset bundle', async () => {
    const db = testEnv.authenticatedContext(VERIFIED_USER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'users', VERIFIED_USER_ID), {
        communityId: 'community-2',
        communityName: 'Other Place',
        verificationStatus: 'pending',
        locationVerified: false,
        locationVerificationStatus: 'pending',
        locationVerifiedCommunityName: '',
        updatedAt: Timestamp.now(),
      }),
    );
  });
});
