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

const PROJECT_ID = 'jirani-service-media-storage-rules-test';
const PROVIDER_ID = 'provider-user';
const OTHER_ID = 'other-user';
const SERVICE_ID = 'service-1';

const jpegBytes = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
const pdfBytes = new Uint8Array([0x25, 0x50, 0x44, 0x46]);

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

describe('service_media storage', () => {
  test('provider can upload a valid service job photo', async () => {
    const storage = testEnv.authenticatedContext(PROVIDER_ID).storage();
    await assertSucceeds(
      uploadBytes(
        ref(
          storage,
          `service_media/${PROVIDER_ID}/${SERVICE_ID}/job_photos/photo.jpg`,
        ),
        jpegBytes,
        { contentType: 'image/jpeg' },
      ),
    );
  });

  test('provider can upload a valid service certificate PDF', async () => {
    const storage = testEnv.authenticatedContext(PROVIDER_ID).storage();
    await assertSucceeds(
      uploadBytes(
        ref(
          storage,
          `service_media/${PROVIDER_ID}/${SERVICE_ID}/certificates/cert.pdf`,
        ),
        pdfBytes,
        { contentType: 'application/pdf' },
      ),
    );
  });

  test('other user cannot upload into provider service media folder', async () => {
    const storage = testEnv.authenticatedContext(OTHER_ID).storage();
    await assertFails(
      uploadBytes(
        ref(
          storage,
          `service_media/${PROVIDER_ID}/${SERVICE_ID}/job_photos/photo.jpg`,
        ),
        jpegBytes,
        { contentType: 'image/jpeg' },
      ),
    );
  });

  test('provider cannot upload unsupported service media content type', async () => {
    const storage = testEnv.authenticatedContext(PROVIDER_ID).storage();
    await assertFails(
      uploadBytes(
        ref(
          storage,
          `service_media/${PROVIDER_ID}/${SERVICE_ID}/certificates/bad.exe`,
        ),
        new Uint8Array([1, 2, 3]),
        { contentType: 'application/octet-stream' },
      ),
    );
  });
});
