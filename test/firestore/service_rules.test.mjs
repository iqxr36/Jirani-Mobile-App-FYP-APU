// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : service_rules.test.mjs (JavaScript module file)
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
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-service-rules-test';
const PROVIDER_ID = 'service-provider';
const NEIGHBOR_ID = 'service-neighbor';
const OUTSIDER_ID = 'service-outsider';
const SERVICE_ID = 'service-1';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

const baseService = {
  id: SERVICE_ID,
  providerId: PROVIDER_ID,
  providerName: 'Service Provider',
  providerEmail: 'provider@example.com',
  providerPhotoUrl: '',
  title: 'House cleaning',
  description: 'Weekly cleaning help',
  category: 'homeCleaningUpkeep',
  priceType: 'fixed',
  priceAmount: 50,
  pricingMode: 'fixedJob',
  hourlyRate: null,
  fixedJobPrice: 50,
  imageUrls: ['https://example.com/service.jpg'],
  certificateUrls: [],
  certificateNames: [],
  availability: 'Weekends',
  availableWeekdays: [6, 7],
  availabilityStartMinutes: 9 * 60,
  availabilityEndMinutes: 17 * 60,
  status: 'active',
  communityId: 'community-1',
  communityName: 'Palm Grove',
  createdAt: new Date(),
  updatedAt: new Date(),
};

function serviceForCreate(id, overrides = {}) {
  return {
    ...baseService,
    id,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', PROVIDER_ID), {
      uid: PROVIDER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'users', NEIGHBOR_ID), {
      uid: NEIGHBOR_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-1',
      communityName: 'Palm Grove',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'users', OUTSIDER_ID), {
      uid: OUTSIDER_ID,
      role: 'resident',
      verificationStatus: 'verified',
      communityId: 'community-2',
      communityName: 'Other Place',
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'services', SERVICE_ID), baseService);
    await setDoc(doc(db, 'services', 'service-inactive'), {
      ...baseService,
      id: 'service-inactive',
      title: 'Tutoring',
      status: 'inactive',
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('service provider updates', () => {
  test('provider can list their own services', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      getDocs(
        query(collection(db, 'services'), where('providerId', '==', PROVIDER_ID)),
      ),
    );
  });

  test('provider can update listing details on an active service', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        title: 'Deep cleaning',
        description: 'Updated description',
        category: 'homeCleaningUpkeep',
        priceType: 'fixed',
        priceAmount: 60,
        pricingMode: 'fixedJob',
        hourlyRate: null,
        fixedJobPrice: 60,
        availability: 'Sat, Sun, 9:00 AM - 5:00 PM',
        availableWeekdays: [6, 7],
        availabilityStartMinutes: 9 * 60,
        availabilityEndMinutes: 17 * 60,
        updatedAt: new Date(),
      }),
    );
  });

  test('provider can use the exact service text length limits', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        title: 't'.repeat(200),
        description: 'd'.repeat(1000),
        availability: 'a'.repeat(1000),
        updatedAt: new Date(),
      }),
    );
  });

  test('provider cannot exceed the service title limit', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        title: 't'.repeat(201),
        updatedAt: new Date(),
      }),
    );
  });

  test('provider cannot exceed the service description limit', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        description: 'd'.repeat(1001),
        updatedAt: new Date(),
      }),
    );
  });

  test('provider cannot exceed the service availability limit', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        availability: 'a'.repeat(1001),
        updatedAt: new Date(),
      }),
    );
  });

  test('provider cannot shorten a service name below 3 characters', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        title: 'ab',
        updatedAt: new Date(),
      }),
    );
  });

  test('provider cannot shorten a service description below 12 characters', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        description: 'd'.repeat(11),
        updatedAt: new Date(),
      }),
    );
  });

  test('provider cannot change pricing while service is inactive', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'services', 'service-inactive'), {
        priceAmount: 99,
        updatedAt: new Date(),
      }),
    );
  });

  test('provider cannot change provider email on an active service', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        providerEmail: 'hijacked@example.com',
        updatedAt: new Date(),
      }),
    );
  });

  test('provider can change service status without editing listing fields', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        status: 'inactive',
        updatedAt: new Date(),
      }),
    );
  });

  test('provider can archive an active service via status change', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'services', 'service-inactive'), {
        status: 'archived',
        updatedAt: new Date(),
      }),
    );
  });
});

describe('service creation validation', () => {
  test('rejects a 2-character service name', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    const id = 'service-title-too-short';
    await assertFails(
      setDoc(
        doc(db, 'services', id),
        serviceForCreate(id, { title: 'ab' }),
      ),
    );
  });

  test('accepts a 3-character service name', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    const id = 'service-title-boundary';
    await assertSucceeds(
      setDoc(
        doc(db, 'services', id),
        serviceForCreate(id, { title: 'abc' }),
      ),
    );
  });

  test('rejects an 11-character service description', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    const id = 'service-description-too-short';
    await assertFails(
      setDoc(
        doc(db, 'services', id),
        serviceForCreate(id, { description: 'd'.repeat(11) }),
      ),
    );
  });

  test('accepts a 12-character service description', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    const id = 'service-description-boundary';
    await assertSucceeds(
      setDoc(
        doc(db, 'services', id),
        serviceForCreate(id, { description: 'd'.repeat(12) }),
      ),
    );
  });

  test('rejects a zero fixed-job price', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    const id = 'service-zero-price';
    await assertFails(
      setDoc(
        doc(db, 'services', id),
        serviceForCreate(id, { priceAmount: 0, fixedJobPrice: 0 }),
      ),
    );
  });

  test('rejects a negative hourly rate', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    const id = 'service-negative-price';
    await assertFails(
      setDoc(
        doc(db, 'services', id),
        serviceForCreate(id, {
          priceAmount: -1,
          pricingMode: 'hourly',
          hourlyRate: -1,
          fixedJobPrice: null,
        }),
      ),
    );
  });
});

describe('service delete and neighbor access', () => {
  test('provider cannot delete their service', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(deleteDoc(doc(db, 'services', SERVICE_ID)));
  });

  test('neighbor cannot update another residents service', async () => {
    const db = testEnv.authenticatedContext(NEIGHBOR_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'services', SERVICE_ID), {
        title: 'Hijacked service',
        updatedAt: new Date(),
      }),
    );
  });

  test('neighbor in same community can read a service listing', async () => {
    const db = testEnv.authenticatedContext(NEIGHBOR_ID).firestore();
    await assertSucceeds(getDoc(doc(db, 'services', SERVICE_ID)));
  });

  test('neighbor can list public profile active services by provider and community', async () => {
    const db = testEnv.authenticatedContext(NEIGHBOR_ID).firestore();
    await assertSucceeds(
      getDocs(
        query(
          collection(db, 'services'),
          where('providerId', '==', PROVIDER_ID),
          where('communityId', '==', 'community-1'),
          where('status', '==', 'active'),
        ),
      ),
    );
  });

  test('neighbor cannot list public profile services without community constraint', async () => {
    const db = testEnv.authenticatedContext(NEIGHBOR_ID).firestore();
    await assertFails(
      getDocs(
        query(
          collection(db, 'services'),
          where('providerId', '==', PROVIDER_ID),
          where('status', '==', 'active'),
        ),
      ),
    );
  });

  test('resident in another community cannot read service listings', async () => {
    const db = testEnv.authenticatedContext(OUTSIDER_ID).firestore();
    await assertFails(getDoc(doc(db, 'services', SERVICE_ID)));
  });
});
