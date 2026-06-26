import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc, Timestamp, updateDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const PROJECT_ID = 'jirani-service-request-rules-test';
const PROVIDER_ID = 'service-request-provider';
const REQUESTER_ID = 'service-request-requester';
const OUTSIDER_ID = 'service-request-outsider';
const SERVICE_ID = 'service-request-service-1';
const REQUEST_ID = 'service-request-1';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

const baseService = {
  id: SERVICE_ID,
  providerId: PROVIDER_ID,
  providerName: 'Service Provider',
  providerEmail: 'provider@example.com',
  title: 'House cleaning',
  description: 'Weekly cleaning help',
  category: 'cleaning',
  priceType: 'fixed',
  priceAmount: 50,
  availability: 'Weekends',
  status: 'active',
  createdAt: new Date(),
  updatedAt: new Date(),
};

const baseRequest = {
  id: REQUEST_ID,
  serviceId: SERVICE_ID,
  serviceTitle: baseService.title,
  providerId: PROVIDER_ID,
  providerName: baseService.providerName,
  requesterId: REQUESTER_ID,
  requesterName: 'Service Requester',
  message: 'Need help this weekend',
  preferredDate: new Date('2026-06-28T00:00:00.000Z'),
  preferredTime: '10:00',
  status: 'pending',
  createdAt: new Date(),
  updatedAt: new Date(),
};

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
    await setDoc(doc(db, 'users', REQUESTER_ID), {
      uid: REQUESTER_ID,
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
    await setDoc(doc(db, 'serviceRequests', REQUEST_ID), baseRequest);
    await setDoc(doc(db, 'serviceRequests', 'service-request-accepted'), {
      ...baseRequest,
      id: 'service-request-accepted',
      status: 'accepted',
    });
    await setDoc(doc(db, 'serviceRequests', 'service-request-cancel'), {
      ...baseRequest,
      id: 'service-request-cancel',
      status: 'pending',
    });
    await setDoc(doc(db, 'serviceRequests', 'service-request-hijack'), {
      ...baseRequest,
      id: 'service-request-hijack',
      status: 'pending',
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('service request create', () => {
  test('verified resident can create a valid service request', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'serviceRequests', 'service-request-new'), {
        id: 'service-request-new',
        serviceId: SERVICE_ID,
        serviceTitle: baseService.title,
        providerId: PROVIDER_ID,
        providerName: baseService.providerName,
        requesterId: REQUESTER_ID,
        requesterName: 'Service Requester',
        message: 'Another request',
        preferredDate: Timestamp.fromDate(new Date('2026-07-01T00:00:00.000Z')),
        preferredTime: '14:00',
        status: 'pending',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('resident cannot create a request for a service in another community', async () => {
    const db = testEnv.authenticatedContext(OUTSIDER_ID).firestore();
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'service-request-cross-community'), {
        id: 'service-request-cross-community',
        serviceId: SERVICE_ID,
        serviceTitle: baseService.title,
        providerId: PROVIDER_ID,
        providerName: baseService.providerName,
        requesterId: OUTSIDER_ID,
        requesterName: 'Outsider',
        message: 'Cross community request',
        preferredDate: new Date('2026-07-01T00:00:00.000Z'),
        preferredTime: '14:00',
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });
});

describe('service request updates', () => {
  test('provider can accept a pending request', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', REQUEST_ID), {
        status: 'accepted',
        updatedAt: new Date(),
      }),
    );
  });

  test('requester can cancel a pending request', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', 'service-request-cancel'), {
        status: 'cancelled',
        updatedAt: new Date(),
      }),
    );
  });

  test('provider can complete an accepted request', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', 'service-request-accepted'), {
        status: 'completed',
        updatedAt: new Date(),
      }),
    );
  });

  test('provider cannot reassign requesterId', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'serviceRequests', 'service-request-hijack'), {
        requesterId: OUTSIDER_ID,
        updatedAt: new Date(),
      }),
    );
  });

  test('requester cannot force status to completed', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'serviceRequests', 'service-request-hijack'), {
        status: 'completed',
        updatedAt: new Date(),
      }),
    );
  });
});

describe('service request read access', () => {
  test('participant can read their service request', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertSucceeds(getDoc(doc(db, 'serviceRequests', REQUEST_ID)));
  });

  test('outsider cannot read another community service request', async () => {
    const db = testEnv.authenticatedContext(OUTSIDER_ID).firestore();
    await assertFails(getDoc(doc(db, 'serviceRequests', REQUEST_ID)));
  });
});
