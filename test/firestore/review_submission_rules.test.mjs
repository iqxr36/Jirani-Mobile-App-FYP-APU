// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : review_submission_rules.test.mjs (JavaScript module file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,01-July-2026
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
import {
  doc,
  runTransaction,
  serverTimestamp,
  setDoc,
  Timestamp,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-review-submission-rules-test';
const COMMUNITY_ID = 'community-1';
const BORROW_ID = 'borrow-clean-return';
const XENDIT_BORROW_ID = 'borrow-xendit-return';
const BORROWER_ID = 'borrower-user';
const OWNER_ID = 'owner-user';
const ITEM_ID = 'item-clean';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

async function seedCompletedBorrow({
  borrowId = BORROW_ID,
  xendit = false,
} = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const now = Timestamp.now();

    await setDoc(doc(db, 'users', BORROWER_ID), {
      uid: BORROWER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: COMMUNITY_ID,
      communityName: 'One South Residence',
      updatedAt: now,
    });
    await setDoc(doc(db, 'users', OWNER_ID), {
      uid: OWNER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: COMMUNITY_ID,
      communityName: 'One South Residence',
      updatedAt: now,
    });
    await setDoc(doc(db, 'publicProfiles', BORROWER_ID), {
      uid: BORROWER_ID,
      fullName: 'Borrower User',
      role: 'resident',
      verificationStatus: 'verified',
      communityId: COMMUNITY_ID,
      communityName: 'One South Residence',
      updatedAt: now,
    });
    await setDoc(doc(db, 'publicProfiles', OWNER_ID), {
      uid: OWNER_ID,
      fullName: 'Owner User',
      role: 'resident',
      verificationStatus: 'verified',
      communityId: COMMUNITY_ID,
      communityName: 'One South Residence',
      updatedAt: now,
    });
    await setDoc(doc(db, 'items', ITEM_ID), {
      ownerId: OWNER_ID,
      status: 'available',
      communityId: COMMUNITY_ID,
      updatedAt: now,
    });
    const borrowData = {
      id: borrowId,
      itemId: ITEM_ID,
      borrowerId: BORROWER_ID,
      borrowerName: 'Borrower User',
      ownerId: OWNER_ID,
      ownerName: 'Owner User',
      status: 'completed',
      paymentProvider: xendit ? 'xendit' : 'stripe',
      depositDecision: 'returnDeposit',
      depositStatus: 'refunded',
      completedAt: now,
      returnConfirmedAt: now,
      borrowerReviewSubmitted: false,
      ownerReviewSubmitted: false,
      updatedAt: now,
    };
    if (xendit) {
      Object.assign(borrowData, {
        paymentStatus: 'completed',
        paymentId: 'payment-xendit-1',
        paymentCompletedAt: now,
        depositAmount: 300,
        depositHeldAmount: 300,
        depositRefundAmount: 300,
        depositRefundedAt: now,
        damageDeductionAmount: 0,
        refundStatus: 'succeeded',
        manualPayoutStatus: 'pending_manual',
        lenderBaseEarning: 50,
        lenderDamageEarning: 0,
        lenderTotalEarning: 50,
        xenditInvoiceId: 'inv-test-1',
        xenditReferenceId: 'payment-xendit-1',
        xenditRefundId: 'refund-test-1',
      });
    }
    await setDoc(doc(db, 'borrowRequests', borrowId), borrowData);
  });
}

async function submitReview({
  db,
  borrowId = BORROW_ID,
  reviewerId,
  revieweeId,
  role,
  flagField,
  flagAtField,
}) {
  const reviewRef = doc(db, 'reviews', `${borrowId}_${reviewerId}`);
  const requestRef = doc(db, 'borrowRequests', borrowId);
  const profileRef = doc(db, 'publicProfiles', revieweeId);
  const publishAfter = Timestamp.fromMillis(Date.now() + 3 * 86_400_000);

  await runTransaction(db, async (txn) => {
    await txn.get(requestRef);
    await txn.get(reviewRef);
    await txn.get(profileRef);

    txn.set(reviewRef, {
      borrowRequestId: borrowId,
      itemId: ITEM_ID,
      reviewerId,
      reviewerName: reviewerId === BORROWER_ID ? 'Borrower User' : 'Owner User',
      revieweeId,
      revieweeName: revieweeId === BORROWER_ID ? 'Borrower User' : 'Owner User',
      rating: 5,
      comment: 'Smooth transaction',
      role,
      visible: false,
      status: 'hidden',
      publishAfter,
      publishedAt: null,
      createdAt: serverTimestamp(),
    });
    txn.update(requestRef, {
      [flagField]: true,
      [flagAtField]: serverTimestamp(),
      reviewGraceEndsAt: publishAfter,
      updatedAt: serverTimestamp(),
    });
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('review submission rules', () => {
  test('borrower can submit lender review after clean completed return', async () => {
    await seedCompletedBorrow();
    const db = testEnv.authenticatedContext(BORROWER_ID).firestore();

    await assertSucceeds(
      submitReview({
        db,
        reviewerId: BORROWER_ID,
        revieweeId: OWNER_ID,
        role: 'borrowerToOwner',
        flagField: 'borrowerReviewSubmitted',
        flagAtField: 'borrowerReviewSubmittedAt',
      }),
    );
  });

  test('lender can submit borrower review after clean completed return', async () => {
    await seedCompletedBorrow();
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();

    await assertSucceeds(
      submitReview({
        db,
        reviewerId: OWNER_ID,
        revieweeId: BORROWER_ID,
        role: 'ownerToBorrower',
        flagField: 'ownerReviewSubmitted',
        flagAtField: 'ownerReviewSubmittedAt',
      }),
    );
  });

  test('borrower can submit lender review after completed Xendit return', async () => {
    await seedCompletedBorrow({ borrowId: XENDIT_BORROW_ID, xendit: true });
    const db = testEnv.authenticatedContext(BORROWER_ID).firestore();

    await assertSucceeds(
      submitReview({
        db,
        borrowId: XENDIT_BORROW_ID,
        reviewerId: BORROWER_ID,
        revieweeId: OWNER_ID,
        role: 'borrowerToOwner',
        flagField: 'borrowerReviewSubmitted',
        flagAtField: 'borrowerReviewSubmittedAt',
      }),
    );
  });

  test('lender can submit borrower review after completed Xendit return', async () => {
    await seedCompletedBorrow({ borrowId: `${XENDIT_BORROW_ID}-owner`, xendit: true });
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();

    await assertSucceeds(
      submitReview({
        db,
        borrowId: `${XENDIT_BORROW_ID}-owner`,
        reviewerId: OWNER_ID,
        revieweeId: BORROWER_ID,
        role: 'ownerToBorrower',
        flagField: 'ownerReviewSubmitted',
        flagAtField: 'ownerReviewSubmittedAt',
      }),
    );
  });

  test('non-participant cannot submit a review for the borrow request', async () => {
    await seedCompletedBorrow();
    const db = testEnv.authenticatedContext('outside-user').firestore();

    await assertFails(
      submitReview({
        db,
        reviewerId: 'outside-user',
        revieweeId: OWNER_ID,
        role: 'borrowerToOwner',
        flagField: 'borrowerReviewSubmitted',
        flagAtField: 'borrowerReviewSubmittedAt',
      }),
    );
  });
});
