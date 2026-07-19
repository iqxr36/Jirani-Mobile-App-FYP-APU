// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : notification_create_rules.test.mjs (JavaScript module file)
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
import {
  addDoc,
  collection,
  doc,
  getDoc,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-notification-create-rules-test';
const SENDER_ID = 'sender-user';
const RECIPIENT_ID = 'recipient-user';

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
    await setDoc(doc(db, 'users', SENDER_ID), {
      uid: SENDER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      updatedAt: now,
    });
    await setDoc(doc(db, 'users', RECIPIENT_ID), {
      uid: RECIPIENT_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      updatedAt: now,
    });
    await setDoc(doc(db, 'notifications', 'notification-1'), {
      userId: RECIPIENT_ID,
      actorId: SENDER_ID,
      type: 'chatMessage',
      title: 'Hello',
      body: 'Test message',
      read: false,
      createdAt: now,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('notification create rules', () => {
  test('resident cannot create in-app notifications directly', async () => {
    const db = testEnv.authenticatedContext(SENDER_ID).firestore();
    await assertFails(
      addDoc(collection(db, 'notifications'), {
        userId: RECIPIENT_ID,
        actorId: SENDER_ID,
        type: 'chatMessage',
        title: 'Hello',
        body: 'Test message',
        read: false,
        createdAt: Timestamp.now(),
      }),
    );
  });

  test('notification owner can mark it as read', async () => {
    const db = testEnv.authenticatedContext(RECIPIENT_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'notifications', 'notification-1'), { read: true }),
    );
  });

  test("resident cannot read another user's notification", async () => {
    const db = testEnv.authenticatedContext(SENDER_ID).firestore();
    await assertFails(getDoc(doc(db, 'notifications', 'notification-1')));
  });
});
