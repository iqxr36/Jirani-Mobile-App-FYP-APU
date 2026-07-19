// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : trust_score_rules.test.mjs (JavaScript module file)
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
import { doc, setDoc, updateDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-trust-rules-test';
const REVIEWEE_ID = 'reviewee-user';
const ATTACKER_ID = 'attacker-user';
const TRIGGER_REVIEW_ID = 'borrow-1_attacker-user';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', REVIEWEE_ID), {
      uid: REVIEWEE_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      reputationScore: 4.0,
      communityTrustScore: 4.0,
      totalReviews: 2,
      trustedResident: false,
      accountFlagged: false,
      trustFlagReason: '',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'users', ATTACKER_ID), {
      uid: ATTACKER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'reviews', TRIGGER_REVIEW_ID), {
      borrowRequestId: 'borrow-1',
      revieweeId: REVIEWEE_ID,
      visible: true,
      status: 'published',
      rating: 5,
      createdAt: new Date(),
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('user trust score updates', () => {
  test('resident cannot write trust fields on another user profile', async () => {
    const db = testEnv.authenticatedContext(ATTACKER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'users', REVIEWEE_ID), {
        reputationScore: 5,
        communityTrustScore: 5,
        totalReviews: 0,
        trustedResident: true,
        accountFlagged: false,
        trustFlagReason: '',
        lastTrustReviewId: TRIGGER_REVIEW_ID,
        trustScoreUpdatedAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('resident cannot write trust fields on their own profile', async () => {
    const db = testEnv.authenticatedContext(REVIEWEE_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'users', REVIEWEE_ID), {
        reputationScore: 5,
        communityTrustScore: 5,
        totalReviews: 99,
        trustedResident: true,
        accountFlagged: false,
        trustFlagReason: '',
        lastTrustReviewId: TRIGGER_REVIEW_ID,
        trustScoreUpdatedAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('resident can still update safe profile fields', async () => {
    const db = testEnv.authenticatedContext(REVIEWEE_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'users', REVIEWEE_ID), {
        firstName: 'Updated',
        updatedAt: new Date(),
      }),
    );
  });
});
