// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : report_create_rules.test.mjs (JavaScript module file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,16-July-2026
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
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-report-create-rules-test';
const REPORTER_ID = 'reporter-user';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', REPORTER_ID), {
      uid: REPORTER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      firstName: 'Report',
      lastName: 'User',
      updatedAt: new Date(),
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

function validReport(overrides = {}) {
  return {
    reporterId: REPORTER_ID,
    communityId: 'community-1',
    communityName: 'Palm Grove',
    type: 'userMisconduct',
    status: 'open',
    title: 'Inappropriate behavior',
    description: 'Resident was abusive in chat.',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

describe('report create rules', () => {
  test('verified resident can create a valid report', async () => {
    const db = testEnv.authenticatedContext(REPORTER_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'reports', 'report-valid'), validReport()),
    );
  });

  test('rejects report with invalid type', async () => {
    const db = testEnv.authenticatedContext(REPORTER_ID).firestore();
    await assertFails(
      setDoc(
        doc(db, 'reports', 'report-invalid-type'),
        validReport({ type: 'notARealType' }),
      ),
    );
  });

  test('rejects report with oversized title', async () => {
    const db = testEnv.authenticatedContext(REPORTER_ID).firestore();
    await assertFails(
      setDoc(
        doc(db, 'reports', 'report-long-title'),
        validReport({ title: 'x'.repeat(201) }),
      ),
    );
  });

  test('rejects report when reporterId does not match auth uid', async () => {
    const db = testEnv.authenticatedContext(REPORTER_ID).firestore();
    await assertFails(
      setDoc(
        doc(db, 'reports', 'report-wrong-reporter'),
        validReport({ reporterId: 'someone-else' }),
      ),
    );
  });
});
