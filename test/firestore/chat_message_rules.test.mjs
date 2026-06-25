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

const PROJECT_ID = 'jirani-chat-rules-test';
const CHAT_ID = 'user-a_user-b';
const MESSAGE_ID = 'message-1';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'chats', CHAT_ID), {
      participantIds: ['user-a', 'user-b'],
      participantLookup: { 'user-a': true, 'user-b': true },
      communityId: 'community-1',
      connectionId: CHAT_ID,
      participantNames: { 'user-a': 'A', 'user-b': 'B' },
      participantImageUrls: { 'user-a': '', 'user-b': '' },
      lastMessageText: 'hello',
      lastMessageType: 'text',
      lastSenderId: 'user-a',
      unreadCounts: { 'user-a': 0, 'user-b': 1 },
      deletedFor: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'chats', CHAT_ID, 'messages', MESSAGE_ID), {
      chatId: CHAT_ID,
      senderId: 'user-a',
      type: 'text',
      text: 'hello',
      readBy: ['user-a'],
      deletedFor: [],
      createdAt: new Date(),
    });
    await setDoc(doc(db, 'chats', CHAT_ID, 'messages', 'legacy-msg'), {
      chatId: CHAT_ID,
      senderId: 'user-a',
      type: 'text',
      text: 'legacy',
      readBy: ['user-a'],
      createdAt: new Date(),
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('chat message updates', () => {
  test('participant can mark message read', async () => {
    const db = testEnv.authenticatedContext('user-b').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'chats', CHAT_ID, 'messages', MESSAGE_ID), {
        readBy: ['user-a', 'user-b'],
      }),
    );
  });

  test('participant can delete message for self', async () => {
    const db = testEnv.authenticatedContext('user-b').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'chats', CHAT_ID, 'messages', MESSAGE_ID), {
        deletedFor: ['user-b'],
      }),
    );
  });

  test('participant can delete legacy message missing deletedFor field', async () => {
    const db = testEnv.authenticatedContext('user-b').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'chats', CHAT_ID, 'messages', 'legacy-msg'), {
        deletedFor: ['user-b'],
      }),
    );
  });

  test('non-participant cannot delete message for self', async () => {
    const db = testEnv.authenticatedContext('user-c').firestore();
    await assertFails(
      updateDoc(doc(db, 'chats', CHAT_ID, 'messages', MESSAGE_ID), {
        deletedFor: ['user-c'],
      }),
    );
  });

  test('participant cannot add another user to deletedFor', async () => {
    const db = testEnv.authenticatedContext('user-b').firestore();
    await assertFails(
      updateDoc(doc(db, 'chats', CHAT_ID, 'messages', MESSAGE_ID), {
        deletedFor: ['user-a'],
      }),
    );
  });

  test('participant cannot change message text', async () => {
    const db = testEnv.authenticatedContext('user-b').firestore();
    await assertFails(
      updateDoc(doc(db, 'chats', CHAT_ID, 'messages', MESSAGE_ID), {
        text: 'hacked',
      }),
    );
  });
});
