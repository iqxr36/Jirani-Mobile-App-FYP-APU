import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp, updateDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-review-publish-rules-test';
const BORROW_ID = 'borrow-1';
const BORROWER_ID = 'borrower-user';
const OWNER_ID = 'owner-user';
const ITEM_ID = 'item-1';
const REVIEW_ID = `${BORROW_ID}_${BORROWER_ID}`;

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

    await setDoc(doc(db, 'users', BORROWER_ID), {
      uid: BORROWER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      updatedAt: now,
    });
    await setDoc(doc(db, 'users', OWNER_ID), {
      uid: OWNER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      updatedAt: now,
    });
    await setDoc(doc(db, 'items', ITEM_ID), {
      ownerId: OWNER_ID,
      status: 'available',
      communityId: 'community-1',
      updatedAt: now,
    });
    await setDoc(doc(db, 'borrowRequests', BORROW_ID), {
      id: BORROW_ID,
      itemId: ITEM_ID,
      borrowerId: BORROWER_ID,
      ownerId: OWNER_ID,
      status: 'completed',
      borrowerReviewSubmitted: true,
      ownerReviewSubmitted: true,
      reviewGraceEndsAt: Timestamp.fromMillis(now.toMillis() + 86_400_000),
      updatedAt: now,
    });
    await setDoc(doc(db, 'reviews', REVIEW_ID), {
      borrowRequestId: BORROW_ID,
      itemId: ITEM_ID,
      reviewerId: BORROWER_ID,
      reviewerName: 'Borrower',
      revieweeId: OWNER_ID,
      revieweeName: 'Owner',
      rating: 5,
      comment: 'Great lender',
      role: 'borrowerToOwner',
      visible: false,
      status: 'hidden',
      publishAfter: Timestamp.fromMillis(now.toMillis() + 86_400_000),
      publishedAt: null,
      createdAt: now,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('review publish rules', () => {
  test('participant cannot publish a hidden review directly', async () => {
    const db = testEnv.authenticatedContext(BORROWER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'reviews', REVIEW_ID), {
        visible: true,
        status: 'published',
        publishedAt: Timestamp.now(),
      }),
    );
  });

  test('participant cannot set reviewsPublishedAt on borrow request', async () => {
    const db = testEnv.authenticatedContext(BORROWER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'borrowRequests', BORROW_ID), {
        reviewsPublishedAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      }),
    );
  });
});
