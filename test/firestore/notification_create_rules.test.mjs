import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  doc,
  setDoc,
  Timestamp,
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
});
