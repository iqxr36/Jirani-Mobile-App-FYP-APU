// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : user_privacy_rules.test.mjs (JavaScript module file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-user-privacy-rules-test';
const OWNER_ID = 'owner-user';
const NEIGHBOR_ID = 'neighbor-user';
const OTHER_COMMUNITY_ID = 'other-community-user';
const COMMUNITY_ADMIN_ID = 'community-admin';
const SUSPENDED_ID = 'suspended-resident';
const INDEFINITE_SUSPENSION_ID = 'indefinite-suspension-resident';
const EXPIRED_SUSPENSION_ID = 'expired-suspension-resident';

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
    await setDoc(doc(db, 'users', SUSPENDED_ID), {
      uid: SUSPENDED_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      accountStatus: 'suspended',
      suspensionEndsAt: new Date('2035-01-01T00:00:00.000Z'),
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'users', EXPIRED_SUSPENSION_ID), {
      uid: EXPIRED_SUSPENSION_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      accountStatus: 'suspended',
      suspensionEndsAt: new Date('2020-01-01T00:00:00.000Z'),
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'users', INDEFINITE_SUSPENSION_ID), {
      uid: INDEFINITE_SUSPENSION_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      accountStatus: 'suspended',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'admins', COMMUNITY_ADMIN_ID), {
      uid: COMMUNITY_ADMIN_ID,
      role: 'communityAdmin',
      communityId: 'community-1',
      isActive: true,
    });
    await setDoc(doc(db, 'borrowRequests', 'private-borrow-request'), {
      ownerId: OWNER_ID,
      borrowerId: NEIGHBOR_ID,
      communityId: 'community-1',
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

  test('resident cannot create a profile without server registration', async () => {
    const db = testEnv.authenticatedContext('new-resident').firestore();
    await assertFails(setDoc(doc(db, 'users', 'new-resident'), {
      uid: 'new-resident',
      role: 'resident',
      verificationStatus: 'pending',
    }));
  });

  test('resident cannot write phoneNumber directly to own profile', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'users', OWNER_ID), {
        phoneNumber: '+60999999999',
        updatedAt: new Date(),
      }),
    );
  });

  test('community admin can read a private user in their community', async () => {
    const db = testEnv.authenticatedContext(COMMUNITY_ADMIN_ID).firestore();
    await assertSucceeds(getDoc(doc(db, 'users', OWNER_ID)));
  });

  test('community admin cannot read a private user in another community', async () => {
    const db = testEnv.authenticatedContext(COMMUNITY_ADMIN_ID).firestore();
    await assertFails(getDoc(doc(db, 'users', OTHER_COMMUNITY_ID)));
  });

  test('unrelated resident cannot read a borrow request', async () => {
    const db = testEnv.authenticatedContext(OTHER_COMMUNITY_ID).firestore();
    await assertFails(
      getDoc(doc(db, 'borrowRequests', 'private-borrow-request')),
    );
  });

  test('unknown collection writes are denied by default', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertFails(setDoc(doc(db, 'unknownCollection', 'record-1'), {
      value: true,
    }));
  });
});

describe('suspension restriction privacy', () => {
  test('resident with an active timed suspension cannot access community profiles', async () => {
    const db = testEnv.authenticatedContext(SUSPENDED_ID).firestore();
    await assertFails(getDoc(doc(db, 'publicProfiles', OWNER_ID)));
  });

  test('resident can access community profiles after a timed suspension expires', async () => {
    const db = testEnv.authenticatedContext(EXPIRED_SUSPENSION_ID).firestore();
    await assertSucceeds(getDoc(doc(db, 'publicProfiles', OWNER_ID)));
  });

  test('resident with an indefinite suspension remains blocked', async () => {
    const db = testEnv.authenticatedContext(INDEFINITE_SUSPENSION_ID).firestore();
    await assertFails(getDoc(doc(db, 'publicProfiles', OWNER_ID)));
  });

  test('resident cannot read or write server-only email restrictions', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    const ref = doc(db, 'residentEmailRestrictions', 'email-hash');
    await assertFails(getDoc(ref));
    await assertFails(setDoc(ref, { blocked: true }));
  });

  test('resident cannot read or write server-only phone registry', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    const ref = doc(db, 'residentPhoneNumbers', 'phone-hash');
    await assertFails(getDoc(ref));
    await assertFails(setDoc(ref, { uid: OWNER_ID, normalizedPhone: '+60123456789' }));
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
