// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_settings_rules.test.mjs (JavaScript module file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,10-July-2026
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
import { doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-admin-settings-rules-test';
const ADMIN_ID = 'community-admin';
const OTHER_ADMIN_ID = 'other-admin';
const LEGACY_ADMIN_ID = 'legacy-admin';

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

    await setDoc(doc(db, 'admins', LEGACY_ADMIN_ID), {
      uid: LEGACY_ADMIN_ID,
      fullName: 'Legacy Admin',
      email: 'legacy-admin@example.com',
      phoneNumber: '',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      status: 'active',
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

  test('admin can save settings payload used by the Flutter app', async () => {
    const db = testEnv.authenticatedContext(ADMIN_ID).firestore();

    await assertSucceeds(
      updateDoc(doc(db, 'admins', ADMIN_ID), {
        fullName: 'Updated Admin',
        phoneNumber: '+60123456789',
        notificationPreferences: {
          verificationAlerts: true,
          reportEscalations: true,
          serviceDisputeAlerts: false,
          weeklyDigest: false,
        },
        themePresetId: 'darkPurple',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('legacy admin without role field can update own settings', async () => {
    const db = testEnv.authenticatedContext(LEGACY_ADMIN_ID).firestore();

    await assertSucceeds(
      updateDoc(doc(db, 'admins', LEGACY_ADMIN_ID), {
        fullName: 'Legacy Admin Updated',
        phoneNumber: '',
        notificationPreferences: {
          verificationAlerts: true,
          reportEscalations: true,
          serviceDisputeAlerts: true,
          weeklyDigest: false,
        },
        themePresetId: 'teal',
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
