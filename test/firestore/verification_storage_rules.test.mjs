import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';
import { getBytes, ref, uploadBytes } from 'firebase/storage';

const __dirname = dirname(fileURLToPath(import.meta.url));
const firestoreRules = readFileSync(
  resolve(__dirname, '../../firestore.rules'),
  'utf8',
);
const storageRules = readFileSync(
  resolve(__dirname, '../../storage.rules'),
  'utf8',
);

const PROJECT_ID = 'jirani-verification-storage-rules-test';
const OWNER_ID = 'owner-user';
const NEIGHBOR_ID = 'neighbor-user';
const COMMUNITY_ADMIN_ID = 'community-admin';
const OTHER_ADMIN_ID = 'other-community-admin';
const REQUEST_ID = 'verification-request-1';

const pdfBytes = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34]);
const pdfMetadata = { contentType: 'application/pdf' };

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: firestoreRules },
    storage: { rules: storageRules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', OWNER_ID), {
      uid: OWNER_ID,
      role: 'resident',
      communityId: 'community-1',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'users', NEIGHBOR_ID), {
      uid: NEIGHBOR_ID,
      role: 'resident',
      communityId: 'community-1',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'admins', COMMUNITY_ADMIN_ID), {
      uid: COMMUNITY_ADMIN_ID,
      role: 'communityAdmin',
      communityId: 'community-1',
      isActive: true,
    });
    await setDoc(doc(db, 'admins', OTHER_ADMIN_ID), {
      uid: OTHER_ADMIN_ID,
      role: 'communityAdmin',
      communityId: 'community-2',
      isActive: true,
    });
    await setDoc(doc(db, 'verificationRequests', REQUEST_ID), {
      userId: OWNER_ID,
      communityId: 'community-1',
      status: 'submitted',
    });
  });

  const ownerStorage = testEnv.authenticatedContext(OWNER_ID).storage();
  await assertSucceeds(
    uploadBytes(
      ref(ownerStorage, `verification_documents/${OWNER_ID}/id_card.pdf`),
      pdfBytes,
      pdfMetadata,
    ),
  );
  await assertSucceeds(
    uploadBytes(
      ref(
        ownerStorage,
        `resident_documents/${OWNER_ID}/${REQUEST_ID}/tenancy.pdf`,
      ),
      pdfBytes,
      pdfMetadata,
    ),
  );
});

after(async () => {
  await testEnv.cleanup();
});

describe('verification_documents storage', () => {
  test('owner can read own verification document', async () => {
    const storage = testEnv.authenticatedContext(OWNER_ID).storage();
    await assertSucceeds(
      getBytes(ref(storage, `verification_documents/${OWNER_ID}/id_card.pdf`)),
    );
  });

  test('neighbor cannot read another resident verification document', async () => {
    const storage = testEnv.authenticatedContext(NEIGHBOR_ID).storage();
    await assertFails(
      getBytes(ref(storage, `verification_documents/${OWNER_ID}/id_card.pdf`)),
    );
  });

  test('community admin can read verification document in their community', async () => {
    const storage = testEnv.authenticatedContext(COMMUNITY_ADMIN_ID).storage();
    await assertSucceeds(
      getBytes(ref(storage, `verification_documents/${OWNER_ID}/id_card.pdf`)),
    );
  });

  test('community admin cannot read verification document outside their community', async () => {
    const storage = testEnv.authenticatedContext(OTHER_ADMIN_ID).storage();
    await assertFails(
      getBytes(ref(storage, `verification_documents/${OWNER_ID}/id_card.pdf`)),
    );
  });

  test('owner cannot upload disallowed content type', async () => {
    const storage = testEnv.authenticatedContext(OWNER_ID).storage();
    await assertFails(
      uploadBytes(
        ref(storage, `verification_documents/${OWNER_ID}/bad.exe`),
        new Uint8Array([1, 2, 3]),
        { contentType: 'application/octet-stream' },
      ),
    );
  });
});

describe('resident_documents storage', () => {
  test('owner can read own resident document', async () => {
    const storage = testEnv.authenticatedContext(OWNER_ID).storage();
    await assertSucceeds(
      getBytes(
        ref(
          storage,
          `resident_documents/${OWNER_ID}/${REQUEST_ID}/tenancy.pdf`,
        ),
      ),
    );
  });

  test('neighbor cannot read another resident document', async () => {
    const storage = testEnv.authenticatedContext(NEIGHBOR_ID).storage();
    await assertFails(
      getBytes(
        ref(
          storage,
          `resident_documents/${OWNER_ID}/${REQUEST_ID}/tenancy.pdf`,
        ),
      ),
    );
  });

  test('community admin can read resident document for review', async () => {
    const storage = testEnv.authenticatedContext(COMMUNITY_ADMIN_ID).storage();
    await assertSucceeds(
      getBytes(
        ref(
          storage,
          `resident_documents/${OWNER_ID}/${REQUEST_ID}/tenancy.pdf`,
        ),
      ),
    );
  });
});
