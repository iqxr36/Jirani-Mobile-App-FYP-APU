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

const PROJECT_ID = 'jirani-borrow-completion-rules-test';
const OWNER_ID = 'owner-user';
const BORROWER_ID = 'borrower-user';
const ITEM_ID = 'item-1';
const BORROW_ID = 'borrow-1';

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

    await setDoc(doc(db, 'users', OWNER_ID), {
      uid: OWNER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      completedLendings: 2,
      completedBorrowings: 0,
      updatedAt: now,
    });
    await setDoc(doc(db, 'users', BORROWER_ID), {
      uid: BORROWER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      completedBorrowings: 1,
      completedLendings: 0,
      updatedAt: now,
    });
    await setDoc(doc(db, 'items', ITEM_ID), {
      ownerId: OWNER_ID,
      status: 'unavailable',
      communityId: 'community-1',
      updatedAt: now,
    });
    await setDoc(doc(db, 'borrowRequests', BORROW_ID), {
      id: BORROW_ID,
      itemId: ITEM_ID,
      ownerId: OWNER_ID,
      borrowerId: BORROWER_ID,
      status: 'completed',
      completedAt: now,
      returnConfirmedAt: now,
      updatedAt: now,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('borrow completion side effects', () => {
  test('owner cannot increment completedLendings directly', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'users', OWNER_ID), {
        completedLendings: 3,
        lastCompletedBorrowRequestId: BORROW_ID,
        updatedAt: Timestamp.now(),
      }),
    );
  });

  test('borrower cannot increment completedBorrowings directly', async () => {
    const db = testEnv.authenticatedContext(BORROWER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'users', BORROWER_ID), {
        completedBorrowings: 2,
        lastCompletedBorrowRequestId: BORROW_ID,
        updatedAt: Timestamp.now(),
      }),
    );
  });

  test('owner cannot mark item available via completion shortcut', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'items', ITEM_ID), {
        status: 'available',
        lastCompletedBorrowRequestId: BORROW_ID,
        updatedAt: Timestamp.now(),
      }),
    );
  });
});
