import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, setDoc, updateDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-item-rules-test';
const OWNER_ID = 'item-owner';
const NEIGHBOR_ID = 'item-neighbor';
const ITEM_ID = 'item-1';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

const baseItem = {
  ownerId: OWNER_ID,
  ownerName: 'Item Owner',
  ownerEmail: 'owner@example.com',
  ownerPhotoUrl: '',
  ownerVerified: true,
  ownerReputationScore: 4.5,
  title: 'Drill',
  description: 'Cordless drill',
  category: 'tools',
  condition: 'good',
  imageUrls: ['https://example.com/drill.jpg'],
  lendingType: 'free',
  hasUsageFee: false,
  hasDeposit: false,
  status: 'available',
  communityId: 'community-1',
  communityName: 'Palm Grove',
  pickupInstructions: 'Lobby pickup',
  isArchived: false,
  createdAt: new Date(),
  updatedAt: new Date(),
};

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', OWNER_ID), {
      uid: OWNER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'users', NEIGHBOR_ID), {
      uid: NEIGHBOR_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'items', ITEM_ID), baseItem);
    await setDoc(doc(db, 'items', 'item-locked'), {
      ...baseItem,
      status: 'unavailable',
    });
    await setDoc(doc(db, 'items', 'item-archive'), {
      ...baseItem,
      title: 'Ladder',
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('item owner updates', () => {
  test('owner can update listing details on an available item', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'items', ITEM_ID), {
        title: 'Updated drill',
        description: 'Updated description',
        category: 'tools',
        condition: 'used',
        lendingType: 'free',
        hasUsageFee: false,
        hasDeposit: false,
        pickupInstructions: 'Side gate',
        imageUrls: ['https://example.com/drill.jpg'],
        updatedAt: new Date(),
      }),
    );
  });

  test('owner cannot change pricing while item is unavailable', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'items', 'item-locked'), {
        hasUsageFee: true,
        feeAmount: 25,
        lendingType: 'smallFee',
        updatedAt: new Date(),
      }),
    );
  });

  test('owner cannot change community on an available item', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'items', ITEM_ID), {
        communityId: 'community-2',
        communityName: 'Other Place',
        updatedAt: new Date(),
      }),
    );
  });

  test('owner can mark an available item unavailable for borrow approval', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'items', ITEM_ID), {
        status: 'unavailable',
        updatedAt: new Date(),
      }),
    );
  });

  test('owner can archive an available item', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'items', 'item-archive'), {
        isArchived: true,
        status: 'archived',
        updatedAt: new Date(),
      }),
    );
  });
});

describe('item delete and neighbor access', () => {
  test('owner cannot delete their item', async () => {
    const db = testEnv.authenticatedContext(OWNER_ID).firestore();
    await assertFails(deleteDoc(doc(db, 'items', ITEM_ID)));
  });

  test('neighbor cannot update another residents item', async () => {
    const db = testEnv.authenticatedContext(NEIGHBOR_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'items', ITEM_ID), {
        title: 'Hijacked',
        updatedAt: new Date(),
      }),
    );
  });
});
