// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : item_image_storage_rules.test.mjs (JavaScript module file)
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
import { ref, uploadBytes } from 'firebase/storage';

const __dirname = dirname(fileURLToPath(import.meta.url));
const firestoreRules = readFileSync(
  resolve(__dirname, '../../firestore.rules'),
  'utf8',
);
const storageRules = readFileSync(
  resolve(__dirname, '../../storage.rules'),
  'utf8',
);

const PROJECT_ID = 'jirani-item-image-storage-rules-test';
const OWNER_ID = 'owner-user';
const OTHER_ID = 'other-user';
const ITEM_ID = 'item-1';

const jpegBytes = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: firestoreRules },
    storage: { rules: storageRules },
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('item_images storage', () => {
  test('owner can upload a valid item image', async () => {
    const storage = testEnv.authenticatedContext(OWNER_ID).storage();
    await assertSucceeds(
      uploadBytes(
        ref(storage, `item_images/${OWNER_ID}/${ITEM_ID}/photo.jpg`),
        jpegBytes,
        { contentType: 'image/jpeg' },
      ),
    );
  });

  test('other user cannot upload into owner item folder', async () => {
    const storage = testEnv.authenticatedContext(OTHER_ID).storage();
    await assertFails(
      uploadBytes(
        ref(storage, `item_images/${OWNER_ID}/${ITEM_ID}/photo.jpg`),
        jpegBytes,
        { contentType: 'image/jpeg' },
      ),
    );
  });

  test('owner cannot upload disallowed content type', async () => {
    const storage = testEnv.authenticatedContext(OWNER_ID).storage();
    await assertFails(
      uploadBytes(
        ref(storage, `item_images/${OWNER_ID}/${ITEM_ID}/bad.exe`),
        new Uint8Array([1, 2, 3]),
        { contentType: 'application/octet-stream' },
      ),
    );
  });
});
