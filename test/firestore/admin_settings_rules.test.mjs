import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-admin-settings-rules-test';
const ADMIN_ID = 'community-admin';
const OTHER_ADMIN_ID = 'other-admin';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'admins', ADMIN_ID), {
      uid: ADMIN_ID,
      fullName: 'Community Admin',
      email: 'admin@example.com',
      phoneNumber: '',
      role: 'communityAdmin',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await setDoc(doc(db, 'admins', OTHER_ADMIN_ID), {
      uid: OTHER_ADMIN_ID,
      fullName: 'Other Admin',
      email: 'other-admin@example.com',
      phoneNumber: '',
      role: 'communityAdmin',
      communityId: 'community-2',
      communityName: 'Other Place',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('admin settings self-updates', () => {
  test('admin can update own profile settings on a minimal admin document', async () => {
    const db = testEnv.authenticatedContext(ADMIN_ID).firestore();

    await assertSucceeds(
      updateDoc(doc(db, 'admins', ADMIN_ID), {
        fullName: 'Updated Admin',
        phoneNumber: '+60123456789',
        notificationPreferences: {
          verificationAlerts: true,
          reportEscalations: false,
          serviceDisputeAlerts: true,
          weeklyDigest: false,
        },
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('admin cannot change own authorization fields through settings', async () => {
    const db = testEnv.authenticatedContext(ADMIN_ID).firestore();

    await assertFails(
      updateDoc(doc(db, 'admins', ADMIN_ID), {
        role: 'systemAdmin',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('admin cannot update another admin settings document', async () => {
    const db = testEnv.authenticatedContext(ADMIN_ID).firestore();

    await assertFails(
      updateDoc(doc(db, 'admins', OTHER_ADMIN_ID), {
        fullName: 'Nope',
        updatedAt: serverTimestamp(),
      }),
    );
  });
});
