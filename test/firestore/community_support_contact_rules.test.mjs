// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : community_support_contact_rules.test.mjs (JavaScript module file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,18-July-2026
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
import { doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');
const PROJECT_ID = 'jirani-community-support-contact-rules';
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', 'resident-1'), {
      role: 'resident',
      communityId: 'community-1',
    });
    await setDoc(doc(db, 'users', 'resident-2'), {
      role: 'resident',
      communityId: 'community-2',
    });
    await setDoc(doc(db, 'admins', 'admin-1'), {
      role: 'communityAdmin',
      communityId: 'community-1',
      isActive: true,
    });
    await setDoc(doc(db, 'admins', 'admin-2'), {
      role: 'communityAdmin',
      communityId: 'community-2',
      isActive: true,
    });
    await setDoc(doc(db, 'admins', 'system-admin'), {
      role: 'systemAdmin',
      communityId: '',
      isActive: true,
    });
    await setDoc(doc(db, 'communitySupportContacts', 'community-1'), {
      communityId: 'community-1',
      contactName: 'Amina Rahman',
      email: 'support@example.com',
      phoneNumber: '+60123456789',
      updatedBy: 'admin-1',
      updatedAt: new Date(),
    });
  });
});

after(async () => testEnv.cleanup());

function payload(communityId, uid) {
  return {
    communityId,
    contactName: 'Community Support',
    email: 'support@example.com',
    phoneNumber: '+60123456789',
    updatedBy: uid,
    updatedAt: serverTimestamp(),
  };
}

describe('community support contacts', () => {
  test('same-community resident can read but cannot write', async () => {
    const db = testEnv.authenticatedContext('resident-1').firestore();
    await assertSucceeds(
      getDoc(doc(db, 'communitySupportContacts', 'community-1')),
    );
    await assertFails(
      setDoc(
        doc(db, 'communitySupportContacts', 'community-1'),
        payload('community-1', 'resident-1'),
      ),
    );
  });

  test('cross-community and unauthenticated reads are denied', async () => {
    const otherDb = testEnv.authenticatedContext('resident-2').firestore();
    const publicDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      getDoc(doc(otherDb, 'communitySupportContacts', 'community-1')),
    );
    await assertFails(
      getDoc(doc(publicDb, 'communitySupportContacts', 'community-1')),
    );
  });

  test('community admin can write only the assigned community', async () => {
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(
      setDoc(
        doc(db, 'communitySupportContacts', 'community-1'),
        payload('community-1', 'admin-1'),
      ),
    );
    await assertFails(
      setDoc(
        doc(db, 'communitySupportContacts', 'community-2'),
        payload('community-2', 'admin-1'),
      ),
    );
  });

  test('system admin can read and write any community contact', async () => {
    const db = testEnv.authenticatedContext('system-admin').firestore();
    await assertSucceeds(
      getDoc(doc(db, 'communitySupportContacts', 'community-1')),
    );
    await assertSucceeds(
      setDoc(
        doc(db, 'communitySupportContacts', 'community-2'),
        payload('community-2', 'system-admin'),
      ),
    );
  });
});
