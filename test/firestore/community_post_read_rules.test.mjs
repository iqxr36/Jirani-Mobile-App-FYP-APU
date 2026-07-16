import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, Timestamp } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-community-post-read-rules-test';
const RESIDENT_ID = 'resident-user';
const OTHER_RESIDENT_ID = 'other-community-resident';
const COMMUNITY_ID = 'community-1';

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
    await setDoc(doc(db, 'users', RESIDENT_ID), {
      uid: RESIDENT_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: COMMUNITY_ID,
      updatedAt: now,
    });
    await setDoc(doc(db, 'users', OTHER_RESIDENT_ID), {
      uid: OTHER_RESIDENT_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-2',
      updatedAt: now,
    });
    await setDoc(doc(db, 'communityPosts', 'published-post'), {
      communityId: COMMUNITY_ID,
      type: 'news',
      title: 'Live update',
      body: 'Visible while published',
      status: 'published',
      authorId: 'admin-1',
      authorName: 'Admin',
      audience: 'All residents',
      createdAt: now,
      updatedAt: now,
      publishedAt: now,
    });
    await setDoc(doc(db, 'communityPosts', 'expired-post'), {
      communityId: COMMUNITY_ID,
      type: 'announcement',
      title: 'Expired update',
      body: 'Still readable from notification deep link',
      status: 'expired',
      authorId: 'admin-1',
      authorName: 'Admin',
      audience: 'All residents',
      createdAt: now,
      updatedAt: now,
      publishedAt: null,
      expiresAt: null,
      expiredAt: now,
    });
    await setDoc(doc(db, 'communityPosts', 'draft-post'), {
      communityId: COMMUNITY_ID,
      type: 'news',
      title: 'Draft update',
      body: 'Not readable by residents',
      status: 'draft',
      authorId: 'admin-1',
      authorName: 'Admin',
      audience: 'All residents',
      createdAt: now,
      updatedAt: now,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('communityPosts resident read rules', () => {
  test('verified resident can read published post in own community', async () => {
    const db = testEnv.authenticatedContext(RESIDENT_ID).firestore();
    await assertSucceeds(getDoc(doc(db, 'communityPosts', 'published-post')));
  });

  test('verified resident can read expired post in own community', async () => {
    const db = testEnv.authenticatedContext(RESIDENT_ID).firestore();
    await assertSucceeds(getDoc(doc(db, 'communityPosts', 'expired-post')));
  });

  test('verified resident cannot read draft post in own community', async () => {
    const db = testEnv.authenticatedContext(RESIDENT_ID).firestore();
    await assertFails(getDoc(doc(db, 'communityPosts', 'draft-post')));
  });

  test('verified resident cannot read expired post from another community', async () => {
    const db = testEnv.authenticatedContext(OTHER_RESIDENT_ID).firestore();
    await assertFails(getDoc(doc(db, 'communityPosts', 'expired-post')));
  });
});
