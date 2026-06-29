import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import Stripe from "stripe";

type DocumentData = admin.firestore.DocumentData;

const PAYMENTS_COLLECTION = "payments";
const USERS_COLLECTION = "users";
const BORROW_REQUESTS_COLLECTION = "borrowRequests";
const PAYMENT_METHODS_COLLECTION = "paymentMethods";
const PAYMENT_TYPE_MARKETPLACE = "marketplace";
const PAYMENT_TYPE_SERVICE = "service";
const PAYMENT_STATUS_PENDING = "pending";
const PAYMENT_STATUS_SUCCEEDED = "succeeded";
const PAYMENT_STATUS_FAILED = "failed";
const PAYMENT_STATUS_CANCELLED = "cancelled";
const BORROW_PAYMENT_STATUS_COMPLETED = "completed";
const BORROW_PAYMENT_STATUS_FAILED = "failed";
const BORROW_PAYMENT_STATUS_CANCELLED = "cancelled";
const BORROW_STATUS_APPROVED = "approved";
const STRIPE_PROVIDER = "stripe";
const DEFAULT_CURRENCY = "myr";
const ALLOWED_CURRENCIES = new Set([DEFAULT_CURRENCY]);
const ALLOWED_PAYMENT_TYPES = new Set([
  PAYMENT_TYPE_MARKETPLACE,
  PAYMENT_TYPE_SERVICE,
]);
const EPHEMERAL_KEY_API_VERSION = "2026-04-22.dahlia";

const stripeSecret = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

let stripeClient: Stripe | undefined;

function stripe(): Stripe {
  if (stripeClient) return stripeClient;
  const secretKey = process.env.STRIPE_SECRET_KEY;
  if (!secretKey) {
    throw new HttpsError(
      "failed-precondition",
      "Stripe secret key is not configured.",
    );
  }
  stripeClient = new Stripe(secretKey);
  return stripeClient;
}

function webhookStripe(): Stripe {
  const secretKey = process.env.STRIPE_SECRET_KEY;
  if (!secretKey) {
    throw new Error("Stripe secret key is not configured.");
  }
  if (!stripeClient) stripeClient = new Stripe(secretKey);
  return stripeClient;
}

function requireUid(auth: {uid?: string} | undefined): string {
  const uid = auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }
  return uid;
}

function asRecord(data: unknown): Record<string, unknown> {
  return data && typeof data === "object" ? data as Record<string, unknown> : {};
}

function readString(
  data: Record<string, unknown>,
  key: string,
  fallback = "",
): string {
  const value = data[key];
  return typeof value === "string" ? value.trim() : fallback;
}

function readPositiveInt(data: Record<string, unknown>, key: string): number {
  const value = data[key];
  if (typeof value !== "number" || !Number.isInteger(value) || value <= 0) {
    throw new HttpsError("invalid-argument", `${key} must be a positive int.`);
  }
  return value;
}

function toMoneyNumber(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function expectedMarketplaceAmount(data: DocumentData): number {
  const usageFee = Math.max(0, toMoneyNumber(data.usageFeeAmount));
  const deposit = Math.max(0, toMoneyNumber(data.depositAmount));
  return Math.round((usageFee + deposit) * 100);
}

function marketplaceChatId(borrowerId: string, ownerId: string): string {
  return [borrowerId, ownerId].sort().join("_");
}

function paymentMethodIdFromDefault(
  defaultPaymentMethod: string | Stripe.PaymentMethod | null | undefined,
): string {
  if (!defaultPaymentMethod) return "";
  return typeof defaultPaymentMethod === "string"
    ? defaultPaymentMethod
    : defaultPaymentMethod.id;
}

function customerIdFromPaymentMethod(
  customer: string | Stripe.Customer | Stripe.DeletedCustomer | null,
): string {
  if (!customer) return "";
  return typeof customer === "string" ? customer : customer.id;
}

function safePaymentMethod(
  paymentMethod: Stripe.PaymentMethod,
  defaultPaymentMethodId: string,
): Record<string, unknown> {
  const card = paymentMethod.card;
  return {
    id: paymentMethod.id,
    stripePaymentMethodId: paymentMethod.id,
    brand: card?.brand ?? "",
    last4: card?.last4 ?? "",
    expMonth: card?.exp_month ?? 0,
    expYear: card?.exp_year ?? 0,
    isDefault: paymentMethod.id === defaultPaymentMethodId,
  };
}

async function ensureStripeCustomer(
  db: admin.firestore.Firestore,
  uid: string,
): Promise<string> {
  const userRef = db.collection(USERS_COLLECTION).doc(uid);
  const userSnapshot = await userRef.get();
  const user = userSnapshot.data();
  if (!user) {
    throw new HttpsError("not-found", "User profile was not found.");
  }

  const existing = typeof user.stripeCustomerId === "string" ?
    user.stripeCustomerId.trim() :
    "";
  if (existing) return existing;

  const email = typeof user.email === "string" ? user.email : undefined;
  const fullName = typeof user.fullName === "string" ?
    user.fullName :
    [user.firstName, user.lastName].filter((value) => typeof value === "string")
      .join(" ");

  // Stripe customer records let PaymentSheet reuse saved payment methods.
  const customer = await stripe().customers.create({
    email,
    name: fullName.trim() || undefined,
    metadata: {firebaseUid: uid},
  });

  await userRef.update({
    stripeCustomerId: customer.id,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return customer.id;
}

async function createEphemeralKey(customerId: string): Promise<string> {
  const key = await stripe().ephemeralKeys.create(
    {customer: customerId},
    {apiVersion: EPHEMERAL_KEY_API_VERSION},
  );
  return key.secret ?? "";
}

async function validateMarketplacePayment(
  db: admin.firestore.Firestore,
  uid: string,
  input: Record<string, unknown>,
): Promise<{
  amount: number;
  currency: string;
  relatedId: string;
  payerId: string;
  receiverId: string;
  itemId: string;
  selectedPaymentMethodId: string;
  requestRef: admin.firestore.DocumentReference;
  requestData: DocumentData;
}> {
  const amount = readPositiveInt(input, "amount");
  const currency = readString(input, "currency", DEFAULT_CURRENCY).toLowerCase();
  const relatedId = readString(input, "relatedId");
  const payerId = readString(input, "payerId");
  const receiverId = readString(input, "receiverId");
  const itemId = readString(input, "itemId");
  const selectedPaymentMethodId = readString(input, "paymentMethodId");

  if (!ALLOWED_CURRENCIES.has(currency)) {
    throw new HttpsError("invalid-argument", "Unsupported currency.");
  }
  if (!relatedId || !payerId || !receiverId || !itemId) {
    throw new HttpsError("invalid-argument", "Missing marketplace payment data.");
  }
  if (!selectedPaymentMethodId) {
    throw new HttpsError("invalid-argument", "Missing payment method id.");
  }
  if (payerId !== uid) {
    throw new HttpsError("permission-denied", "You cannot pay for another user.");
  }

  const requestRef = db.collection(BORROW_REQUESTS_COLLECTION).doc(relatedId);
  const requestSnapshot = await requestRef.get();
  const requestData = requestSnapshot.data();
  if (!requestData) {
    throw new HttpsError("not-found", "Borrow request was not found.");
  }
  if (requestData.borrowerId !== uid || requestData.borrowerId !== payerId) {
    throw new HttpsError("permission-denied", "Invalid payer for this request.");
  }
  if (requestData.ownerId !== receiverId || requestData.itemId !== itemId) {
    throw new HttpsError("invalid-argument", "Payment target does not match request.");
  }
  if (requestData.status !== BORROW_STATUS_APPROVED) {
    throw new HttpsError(
      "failed-precondition",
      "Payment is available after owner approval.",
    );
  }
  if (requestData.paymentStatus === BORROW_PAYMENT_STATUS_COMPLETED) {
    throw new HttpsError("already-exists", "This request is already paid.");
  }

  const expectedAmount = expectedMarketplaceAmount(requestData);
  if (expectedAmount <= 0) {
    throw new HttpsError("failed-precondition", "No payment is required.");
  }
  if (amount !== expectedAmount) {
    throw new HttpsError("invalid-argument", "Payment amount does not match request.");
  }

  return {
    amount,
    currency,
    relatedId,
    payerId,
    receiverId,
    itemId,
    selectedPaymentMethodId,
    requestRef,
    requestData,
  };
}

async function verifyPaymentMethodBelongsToCustomer(
  paymentMethodId: string,
  customerId: string,
): Promise<void> {
  const paymentMethod = await stripe().paymentMethods.retrieve(paymentMethodId);
  if (customerIdFromPaymentMethod(paymentMethod.customer) !== customerId) {
    throw new HttpsError(
      "permission-denied",
      "Payment method does not belong to this user.",
    );
  }
}

async function clearPendingMarketplacePayment(
  requestRef: admin.firestore.DocumentReference,
): Promise<void> {
  await requestRef.set({
    pendingPaymentId: admin.firestore.FieldValue.delete(),
    pendingStripePaymentIntentId: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

async function cancelExistingPendingMarketplacePayment(
  db: admin.firestore.Firestore,
  requestRef: admin.firestore.DocumentReference,
  requestData: DocumentData,
): Promise<void> {
  const pendingPaymentId = typeof requestData.pendingPaymentId === "string" ?
    requestData.pendingPaymentId :
    "";
  if (!pendingPaymentId) return;

  const pendingRef = db.collection(PAYMENTS_COLLECTION).doc(pendingPaymentId);
  const pendingSnapshot = await pendingRef.get();
  const pending = pendingSnapshot.data();
  if (!pending || pending.status !== PAYMENT_STATUS_PENDING) {
    await clearPendingMarketplacePayment(requestRef);
    return;
  }

  const intentId = typeof pending.stripePaymentIntentId === "string" ?
    pending.stripePaymentIntentId :
    "";
  if (!intentId) {
    await pendingRef.update({
      status: PAYMENT_STATUS_CANCELLED,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await clearPendingMarketplacePayment(requestRef);
    return;
  }

  const intent = await stripe().paymentIntents.retrieve(intentId);
  if (intent.status === "succeeded") {
    await updatePaymentFromIntent(intent, PAYMENT_STATUS_SUCCEEDED);
    throw new HttpsError("already-exists", "This request is already paid.");
  }
  if (intent.status === "processing") {
    throw new HttpsError(
      "failed-precondition",
      "A previous payment is still processing. Please refresh shortly.",
    );
  }
  if (intent.status !== "canceled") {
    await stripe().paymentIntents.cancel(intentId);
  }

  await pendingRef.update({
    status: PAYMENT_STATUS_CANCELLED,
    replacementReason: "new_payment_attempt",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await clearPendingMarketplacePayment(requestRef);
}

export const createPaymentIntent = onCall({secrets: [stripeSecret]}, async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const paymentType = readString(input, "paymentType");
  if (!ALLOWED_PAYMENT_TYPES.has(paymentType)) {
    throw new HttpsError("invalid-argument", "Invalid payment type.");
  }
  if (paymentType === PAYMENT_TYPE_SERVICE) {
    throw new HttpsError(
      "failed-precondition",
      "Service payments are not active yet.",
    );
  }

  const db = admin.firestore();
  const marketplace = await validateMarketplacePayment(db, uid, input);
  const customerId = await ensureStripeCustomer(db, uid);
  await verifyPaymentMethodBelongsToCustomer(
    marketplace.selectedPaymentMethodId,
    customerId,
  );
  await cancelExistingPendingMarketplacePayment(
    db,
    marketplace.requestRef,
    marketplace.requestData,
  );
  const paymentRef = db.collection(PAYMENTS_COLLECTION).doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Firestore payment records are created before Stripe so metadata can point
  // back to the authoritative app payment id.
  await paymentRef.set({
    payerId: marketplace.payerId,
    receiverId: marketplace.receiverId,
    paymentType,
    relatedId: marketplace.relatedId,
    itemId: marketplace.itemId,
    amount: marketplace.amount,
    currency: marketplace.currency,
    status: PAYMENT_STATUS_PENDING,
    stripeCustomerId: customerId,
    selectedPaymentMethodId: marketplace.selectedPaymentMethodId,
    stripePaymentIntentId: "",
    createdAt: now,
    updatedAt: now,
  });

  try {
    // PaymentIntent creation stays server-side so Stripe secret keys never
    // enter Flutter. Metadata lets webhooks update Firestore safely later.
    const intent = await stripe().paymentIntents.create({
      amount: marketplace.amount,
      currency: marketplace.currency,
      customer: customerId,
      payment_method: marketplace.selectedPaymentMethodId,
      automatic_payment_methods: {enabled: true},
      setup_future_usage: "off_session",
      description: readString(input, "description", "Jirani marketplace payment"),
      metadata: {
        paymentId: paymentRef.id,
        paymentType,
        relatedId: marketplace.relatedId,
        payerId: marketplace.payerId,
        receiverId: marketplace.receiverId,
        itemId: marketplace.itemId,
        selectedPaymentMethodId: marketplace.selectedPaymentMethodId,
      },
    });

    await paymentRef.update({
      stripePaymentIntentId: intent.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await marketplace.requestRef.set({
      pendingPaymentId: paymentRef.id,
      pendingStripePaymentIntentId: intent.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    return {
      clientSecret: intent.client_secret,
      paymentId: paymentRef.id,
      customerId,
      ephemeralKey: await createEphemeralKey(customerId),
    };
  } catch (error) {
    await paymentRef.update({
      status: PAYMENT_STATUS_FAILED,
      errorMessage: error instanceof Error ? error.message : "Stripe error",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw error;
  }
});

export const createSetupIntent = onCall({secrets: [stripeSecret]}, async (request) => {
  const uid = requireUid(request.auth);
  const db = admin.firestore();
  const customerId = await ensureStripeCustomer(db, uid);

  // SetupIntent lets Stripe collect and save card details without the app
  // touching card numbers, CVV, or full expiry data.
  const setupIntent = await stripe().setupIntents.create({
    customer: customerId,
    automatic_payment_methods: {enabled: true},
    usage: "off_session",
    metadata: {firebaseUid: uid},
  });

  return {
    setupIntentClientSecret: setupIntent.client_secret,
    customerId,
    ephemeralKey: await createEphemeralKey(customerId),
  };
});

export const listPaymentMethods = onCall({secrets: [stripeSecret]}, async (request) => {
  const uid = requireUid(request.auth);
  const db = admin.firestore();
  const userSnapshot = await db.collection(USERS_COLLECTION).doc(uid).get();
  const customerId = userSnapshot.data()?.stripeCustomerId;
  if (typeof customerId !== "string" || !customerId.trim()) {
    return {paymentMethods: []};
  }

  const customer = await stripe().customers.retrieve(customerId);
  if (customer.deleted) return {paymentMethods: []};
  const defaultPaymentMethodId = paymentMethodIdFromDefault(
    customer.invoice_settings.default_payment_method,
  );
  const paymentMethods = await stripe().paymentMethods.list({
    customer: customerId,
    type: "card",
  });
  const safeMethods = paymentMethods.data.map((method) =>
    safePaymentMethod(method, defaultPaymentMethodId),
  );

  // Keep safe card metadata in Firestore for admin/support visibility without
  // storing any sensitive card data.
  const batch = db.batch();
  const methodsRef = db
    .collection(USERS_COLLECTION)
    .doc(uid)
    .collection(PAYMENT_METHODS_COLLECTION);
  for (const method of safeMethods) {
    batch.set(methodsRef.doc(String(method.id)), {
      ...method,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  await batch.commit();

  return {paymentMethods: safeMethods};
});

export const deletePaymentMethod = onCall({secrets: [stripeSecret]}, async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const paymentMethodId = readString(input, "paymentMethodId");
  if (!paymentMethodId) {
    throw new HttpsError("invalid-argument", "Missing payment method id.");
  }

  const db = admin.firestore();
  const userSnapshot = await db.collection(USERS_COLLECTION).doc(uid).get();
  const customerId = userSnapshot.data()?.stripeCustomerId;
  if (typeof customerId !== "string" || !customerId.trim()) {
    throw new HttpsError("failed-precondition", "No Stripe customer exists.");
  }

  const paymentMethod = await stripe().paymentMethods.retrieve(paymentMethodId);
  if (customerIdFromPaymentMethod(paymentMethod.customer) !== customerId) {
    throw new HttpsError(
      "permission-denied",
      "Payment method does not belong to this user.",
    );
  }

  // Detaching removes the saved card from the Stripe customer. Firestore only
  // stores safe metadata, so deleting it locally is enough after detach.
  await stripe().paymentMethods.detach(paymentMethodId);
  await db
    .collection(USERS_COLLECTION)
    .doc(uid)
    .collection(PAYMENT_METHODS_COLLECTION)
    .doc(paymentMethodId)
    .delete();

  return {success: true};
});

export const setDefaultPaymentMethod = onCall({secrets: [stripeSecret]}, async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const paymentMethodId = readString(input, "paymentMethodId");
  if (!paymentMethodId) {
    throw new HttpsError("invalid-argument", "Missing payment method id.");
  }

  const db = admin.firestore();
  const userSnapshot = await db.collection(USERS_COLLECTION).doc(uid).get();
  const customerId = userSnapshot.data()?.stripeCustomerId;
  if (typeof customerId !== "string" || !customerId.trim()) {
    throw new HttpsError("failed-precondition", "No Stripe customer exists.");
  }

  const paymentMethod = await stripe().paymentMethods.retrieve(paymentMethodId);
  if (customerIdFromPaymentMethod(paymentMethod.customer) !== customerId) {
    throw new HttpsError(
      "permission-denied",
      "Payment method does not belong to this user.",
    );
  }

  await stripe().customers.update(customerId, {
    invoice_settings: {default_payment_method: paymentMethodId},
  });

  const methods = await stripe().paymentMethods.list({
    customer: customerId,
    type: "card",
  });
  const batch = db.batch();
  const methodsRef = db
    .collection(USERS_COLLECTION)
    .doc(uid)
    .collection(PAYMENT_METHODS_COLLECTION);
  for (const method of methods.data) {
    batch.set(methodsRef.doc(method.id), {
      ...safePaymentMethod(method, paymentMethodId),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  await batch.commit();

  return {success: true};
});

export const getPaymentStatus = onCall({secrets: [stripeSecret]}, async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const paymentId = readString(input, "paymentId");
  if (!paymentId) {
    throw new HttpsError("invalid-argument", "Missing payment id.");
  }

  const snapshot = await admin.firestore()
    .collection(PAYMENTS_COLLECTION)
    .doc(paymentId)
    .get();
  const data = snapshot.data();
  if (!data) {
    throw new HttpsError("not-found", "Payment was not found.");
  }
  if (data.payerId !== uid && data.receiverId !== uid) {
    throw new HttpsError("permission-denied", "You cannot read this payment.");
  }

  return {
    paymentId,
    status: data.status ?? PAYMENT_STATUS_PENDING,
    paymentType: data.paymentType ?? "",
    relatedId: data.relatedId ?? "",
  };
});

async function updateMarketplaceBorrowRequest(
  payment: DocumentData,
  status: string,
): Promise<void> {
  if (payment.paymentType !== PAYMENT_TYPE_MARKETPLACE) return;
  const relatedId = typeof payment.relatedId === "string" ? payment.relatedId : "";
  if (!relatedId) return;

  const update: Record<string, unknown> = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (status === PAYMENT_STATUS_SUCCEEDED) {
    // Marketplace success unlocks chat and handover; Flutter never performs
    // this final state transition directly.
    update.paymentStatus = BORROW_PAYMENT_STATUS_COMPLETED;
    update.paymentProvider = STRIPE_PROVIDER;
    update.paymentCompletedAt = admin.firestore.FieldValue.serverTimestamp();
    update.paymentId = payment.id;
    update.stripePaymentIntentId = payment.stripePaymentIntentId;
    update.chatId = marketplaceChatId(
      String(payment.payerId ?? ""),
      String(payment.receiverId ?? ""),
    );
    update.pendingPaymentId = admin.firestore.FieldValue.delete();
    update.pendingStripePaymentIntentId = admin.firestore.FieldValue.delete();
  } else if (status === PAYMENT_STATUS_FAILED) {
    update.paymentStatus = BORROW_PAYMENT_STATUS_FAILED;
    update.pendingPaymentId = admin.firestore.FieldValue.delete();
    update.pendingStripePaymentIntentId = admin.firestore.FieldValue.delete();
  } else if (status === PAYMENT_STATUS_CANCELLED) {
    update.paymentStatus = BORROW_PAYMENT_STATUS_CANCELLED;
    update.pendingPaymentId = admin.firestore.FieldValue.delete();
    update.pendingStripePaymentIntentId = admin.firestore.FieldValue.delete();
  }

  await admin.firestore()
    .collection(BORROW_REQUESTS_COLLECTION)
    .doc(relatedId)
    .set(update, {merge: true});
}

async function updatePaymentFromIntent(
  intent: Stripe.PaymentIntent,
  status: string,
): Promise<void> {
  const paymentId = intent.metadata.paymentId;
  if (!paymentId) {
    logger.warn("Stripe PaymentIntent missing paymentId metadata", {
      paymentIntentId: intent.id,
    });
    return;
  }

  const paymentRef = admin.firestore().collection(PAYMENTS_COLLECTION).doc(paymentId);
  const update = {
    id: paymentId,
    status,
    stripePaymentIntentId: intent.id,
    lastStripeEventAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await paymentRef.set(update, {merge: true});
  const latest = await paymentRef.get();
  const payment = latest.data();
  if (!payment) return;
  await updateMarketplaceBorrowRequest({...payment, id: paymentId}, status);
}

export const stripeWebhook = onRequest(
  {secrets: [stripeSecret, stripeWebhookSecret]},
  async (request, response) => {
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!webhookSecret) {
    response.status(500).send("Stripe webhook secret is not configured.");
    return;
  }

  const signature = request.header("stripe-signature");
  const rawBody = (request as {rawBody?: Buffer}).rawBody;
  if (!signature || !rawBody) {
    response.status(400).send("Missing Stripe signature or raw body.");
    return;
  }

  let event: Stripe.Event;
  try {
    event = webhookStripe().webhooks.constructEvent(
      rawBody,
      signature,
      webhookSecret,
    );
  } catch (error) {
    logger.warn("Invalid Stripe webhook signature", {error});
    response.status(400).send("Invalid Stripe webhook signature.");
    return;
  }

  try {
    switch (event.type) {
    case "payment_intent.succeeded":
      await updatePaymentFromIntent(
        event.data.object as Stripe.PaymentIntent,
        PAYMENT_STATUS_SUCCEEDED,
      );
      break;
    case "payment_intent.payment_failed":
      await updatePaymentFromIntent(
        event.data.object as Stripe.PaymentIntent,
        PAYMENT_STATUS_FAILED,
      );
      break;
    case "payment_intent.canceled":
      await updatePaymentFromIntent(
        event.data.object as Stripe.PaymentIntent,
        PAYMENT_STATUS_CANCELLED,
      );
      break;
    case "setup_intent.succeeded":
      logger.info("Stripe setup intent succeeded", {
        setupIntentId: (event.data.object as Stripe.SetupIntent).id,
      });
      break;
    default:
      logger.debug("Unhandled Stripe event", {type: event.type});
    }
    response.json({received: true});
  } catch (error) {
    logger.error("Failed to process Stripe webhook", {type: event.type, error});
    response.status(500).send("Webhook processing failed.");
  }
});
