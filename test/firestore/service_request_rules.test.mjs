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
const HOURLY_SERVICE_ID = 'service-request-hourly-service-1';
const WEEKEND_SERVICE_ID = 'service-request-weekend-service-1';
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
  category: 'homeCleaningUpkeep',
  priceType: 'fixed',
  priceAmount: 50,
  pricingMode: 'fixedJob',
  hourlyRate: null,
  fixedJobPrice: 50,
  availability: 'Weekends',
  status: 'active',
  communityId: 'community-1',
  communityName: 'Palm Grove',
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

const validFixedJobRequestCreate = (id) => ({
  id,
  serviceId: SERVICE_ID,
  serviceTitle: baseService.title,
  providerId: PROVIDER_ID,
  providerName: baseService.providerName,
  requesterId: REQUESTER_ID,
  requesterName: 'Service Requester',
  message: 'Another request',
  preferredDate: Timestamp.fromDate(new Date('2026-07-01T00:00:00.000Z')),
  preferredTime: '14:00',
  preferredWeekday: 3,
  preferredTimeMinutes: 14 * 60,
  amount: 50,
  durationHours: null,
  hourlyRate: null,
  currency: 'myr',
  paymentStatus: 'pending',
  paymentId: '',
  paymentProvider: '',
  platformFeeAmount: 0,
  providerPayoutAmount: 50,
  payoutStatus: 'notStarted',
  refundStatus: 'not_started',
  status: 'pending',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

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
    await setDoc(doc(db, 'services', HOURLY_SERVICE_ID), {
      ...baseService,
      id: HOURLY_SERVICE_ID,
      title: 'Hourly cleaning',
      serviceTitle: 'Hourly cleaning',
      priceAmount: 25,
      pricingMode: 'hourly',
      hourlyRate: 25,
      fixedJobPrice: null,
    });
    await setDoc(doc(db, 'services', WEEKEND_SERVICE_ID), {
      ...baseService,
      id: WEEKEND_SERVICE_ID,
      title: 'Weekend cleaning',
      availability: 'Sat, Sun, 9:00 AM - 5:00 PM',
      availableWeekdays: [6, 7],
      availabilityStartMinutes: 9 * 60,
      availabilityEndMinutes: 17 * 60,
    });
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
    await setDoc(doc(db, 'serviceRequests', 'service-request-paid'), {
      ...baseRequest,
      id: 'service-request-paid',
      status: 'pending',
      amount: 50,
      durationHours: null,
      hourlyRate: null,
    });
    await setDoc(doc(db, 'serviceRequests', 'service-request-free'), {
      ...baseRequest,
      id: 'service-request-free',
      status: 'pending',
    });
    await setDoc(doc(db, 'serviceRequests', 'service-request-awaiting-payment'), {
      ...baseRequest,
      id: 'service-request-awaiting-payment',
      status: 'acceptedAwaitingPayment',
      amount: 50,
      durationHours: null,
      hourlyRate: null,
    });
    await setDoc(doc(db, 'serviceRequests', 'service-request-in-progress'), {
      ...baseRequest,
      id: 'service-request-in-progress',
      status: 'inProgress',
      amount: 50,
      durationHours: null,
      hourlyRate: null,
      paymentStatus: 'succeeded',
      paymentId: 'payment-in-progress',
      paymentProvider: 'xendit',
      providerPayoutAmount: 50,
      payoutStatus: 'notStarted',
      refundStatus: 'not_started',
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
      setDoc(
        doc(db, 'serviceRequests', 'service-request-new'),
        validFixedJobRequestCreate('service-request-new'),
      ),
    );
  });

  test('verified resident can create a valid hourly service request', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'serviceRequests', 'service-request-hourly-new'), {
        ...validFixedJobRequestCreate('service-request-hourly-new'),
        serviceId: HOURLY_SERVICE_ID,
        serviceTitle: 'Hourly cleaning',
        amount: 75,
        durationHours: 3,
        hourlyRate: 25,
        providerPayoutAmount: 75,
      }),
    );
  });

  test('resident cannot create a request with unsafe payment fields', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'service-request-unsafe-payment'), {
        ...validFixedJobRequestCreate('service-request-unsafe-payment'),
        paymentStatus: 'completed',
      }),
    );
  });

  test('resident cannot create a service request with extra fields', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'service-request-extra-field'), {
        ...validFixedJobRequestCreate('service-request-extra-field'),
        providerPrivateNote: 'unvalidated payload',
      }),
    );
  });

  test('resident cannot create a request on wrong weekday when service has structured availability', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'service-request-weekday-invalid'), {
        ...validFixedJobRequestCreate('service-request-weekday-invalid'),
        serviceId: WEEKEND_SERVICE_ID,
        serviceTitle: 'Weekend cleaning',
        preferredDate: Timestamp.fromDate(new Date('2026-07-06T00:00:00.000Z')),
        preferredWeekday: 1,
        preferredTimeMinutes: 10 * 60,
      }),
    );
  });

  test('resident can create a weekend request within provider hours', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'serviceRequests', 'service-request-weekend-valid'), {
        ...validFixedJobRequestCreate('service-request-weekend-valid'),
        serviceId: WEEKEND_SERVICE_ID,
        serviceTitle: 'Weekend cleaning',
        preferredDate: Timestamp.fromDate(new Date('2026-07-04T00:00:00.000Z')),
        preferredWeekday: 6,
        preferredTimeMinutes: 10 * 60,
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
  test('provider can accept a free pending request', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', REQUEST_ID), {
        status: 'accepted',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('provider can accept a paid pending request with acceptedAwaitingPayment', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', 'service-request-paid'), {
        status: 'acceptedAwaitingPayment',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('provider cannot accept a paid pending request with accepted only', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'serviceRequests', 'service-request-paid'), {
        status: 'accepted',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('provider can accept a free pending request without amount', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', 'service-request-free'), {
        status: 'accepted',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('provider can reject a pending request', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', 'service-request-hijack'), {
        status: 'rejected',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('requester can cancel a pending request', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', 'service-request-cancel'), {
        status: 'cancelled',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('requester can cancel an acceptedAwaitingPayment request', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', 'service-request-awaiting-payment'), {
        status: 'cancelled',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('provider can complete an accepted request', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'serviceRequests', 'service-request-accepted'), {
        status: 'completed',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('provider cannot reassign requesterId', async () => {
    const db = testEnv.authenticatedContext(PROVIDER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'serviceRequests', 'service-request-hijack'), {
        requesterId: OUTSIDER_ID,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('requester cannot force status to completed', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'serviceRequests', 'service-request-hijack'), {
        status: 'completed',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('requester cannot open a service dispute via client update', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_ID).firestore();
    await assertFails(
      updateDoc(doc(db, 'serviceRequests', 'service-request-in-progress'), {
        status: 'disputed',
        disputeType: 'poorQuality',
        disputeReason: 'Work was not done properly',
        updatedAt: serverTimestamp(),
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
