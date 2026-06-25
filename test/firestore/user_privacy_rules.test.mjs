import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-user-privacy-rules-test';
const OWNER_ID = 'owner-user';
const NEIGHBOR_ID = 'neighbor-user';
const OTHER_COMMUNITY_ID = 'other-community-user';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const privateUser = {
      uid: OWNER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      firstName: 'Private',
      lastName: 'Owner',
      email: 'owner@example.com',
      phoneNumber: '+60123456789',
      unitNumber: '12A',
      accountFlagged: true,
      trustFlagReason: 'internal-only',
      updatedAt: new Date(),
    };

    await setDoc(doc(db, 'users', OWNER_ID), privateUser);
    await setDoc(doc(db, 'users', NEIGHBOR_ID), {
      uid: NEIGHBOR_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      firstName: 'Neighbor',
      lastName: 'Resident',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'users', OTHER_COMMUNITY_ID), {
      uid: OTHER_COMMUNITY_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-2',
      communityName: 'Other Place',
      firstName: 'Other',
      lastName: 'Community',
      updatedAt: new Date(),
    });

    await setDoc(doc(db, 'publicProfiles', OWNER_ID), {
      uid: OWNER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      firstName: 'Private',
      lastName: 'Owner',
      fullName: 'Private Owner',
      profileImageUrl: '',
      reputationScore: 4.2,
      communityTrustScore: 4.2,
      totalReviews: 3,
      trustedResident: false,
      completedBorrowings: 1,
      completedLendings: 2,
      completedServices: 0,
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'publicProfiles', OTHER_COMMUNITY_ID), {
      uid: OTHER_COMMUNITY_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-2',
      communityName: 'Other Place',
      firstName: 'Other',
      lastName: 'Community',
      fullName: 'Other Community',
      profileImageUrl: '',
      reputationScore: 4,
      communityTrustScore: 4,
      totalReviews: 1,
      trustedResident: false,
      completedBorrowings: 0,
      completedLendings: 0,
      completedServices: 0,
      updatedAt: new Date(),
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('private user profile access', () => {
  test('neighbor cannot read another resident full user document', async () => {
    const db = testEnv.authenticatedContext(NEIGHBOR_ID).firestore();
    await assertFails(getDoc(doc(db, 'users', OWNER_ID)));
  });

  test('resident can read own private user document', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(getDoc(doc(db, 'users', OWNER_ID)));
  });
});

describe('public profile access', () => {
  test('neighbor can read same-community public profile', async () => {
    const db = testEnv.authenticatedContext(NEIGHBOR_ID).firestore();
    const snap = await assertSucceeds(getDoc(doc(db, 'publicProfiles', OWNER_ID)));
    const data = snap.data();
    if (!data?.firstName || data.email) {
      throw new Error('Expected public profile fields without private email');
    }
  });

  test('neighbor cannot read other-community public profile', async () => {
    const db = testEnv.authenticatedContext(NEIGHBOR_ID).firestore();
    await assertFails(getDoc(doc(db, 'publicProfiles', OTHER_COMMUNITY_ID)));
  });
});
