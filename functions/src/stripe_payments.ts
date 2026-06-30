import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import Stripe from "stripe";
import {createInAppNotification} from "./notifications";

type DocumentData = admin.firestore.DocumentData;

const PAYMENTS_COLLECTION = "payments";
const USERS_COLLECTION = "users";
const ADMINS_COLLECTION = "admins";
const BORROW_REQUESTS_COLLECTION = "borrowRequests";
const REPORTS_COLLECTION = "reports";
const PAYMENT_METHODS_COLLECTION = "paymentMethods";
const PAYMENT_TYPE_MARKETPLACE = "marketplace";
const PAYMENT_TYPE_SERVICE = "service";
const PAYMENT_STATUS_PENDING = "pending";
const PAYMENT_STATUS_SUCCEEDED = "succeeded";
const PAYMENT_STATUS_FAILED = "failed";
const PAYMENT_STATUS_CANCELLED = "cancelled";
const NOTIFICATION_TYPE_BORROW_DEPOSIT_RESOLVED = "borrowDepositResolved";
const NOTIFICATION_TYPE_BORROW_PAYOUT_READY = "borrowPayoutReady";
const NOTIFICATION_TYPE_BORROW_PAYOUT_PAID = "borrowPayoutPaid";
const BORROW_PAYMENT_STATUS_COMPLETED = "completed";
const BORROW_PAYMENT_STATUS_FAILED = "failed";
const BORROW_PAYMENT_STATUS_CANCELLED = "cancelled";
const BORROW_STATUS_APPROVED = "approved";
const BORROW_STATUS_COMPLETED = "completed";
const BORROW_STATUS_DISPUTED = "disputed";
const STRIPE_PROVIDER = "stripe";
const ROLE_COMMUNITY_ADMIN = "communityAdmin";
const ROLE_SYSTEM_ADMIN = "systemAdmin";
const DEFAULT_CURRENCY = "myr";
const ALLOWED_CURRENCIES = new Set([DEFAULT_CURRENCY]);
const ALLOWED_PAYMENT_TYPES = new Set([
  PAYMENT_TYPE_MARKETPLACE,
  PAYMENT_TYPE_SERVICE,
]);
const EPHEMERAL_KEY_API_VERSION = "2026-04-22.dahlia";
const DEPOSIT_STATUS_HELD = "held";
const DEPOSIT_STATUS_REFUNDED = "refunded";
const DEPOSIT_STATUS_PARTIALLY_REFUNDED = "partially_refunded";
const DEPOSIT_STATUS_DEDUCTED = "deducted";
const DEPOSIT_STATUS_DISPUTED = "disputed";
const DEPOSIT_STATUS_REFUND_FAILED = "refund_failed";
const DEPOSIT_STATUS_NOT_REQUIRED = "not_required";
const REFUND_STATUS_NOT_STARTED = "not_started";
const REFUND_STATUS_PENDING = "pending";
const REFUND_STATUS_SUCCEEDED = "succeeded";
const REFUND_STATUS_FAILED = "failed";
const REFUND_STATUS_NOT_REQUIRED = "not_required";
const DAMAGE_DECISION_NONE = "none";
const DAMAGE_DECISION_BORROWER_ACCEPTED = "borrower_accepted";
const DAMAGE_DECISION_ADMIN_FULL_REFUND = "admin_full_refund";
const DAMAGE_DECISION_ADMIN_PARTIAL_DEDUCTION = "admin_partial_deduction";
const DAMAGE_DECISION_ADMIN_FULL_DEDUCTION = "admin_full_deduction";
const MANUAL_PAYOUT_NOT_READY = "not_ready";
const MANUAL_PAYOUT_BLOCKED = "blocked";
const MANUAL_PAYOUT_PENDING_MANUAL = "pending_manual";
const MANUAL_PAYOUT_PAID = "paid";
const STRIPE_TRANSFER_STATUS_NOT_READY = "not_ready";
const STRIPE_TRANSFER_STATUS_PENDING = "pending";
const STRIPE_TRANSFER_STATUS_PAID = "paid";
const STRIPE_TRANSFER_STATUS_FAILED = "failed";
const RESOLUTION_FULL_REFUND = "full_refund";
const RESOLUTION_PARTIAL_DEDUCTION = "partial_deduction";
const RESOLUTION_FULL_DEDUCTION = "full_deduction";
const MINOR_ISSUE_ACCEPTED = "accepted";
const DEPOSIT_DECISION_RETURN_DEPOSIT = "returnDeposit";
const DEPOSIT_DECISION_PARTIAL_DEDUCTION = "partialDeduction";
const DEPOSIT_DECISION_WITHHOLD_DEPOSIT = "withholdDeposit";
const ADMIN_RESOLUTION_FOR_BORROWER = "resolveForBorrower";
const ADMIN_RESOLUTION_FOR_LENDER = "resolveForLender";

const stripeSecret = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

let stripeClient: Stripe | undefined;

// Payments backend: creates the Stripe client for callable functions using the secret stored in Firebase Functions.
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

// Payments backend: creates the Stripe client used by the HTTP webhook handler.
function webhookStripe(): Stripe {
  const secretKey = process.env.STRIPE_SECRET_KEY;
  if (!secretKey) {
    throw new Error("Stripe secret key is not configured.");
  }
  if (!stripeClient) stripeClient = new Stripe(secretKey);
  return stripeClient;
}

// Security helper: requires Firebase Auth so users cannot call payment functions anonymously.
function requireUid(auth: {uid?: string} | undefined): string {
  const uid = auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }
  return uid;
}

// Callable helper: normalizes incoming request data into an object before reading fields.
function asRecord(data: unknown): Record<string, unknown> {
  return data && typeof data === "object" ? data as Record<string, unknown> : {};
}

// Callable helper: reads and trims string parameters from callable function input.
function readString(
  data: Record<string, unknown>,
  key: string,
  fallback = "",
): string {
  const value = data[key];
  return typeof value === "string" ? value.trim() : fallback;
}

// Payments validation: reads Stripe minor-unit amounts and rejects zero, negative, or non-integer values.
function readPositiveInt(data: Record<string, unknown>, key: string): number {
  const value = data[key];
  if (typeof value !== "number" || !Number.isInteger(value) || value <= 0) {
    throw new HttpsError("invalid-argument", `${key} must be a positive int.`);
  }
  return value;
}

// Payments validation: reads optional RM amount fields used by deposit resolution decisions.
function readNumber(data: Record<string, unknown>, key: string): number {
  const value = data[key];
  if (value === undefined || value === null) return 0;
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new HttpsError("invalid-argument", `${key} must be a number.`);
  }
  return value;
}

// Payments helper: safely converts Firestore money fields into numbers.
function toMoneyNumber(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

// Stripe helper: converts RM values into Stripe minor units (sen).
function moneyToMinorUnits(value: number): number {
  return Math.max(0, Math.round(value * 100));
}

// Marketplace payments: calculates the expected Stripe charge amount from usage fee plus deposit.
function expectedMarketplaceAmount(data: DocumentData): number {
  const usageFee = Math.max(0, toMoneyNumber(data.usageFeeAmount));
  const deposit = Math.max(0, toMoneyNumber(data.depositAmount));
  return Math.round((usageFee + deposit) * 100);
}

// Marketplace payments: creates the deterministic chat id unlocked after the payment webhook succeeds.
function marketplaceChatId(borrowerId: string, ownerId: string): string {
  return [borrowerId, ownerId].sort().join("_");
}

// Admin security: checks both users and admins collections for roles allowed to resolve deposits.
async function isAdminUser(db: admin.firestore.Firestore, uid: string): Promise<boolean> {
  const [userSnapshot, adminSnapshot] = await Promise.all([
    db.collection(USERS_COLLECTION).doc(uid).get(),
    db.collection(ADMINS_COLLECTION).doc(uid).get(),
  ]);
  const userRole = userSnapshot.data()?.role;
  const adminRole = adminSnapshot.data()?.role;
  return userRole === ROLE_COMMUNITY_ADMIN ||
    userRole === ROLE_SYSTEM_ADMIN ||
    adminRole === ROLE_COMMUNITY_ADMIN ||
    adminRole === ROLE_SYSTEM_ADMIN;
}

// Admin security: blocks non-admins from manual payout and admin-only deposit actions.
async function requireAdmin(
  db: admin.firestore.Firestore,
  uid: string,
): Promise<void> {
  if (!await isAdminUser(db, uid)) {
    throw new HttpsError("permission-denied", "Admin access is required.");
  }
}

// Payments backend: stores a short safe failure reason without leaking full Stripe/internal errors.
function safeErrorMessage(error: unknown): string {
  if (error instanceof Error && error.message.trim()) {
    return error.message.trim().slice(0, 500);
  }
  return "Stripe refund failed.";
}

// Notifications helper: builds deterministic ids so retried functions do not duplicate resident notifications.
function notificationIdFor(...parts: string[]): string {
  return parts.join("_").replace(/\//g, "_");
}

// Payments UI helper: formats RM amounts used in backend-created notification messages.
function moneyLabel(value: number): string {
  return `RM ${value.toFixed(2)}`;
}

// Stripe Connect payouts: returns true only when the lender account can receive transfers and payouts.
function transferCapable(account: Stripe.Account): boolean {
  return account.capabilities?.transfers === "active" &&
    account.charges_enabled === true &&
    account.payouts_enabled === true;
}

// Stripe Connect payouts: maps Stripe account requirements into app statuses shown to lenders.
function connectStatusFor(account: Stripe.Account): string {
  if (transferCapable(account)) return "complete";
  if ((account.requirements?.currently_due ?? []).length > 0 ||
      (account.requirements?.past_due ?? []).length > 0 ||
      account.details_submitted !== true) {
    return "needs_onboarding";
  }
  return "pending";
}

// Stripe Connect payouts: accepts only HTTPS return URLs and falls back to the hosted app URL.
function connectReturnUrl(input: Record<string, unknown>, key: string): string {
  const value = readString(input, key);
  if (value.startsWith("https://")) return value;
  return "https://final-year-project-faisal.web.app/stripe-connect-return";
}

// Marketplace deposit notifications: builds borrower/lender wording for refund, partial deduction, or full deduction decisions.
function depositDecisionNotificationBodies(
  decision: string,
  itemTitle: string,
  depositAmount: number,
  deductionAmount: number,
  refundAmount: number,
  reason: string,
): {borrower: string; lender: string} {
  const note = reason.trim() ? ` Admin note: ${reason.trim()}` : "";
  if (decision === RESOLUTION_FULL_REFUND) {
    return {
      borrower: `Admin decided to return your ${moneyLabel(depositAmount)} deposit for "${itemTitle}".${note}`,
      lender: `Admin decided to return the deposit to the borrower for "${itemTitle}". No deposit payout is due.${note}`,
    };
  }
  if (decision === RESOLUTION_PARTIAL_DEDUCTION) {
    return {
      borrower: `Admin approved a ${moneyLabel(deductionAmount)} deduction for "${itemTitle}". ${moneyLabel(refundAmount)} will return to you.${note}`,
      lender: `Admin approved a ${moneyLabel(deductionAmount)} damage deduction for "${itemTitle}". Your manual payout is being prepared.${note}`,
    };
  }
  return {
    borrower: `Admin awarded the ${moneyLabel(depositAmount)} deposit to the lender for "${itemTitle}". No deposit refund is due.${note}`,
    lender: `Admin awarded the ${moneyLabel(depositAmount)} deposit to you for "${itemTitle}". Your manual payout is ready to collect.${note}`,
  };
}

// Marketplace deposit payouts: tells the lender to collect from admin when automatic Stripe transfer is not available.
async function notifyManualPayoutReady(
  db: admin.firestore.Firestore,
  borrowRequestId: string,
  data: DocumentData,
  actorId: string,
): Promise<void> {
  const ownerId = typeof data.ownerId === "string" ? data.ownerId : "";
  const itemTitle = typeof data.itemTitle === "string" && data.itemTitle.trim() ?
    data.itemTitle.trim() :
    "your marketplace item";
  const payoutAmount = moneyLabel(Math.max(0, toMoneyNumber(data.lenderTotalEarning)));
  await createInAppNotification(db, {
    userId: ownerId,
    actorId,
    type: NOTIFICATION_TYPE_BORROW_PAYOUT_READY,
    title: "Deposit payout ready",
    body: `Admin has ${payoutAmount} ready for "${itemTitle}". Please collect the manual payout from admin.`,
    category: "Marketplace",
    borrowRequestId,
    notificationId: notificationIdFor(
      "borrowPayoutReady",
      borrowRequestId,
      ownerId,
    ),
  });
}

// Stripe Connect payouts: refreshes a lender's Stripe account capabilities into users/{uid}.
async function syncConnectAccountStatus(
  db: admin.firestore.Firestore,
  uid: string,
  accountId: string,
): Promise<{account: Stripe.Account; status: string; payoutsEnabled: boolean}> {
  const account = await stripe().accounts.retrieve(accountId);
  const status = connectStatusFor(account);
  const payoutsEnabled = transferCapable(account);
  await db.collection(USERS_COLLECTION).doc(uid).set({
    stripeConnectAccountId: account.id,
    stripeConnectStatus: status,
    stripeConnectChargesEnabled: account.charges_enabled === true,
    stripeConnectPayoutsEnabled: account.payouts_enabled === true,
    stripeConnectTransfersCapability: account.capabilities?.transfers ?? "",
    stripeConnectDetailsSubmitted: account.details_submitted === true,
    stripeConnectRequirementsDue: account.requirements?.currently_due ?? [],
    stripeConnectDisabledReason: account.requirements?.disabled_reason ?? "",
    stripeConnectUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  return {account, status, payoutsEnabled};
}

// Stripe Connect payouts: creates or reuses the lender's connected account before onboarding or transfers.
async function ensureConnectAccount(
  db: admin.firestore.Firestore,
  uid: string,
): Promise<{account: Stripe.Account; status: string; payoutsEnabled: boolean}> {
  const userRef = db.collection(USERS_COLLECTION).doc(uid);
  const userSnap = await userRef.get();
  const userData = userSnap.data();
  if (!userData) {
    throw new HttpsError("not-found", "User profile was not found.");
  }

  const existingAccountId =
    typeof userData.stripeConnectAccountId === "string" ?
      userData.stripeConnectAccountId :
      "";
  if (existingAccountId) {
    return syncConnectAccountStatus(db, uid, existingAccountId);
  }

  const fullName = `${readString(userData, "firstName")} ${readString(userData, "lastName")}`.trim();
  const account = await stripe().accounts.create({
    country: "MY",
    email: readString(userData, "email"),
    business_type: "individual",
    business_profile: {
      name: fullName || "Jirani lender",
      product_description: "Marketplace item lending payouts on Jirani",
    },
    capabilities: {
      transfers: {requested: true},
    },
    controller: {
      fees: {payer: "application"},
      losses: {payments: "application"},
      requirement_collection: "stripe",
      stripe_dashboard: {type: "express"},
    },
    metadata: {
      firebaseUid: uid,
      app: "jirani",
      purpose: "lender_payouts",
    },
  });
  return syncConnectAccountStatus(db, uid, account.id);
}

// Callable API: starts Stripe Express onboarding or opens the lender dashboard when payout setup is already complete.
export const createConnectOnboardingLink = onCall(
  {secrets: [stripeSecret]},
  async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const db = admin.firestore();
  const {account, status, payoutsEnabled} = await ensureConnectAccount(db, uid);
  if (payoutsEnabled) {
    const loginLink = await stripe().accounts.createLoginLink(account.id);
    return {
      url: loginLink.url,
      accountId: account.id,
      status,
      payoutsEnabled,
    };
  }
  const accountLink = await stripe().accountLinks.create({
    account: account.id,
    type: "account_onboarding",
    refresh_url: connectReturnUrl(input, "refreshUrl"),
    return_url: connectReturnUrl(input, "returnUrl"),
    collection_options: {
      fields: "eventually_due",
      future_requirements: "include",
    },
  });
  return {
    url: accountLink.url,
    accountId: account.id,
    status,
    payoutsEnabled,
  };
});

// Callable API: returns the current lender Stripe Connect payout readiness to Flutter.
export const getConnectAccountStatus = onCall(
  {secrets: [stripeSecret]},
  async (request) => {
  const uid = requireUid(request.auth);
  const db = admin.firestore();
  const userSnap = await db.collection(USERS_COLLECTION).doc(uid).get();
  const accountId = userSnap.data()?.stripeConnectAccountId;
  if (typeof accountId !== "string" || !accountId) {
    return {
      accountId: "",
      status: "not_started",
      payoutsEnabled: false,
      chargesEnabled: false,
      transfersCapability: "",
      requirementsDue: [],
    };
  }
  const {account, status, payoutsEnabled} =
    await syncConnectAccountStatus(db, uid, accountId);
  return {
    accountId: account.id,
    status,
    payoutsEnabled,
    chargesEnabled: account.charges_enabled === true,
    transfersCapability: account.capabilities?.transfers ?? "",
    detailsSubmitted: account.details_submitted === true,
    requirementsDue: account.requirements?.currently_due ?? [],
    disabledReason: account.requirements?.disabled_reason ?? "",
  };
});

// Stripe Connect payouts: transfers lender earnings after deposit resolution when the lender account is fully onboarded.
async function createStripeLenderTransferIfReady(
  db: admin.firestore.Firestore,
  borrowRequestId: string,
  data: DocumentData,
  actorId: string,
): Promise<{
  transferred: boolean;
  transferId: string;
  reason: string;
}> {
  const ownerId = typeof data.ownerId === "string" ? data.ownerId : "";
  const transferAmount = Math.max(0, toMoneyNumber(data.lenderTotalEarning));
  if (!ownerId || transferAmount <= 0) {
    return {transferred: false, transferId: "", reason: "no_lender_earning"};
  }
  if (typeof data.stripeTransferId === "string" && data.stripeTransferId) {
    return {
      transferred: true,
      transferId: data.stripeTransferId,
      reason: "already_transferred",
    };
  }

  const ownerSnap = await db.collection(USERS_COLLECTION).doc(ownerId).get();
  const ownerData = ownerSnap.data();
  const accountId = typeof ownerData?.stripeConnectAccountId === "string" ?
    ownerData.stripeConnectAccountId :
    "";
  if (!accountId) {
    return {transferred: false, transferId: "", reason: "connect_not_started"};
  }

  const {payoutsEnabled} = await syncConnectAccountStatus(db, ownerId, accountId);
  if (!payoutsEnabled) {
    return {transferred: false, transferId: "", reason: "connect_incomplete"};
  }

  const itemTitle = typeof data.itemTitle === "string" && data.itemTitle.trim() ?
    data.itemTitle.trim() :
    "marketplace item";
  const paymentIntentId = typeof data.stripePaymentIntentId === "string" ?
    data.stripePaymentIntentId :
    "";
  const sourceTransaction = typeof data.stripeChargeId === "string" ?
    data.stripeChargeId :
    "";
  const transfer = await stripe().transfers.create({
    amount: moneyToMinorUnits(transferAmount),
    currency: DEFAULT_CURRENCY,
    destination: accountId,
    description: `Jirani lender payout for ${itemTitle}`,
    transfer_group: `borrow_${borrowRequestId}`,
    ...(sourceTransaction ? {source_transaction: sourceTransaction} : {}),
    metadata: {
      borrowRequestId,
      ownerId,
      paymentIntentId,
      payoutType: "marketplace_lender_earning",
      actorId,
    },
  }, {
    idempotencyKey: `borrow_${borrowRequestId}_lender_transfer`,
  });

  await db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId).set({
    stripeTransferId: transfer.id,
    stripeTransferDestinationAccountId: accountId,
    stripeTransferAmount: transferAmount,
    stripeTransferStatus: STRIPE_TRANSFER_STATUS_PAID,
    stripeTransferCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
    manualPayoutStatus: MANUAL_PAYOUT_PAID,
    manualPayoutMarkedAt: admin.firestore.FieldValue.serverTimestamp(),
    manualPayoutMarkedBy: "stripeConnect",
    manualPayoutReference: transfer.id,
    manualPayoutNote: "Paid automatically through Stripe Connect.",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  await createInAppNotification(db, {
    userId: ownerId,
    actorId,
    type: NOTIFICATION_TYPE_BORROW_PAYOUT_PAID,
    title: "Stripe payout sent",
    body: `Stripe sent your ${moneyLabel(transferAmount)} payout for "${itemTitle}" to your connected account. Reference: ${transfer.id}.`,
    category: "Marketplace",
    borrowRequestId,
    notificationId: notificationIdFor(
      "borrowPayoutPaidStripe",
      borrowRequestId,
      ownerId,
    ),
  });

  return {transferred: true, transferId: transfer.id, reason: "transferred"};
}

// Saved cards: extracts the default payment method id whether Stripe returns an id or expanded object.
function paymentMethodIdFromDefault(
  defaultPaymentMethod: string | Stripe.PaymentMethod | null | undefined,
): string {
  if (!defaultPaymentMethod) return "";
  return typeof defaultPaymentMethod === "string"
    ? defaultPaymentMethod
    : defaultPaymentMethod.id;
}

// Saved cards security: extracts the Stripe customer id attached to a payment method for ownership checks.
function customerIdFromPaymentMethod(
  customer: string | Stripe.Customer | Stripe.DeletedCustomer | null,
): string {
  if (!customer) return "";
  return typeof customer === "string" ? customer : customer.id;
}

// Saved cards: returns only safe card metadata for Flutter and Firestore, never card number or CVV.
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

// Saved cards: creates or reuses the Stripe customer linked to the Firebase user.
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

// Stripe PaymentSheet: creates an ephemeral key so Flutter can access the current customer's PaymentSheet data.
async function createEphemeralKey(customerId: string): Promise<string> {
  const key = await stripe().ephemeralKeys.create(
    {customer: customerId},
    {apiVersion: EPHEMERAL_KEY_API_VERSION},
  );
  return key.secret ?? "";
}

// Marketplace payments: verifies borrower, owner, item, approval status, selected card, and exact amount before charging.
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

// Saved cards security: blocks users from paying with or modifying another customer's Stripe payment method.
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

// Marketplace payments: removes stale pending payment markers from the borrow request.
async function clearPendingMarketplacePayment(
  requestRef: admin.firestore.DocumentReference,
): Promise<void> {
  await requestRef.set({
    pendingPaymentId: admin.firestore.FieldValue.delete(),
    pendingStripePaymentIntentId: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

// Marketplace payments: cancels an old pending Stripe intent before creating a replacement payment attempt.
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

// Callable API: creates a marketplace PaymentIntent only after Firebase Auth and borrow-request validation pass.
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
    usageFeeAmount: Math.max(0, toMoneyNumber(marketplace.requestData.usageFeeAmount)),
    depositAmount: Math.max(0, toMoneyNumber(marketplace.requestData.depositAmount)),
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

// Callable API: creates a SetupIntent so residents can save cards through Stripe's secure PaymentSheet.
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

// Callable API: lists saved card metadata for the current Firebase user's Stripe customer.
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

// Callable API: detaches a saved card after confirming it belongs to the current user's Stripe customer.
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

// Callable API: updates the Stripe customer default payment method and syncs safe card metadata to Firestore.
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

// Callable API: lets borrower/lender read their payment status after the webhook updates payments/{paymentId}.
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

// Marketplace deposit resolution: validates that refund/deduction amounts match the selected admin decision.
function assertDepositResolutionInput(
  decision: string,
  depositAmount: number,
  deductionAmount: number,
): void {
  if (decision === RESOLUTION_FULL_REFUND && deductionAmount !== 0) {
    throw new HttpsError("invalid-argument", "Full refund deduction must be 0.");
  }
  if (
    decision === RESOLUTION_PARTIAL_DEDUCTION &&
    (deductionAmount <= 0 || deductionAmount >= depositAmount)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Partial deduction must be more than 0 and less than the deposit.",
    );
  }
  if (
    decision === RESOLUTION_FULL_DEDUCTION &&
    deductionAmount !== depositAmount
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Full deduction must equal the full deposit.",
    );
  }
  if (![
    RESOLUTION_FULL_REFUND,
    RESOLUTION_PARTIAL_DEDUCTION,
    RESOLUTION_FULL_DEDUCTION,
  ].includes(decision)) {
    throw new HttpsError("invalid-argument", "Invalid deposit decision.");
  }
}

// Marketplace deposit resolution: allows limited self-service resolutions, while admin decisions use admin role checks.
function resolutionAllowedForParticipant(
  requestData: DocumentData,
  uid: string,
  decision: string,
  deductionAmount: number,
): boolean {
  const isOwner = requestData.ownerId === uid;
  const isBorrower = requestData.borrowerId === uid;
  const depositAmount = Math.max(0, toMoneyNumber(requestData.depositAmount));
  if (depositAmount <= 0) {
    return isOwner &&
      decision === RESOLUTION_FULL_REFUND &&
      requestData.status === BORROW_STATUS_COMPLETED;
  }
  if (decision === RESOLUTION_FULL_REFUND) {
    return isOwner &&
      requestData.status === BORROW_STATUS_COMPLETED &&
      requestData.depositDecision === DEPOSIT_DECISION_RETURN_DEPOSIT;
  }
  if (decision === RESOLUTION_PARTIAL_DEDUCTION) {
    return isBorrower &&
      requestData.status === BORROW_STATUS_COMPLETED &&
      requestData.minorIssueBorrowerDecision === MINOR_ISSUE_ACCEPTED &&
      requestData.depositDecision === DEPOSIT_DECISION_PARTIAL_DEDUCTION &&
      Math.round(toMoneyNumber(requestData.minorDeductionAmount) * 100) ===
        Math.round(deductionAmount * 100);
  }
  return false;
}

// Marketplace deposit resolution: stores who made the damage decision and what deduction type was approved.
function damageDecisionFor(decision: string, isAdmin: boolean): string {
  if (decision === RESOLUTION_FULL_REFUND) {
    return isAdmin ? DAMAGE_DECISION_ADMIN_FULL_REFUND : DAMAGE_DECISION_NONE;
  }
  if (decision === RESOLUTION_PARTIAL_DEDUCTION) {
    return isAdmin ?
      DAMAGE_DECISION_ADMIN_PARTIAL_DEDUCTION :
      DAMAGE_DECISION_BORROWER_ACCEPTED;
  }
  return DAMAGE_DECISION_ADMIN_FULL_DEDUCTION;
}

// Marketplace deposit resolution: converts an admin decision into the borrow request deposit status.
function depositStatusFor(decision: string): string {
  if (decision === RESOLUTION_FULL_REFUND) return DEPOSIT_STATUS_REFUNDED;
  if (decision === RESOLUTION_PARTIAL_DEDUCTION) {
    return DEPOSIT_STATUS_PARTIALLY_REFUNDED;
  }
  return DEPOSIT_STATUS_DEDUCTED;
}

// Callable API: resolves a completed Stripe marketplace deposit by refunding the borrower and/or paying the lender.
export const resolveMarketplaceDeposit = onCall(
  {secrets: [stripeSecret]},
  async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const borrowRequestId = readString(input, "borrowRequestId");
  const decision = readString(input, "decision");
  const reason = readString(input, "reason");
  const requestedDeductionAmount = readNumber(input, "damageDeductionAmount");
  const reportId = readString(input, "reportId");
  if (!borrowRequestId) {
    throw new HttpsError("invalid-argument", "Missing borrow request id.");
  }

  const db = admin.firestore();
  const requestRef = db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId);
  const requestSnapshot = await requestRef.get();
  const requestData = requestSnapshot.data();
  if (!requestData) {
    throw new HttpsError("not-found", "Borrow request was not found.");
  }

  const adminCaller = await isAdminUser(db, uid);
  if (!adminCaller && !resolutionAllowedForParticipant(
    requestData,
    uid,
    decision,
    requestedDeductionAmount,
  )) {
    throw new HttpsError(
      "permission-denied",
      "You cannot resolve this marketplace deposit.",
    );
  }

  if (requestData.paymentStatus !== BORROW_PAYMENT_STATUS_COMPLETED ||
      requestData.paymentProvider !== STRIPE_PROVIDER) {
    throw new HttpsError(
      "failed-precondition",
      "Stripe payment must be completed before resolving deposit.",
    );
  }
  const paymentIntentId = typeof requestData.stripePaymentIntentId === "string" ?
    requestData.stripePaymentIntentId :
    "";
  if (!paymentIntentId) {
    throw new HttpsError("failed-precondition", "Missing Stripe payment intent.");
  }

  const depositAmount = Math.max(0, toMoneyNumber(requestData.depositAmount));
  const usageFeeAmount = Math.max(0, toMoneyNumber(requestData.usageFeeAmount));
  if (depositAmount <= 0) {
    const noDepositUpdate = {
      depositStatus: DEPOSIT_STATUS_NOT_REQUIRED,
      depositHeldAmount: 0,
      depositRefundAmount: 0,
      damageDeductionAmount: 0,
      damageDecision: DAMAGE_DECISION_NONE,
      damageDecisionReason: "",
      refundStatus: REFUND_STATUS_NOT_REQUIRED,
      lenderBaseEarning: usageFeeAmount,
      lenderDamageEarning: 0,
      lenderTotalEarning: usageFeeAmount,
      manualPayoutStatus: MANUAL_PAYOUT_PENDING_MANUAL,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await requestRef.set(noDepositUpdate, {merge: true});
    let transferResult = {transferred: false, transferId: "", reason: ""};
    try {
      transferResult = await createStripeLenderTransferIfReady(
        db,
        borrowRequestId,
        {...requestData, ...noDepositUpdate},
        uid,
      );
    } catch (error) {
      await requestRef.set({
        stripeTransferStatus: STRIPE_TRANSFER_STATUS_FAILED,
        stripeTransferFailureReason: safeErrorMessage(error),
        manualPayoutStatus: MANUAL_PAYOUT_PENDING_MANUAL,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      transferResult = {
        transferred: false,
        transferId: "",
        reason: "transfer_failed",
      };
    }
    return {
      success: true,
      refundAmount: 0,
      stripeTransferId: transferResult.transferId,
      stripeTransferStatus: transferResult.transferred ?
        STRIPE_TRANSFER_STATUS_PAID :
        STRIPE_TRANSFER_STATUS_PENDING,
      payoutMode: transferResult.transferred ? "stripe_connect" : "manual",
    };
  }

  const currentDepositStatus = typeof requestData.depositStatus === "string" ?
    requestData.depositStatus :
    DEPOSIT_STATUS_HELD;
  if ([
    DEPOSIT_STATUS_REFUNDED,
    DEPOSIT_STATUS_PARTIALLY_REFUNDED,
    DEPOSIT_STATUS_DEDUCTED,
  ].includes(currentDepositStatus)) {
    throw new HttpsError("already-exists", "Deposit is already resolved.");
  }

  const deductionAmount = decision === RESOLUTION_FULL_DEDUCTION ?
    depositAmount :
    requestedDeductionAmount;
  assertDepositResolutionInput(decision, depositAmount, deductionAmount);

  const refundAmount = Math.max(0, depositAmount - deductionAmount);
  const lenderDamageEarning = deductionAmount;
  const lenderTotalEarning = usageFeeAmount + lenderDamageEarning;
  const now = admin.firestore.FieldValue.serverTimestamp();
  let stripeRefundId = "";
  let refundStatus = refundAmount > 0 ?
    REFUND_STATUS_PENDING :
    REFUND_STATUS_NOT_REQUIRED;

  // Marketplace deposit resolution: refund the borrower portion first, then unblock lender payout after refund succeeds.
  if (refundAmount > 0) {
    await requestRef.set({
      refundStatus: REFUND_STATUS_PENDING,
      manualPayoutStatus: MANUAL_PAYOUT_BLOCKED,
      updatedAt: now,
    }, {merge: true});
    try {
      const refund = await stripe().refunds.create({
        payment_intent: paymentIntentId,
        amount: moneyToMinorUnits(refundAmount),
        metadata: {
          borrowRequestId,
          refundType: "marketplace_deposit",
          decision,
        },
      });
      stripeRefundId = refund.id;
      if (refund.status === "succeeded") {
        refundStatus = REFUND_STATUS_SUCCEEDED;
      }
    } catch (error) {
      await requestRef.set({
        depositStatus: DEPOSIT_STATUS_REFUND_FAILED,
        refundStatus: REFUND_STATUS_FAILED,
        refundFailureReason: safeErrorMessage(error),
        manualPayoutStatus: MANUAL_PAYOUT_BLOCKED,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      throw new HttpsError(
        "internal",
        "Stripe refund failed. The deposit remains blocked for admin review.",
      );
    }
  }

  const update: Record<string, unknown> = {
    status: BORROW_STATUS_COMPLETED,
    depositStatus: depositStatusFor(decision),
    depositHeldAmount: depositAmount,
    depositRefundAmount: refundAmount,
    damageDeductionAmount: deductionAmount,
    damageDecision: damageDecisionFor(decision, adminCaller),
    damageDecisionReason: reason,
    damageDecidedAt: now,
    refundStatus: refundAmount > 0 ?
      refundStatus :
      REFUND_STATUS_NOT_REQUIRED,
    refundFailureReason: "",
    lenderBaseEarning: usageFeeAmount,
    lenderDamageEarning,
    lenderTotalEarning,
    manualPayoutStatus: refundStatus === REFUND_STATUS_PENDING ?
      MANUAL_PAYOUT_BLOCKED :
      MANUAL_PAYOUT_PENDING_MANUAL,
    updatedAt: now,
  };
  if (refundAmount > 0 && refundStatus === REFUND_STATUS_SUCCEEDED) {
    update.depositRefundedAt = now;
    update.stripeRefundId = stripeRefundId;
  } else if (refundAmount > 0) {
    update.stripeRefundId = stripeRefundId;
  } else {
    update.stripeRefundId = "";
  }
  if (adminCaller) {
    update.adminResolvedAt = now;
    update.adminResolvedBy = uid;
    update.adminResolutionReason = reason;
    update.adminResolution = decision === RESOLUTION_FULL_REFUND ?
      ADMIN_RESOLUTION_FOR_BORROWER :
      ADMIN_RESOLUTION_FOR_LENDER;
    update.depositDecision = decision === RESOLUTION_FULL_REFUND ?
      DEPOSIT_DECISION_RETURN_DEPOSIT :
      decision === RESOLUTION_PARTIAL_DEDUCTION ?
        DEPOSIT_DECISION_PARTIAL_DEDUCTION :
        DEPOSIT_DECISION_WITHHOLD_DEPOSIT;
    update.depositDecisionReason = reason;
    update.depositDecidedAt = now;
    update.returnConfirmedAt = requestData.returnConfirmedAt ?? now;
    update.completedAt = requestData.completedAt ?? now;
  }

  const batch = db.batch();
  batch.set(requestRef, update, {merge: true});
  if (reportId) {
    batch.set(db.collection(REPORTS_COLLECTION).doc(reportId), {
      status: "resolved",
      adminResolution: update.adminResolution ?? "",
      adminResolutionReason: reason,
      adminResolvedAt: now,
      adminResolvedBy: uid,
      updatedAt: now,
    }, {merge: true});
  }
  await batch.commit();
  let transferResult = {transferred: false, transferId: "", reason: ""};
  // Marketplace deposit payout: try automatic Stripe Connect transfer; fall back to manual admin payout if unavailable.
  if (update.manualPayoutStatus === MANUAL_PAYOUT_PENDING_MANUAL) {
    try {
      transferResult = await createStripeLenderTransferIfReady(
        db,
        borrowRequestId,
        {...requestData, ...update, lenderTotalEarning},
        uid,
      );
    } catch (error) {
      await requestRef.set({
        stripeTransferStatus: STRIPE_TRANSFER_STATUS_FAILED,
        stripeTransferFailureReason: safeErrorMessage(error),
        manualPayoutStatus: MANUAL_PAYOUT_PENDING_MANUAL,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      transferResult = {
        transferred: false,
        transferId: "",
        reason: "transfer_failed",
      };
    }
  }
  const itemTitle = typeof requestData.itemTitle === "string" &&
    requestData.itemTitle.trim() ?
    requestData.itemTitle.trim() :
    "your marketplace item";
  const borrowerId = typeof requestData.borrowerId === "string" ?
    requestData.borrowerId :
    "";
  const ownerId = typeof requestData.ownerId === "string" ?
    requestData.ownerId :
    "";
  const bodies = depositDecisionNotificationBodies(
    decision,
    itemTitle,
    depositAmount,
    deductionAmount,
    refundAmount,
    reason,
  );
  // Marketplace notifications: inform both borrower and lender exactly how admin resolved the deposit.
  await Promise.all([
    createInAppNotification(db, {
      userId: borrowerId,
      actorId: uid,
      type: NOTIFICATION_TYPE_BORROW_DEPOSIT_RESOLVED,
      title: "Deposit decision updated",
      body: bodies.borrower,
      category: "Marketplace",
      borrowRequestId,
      notificationId: notificationIdFor(
        "borrowDepositResolved",
        borrowRequestId,
        borrowerId,
      ),
    }),
    createInAppNotification(db, {
      userId: ownerId,
      actorId: uid,
      type: NOTIFICATION_TYPE_BORROW_DEPOSIT_RESOLVED,
      title: "Deposit decision updated",
      body: bodies.lender,
      category: "Marketplace",
      borrowRequestId,
      notificationId: notificationIdFor(
        "borrowDepositResolved",
        borrowRequestId,
        ownerId,
      ),
    }),
    update.manualPayoutStatus === MANUAL_PAYOUT_PENDING_MANUAL &&
      !transferResult.transferred ?
      notifyManualPayoutReady(db, borrowRequestId, {
        ownerId,
        itemTitle,
        lenderTotalEarning,
      }, uid) :
      Promise.resolve(),
  ]);
  return {
    success: true,
    refundAmount,
    stripeRefundId,
    stripeTransferId: transferResult.transferId,
    stripeTransferStatus: transferResult.transferred ?
      STRIPE_TRANSFER_STATUS_PAID :
      (update.manualPayoutStatus === MANUAL_PAYOUT_PENDING_MANUAL ?
        STRIPE_TRANSFER_STATUS_PENDING :
        STRIPE_TRANSFER_STATUS_NOT_READY),
    payoutMode: transferResult.transferred ? "stripe_connect" : "manual",
  };
});

// Callable API: lets admin mark a manual lender payout as paid when the lender collects it outside Stripe.
export const markManualPayoutPaid = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const borrowRequestId = readString(input, "borrowRequestId");
  const manualPayoutReference = readString(input, "manualPayoutReference");
  const manualPayoutNote = readString(input, "manualPayoutNote");
  if (!borrowRequestId) {
    throw new HttpsError("invalid-argument", "Missing borrow request id.");
  }
  const db = admin.firestore();
  await requireAdmin(db, uid);

  const requestRef = db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId);
  const snapshot = await requestRef.get();
  const data = snapshot.data();
  if (!data) {
    throw new HttpsError("not-found", "Borrow request was not found.");
  }
  if (data.manualPayoutStatus !== MANUAL_PAYOUT_PENDING_MANUAL) {
    throw new HttpsError(
      "failed-precondition",
      "Manual payout is not ready to be marked paid.",
    );
  }
  if (toMoneyNumber(data.lenderTotalEarning) < 0) {
    throw new HttpsError("failed-precondition", "Invalid payout amount.");
  }

  await requestRef.set({
    manualPayoutStatus: MANUAL_PAYOUT_PAID,
    manualPayoutMarkedAt: admin.firestore.FieldValue.serverTimestamp(),
    manualPayoutMarkedBy: uid,
    manualPayoutReference,
    manualPayoutNote,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  const ownerId = typeof data.ownerId === "string" ? data.ownerId : "";
  const itemTitle = typeof data.itemTitle === "string" && data.itemTitle.trim() ?
    data.itemTitle.trim() :
    "your marketplace item";
  const payoutAmount = moneyLabel(Math.max(0, toMoneyNumber(data.lenderTotalEarning)));
  const referenceText = manualPayoutReference ?
    ` Reference: ${manualPayoutReference}.` :
    "";
  await createInAppNotification(db, {
    userId: ownerId,
    actorId: uid,
    type: NOTIFICATION_TYPE_BORROW_PAYOUT_PAID,
    title: "Manual payout marked paid",
    body: `Admin marked your ${payoutAmount} payout for "${itemTitle}" as paid.${referenceText}`,
    category: "Marketplace",
    borrowRequestId,
    notificationId: notificationIdFor(
      "borrowPayoutPaid",
      borrowRequestId,
      ownerId,
    ),
  });
  return {success: true};
});

// Marketplace deposit trigger helper: marks held Stripe deposits as disputed when a completed request becomes disputed.
export async function markMarketplaceDepositDisputedIfNeeded(
  db: admin.firestore.Firestore,
  borrowRequestId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): Promise<void> {
  if (!after || before?.status === BORROW_STATUS_DISPUTED) return;
  if (after.status !== BORROW_STATUS_DISPUTED) return;
  if (
    after.paymentProvider !== STRIPE_PROVIDER ||
    after.paymentStatus !== BORROW_PAYMENT_STATUS_COMPLETED
  ) {
    return;
  }

  const depositAmount = Math.max(0, toMoneyNumber(after.depositAmount));
  if (depositAmount <= 0) return;
  const depositStatus = typeof after.depositStatus === "string" ?
    after.depositStatus :
    DEPOSIT_STATUS_HELD;
  if ([
    DEPOSIT_STATUS_REFUNDED,
    DEPOSIT_STATUS_PARTIALLY_REFUNDED,
    DEPOSIT_STATUS_DEDUCTED,
  ].includes(depositStatus)) {
    return;
  }

  await db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId).set({
    depositStatus: DEPOSIT_STATUS_DISPUTED,
    refundStatus: REFUND_STATUS_NOT_STARTED,
    manualPayoutStatus: MANUAL_PAYOUT_BLOCKED,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

// Stripe webhook: updates borrowRequests after payment success, failure, or cancellation.
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
    if (typeof payment.stripeChargeId === "string" && payment.stripeChargeId) {
      update.stripeChargeId = payment.stripeChargeId;
    }
    update.chatId = marketplaceChatId(
      String(payment.payerId ?? ""),
      String(payment.receiverId ?? ""),
    );
    const depositAmount = Math.max(0, toMoneyNumber(payment.depositAmount));
    const usageFeeAmount = Math.max(0, toMoneyNumber(payment.usageFeeAmount));
    const hasDeposit = depositAmount > 0;
    update.depositStatus = hasDeposit ?
      DEPOSIT_STATUS_HELD :
      DEPOSIT_STATUS_NOT_REQUIRED;
    update.depositHeldAmount = hasDeposit ? depositAmount : 0;
    update.depositRefundAmount = 0;
    update.damageDeductionAmount = 0;
    update.damageDecision = DAMAGE_DECISION_NONE;
    update.damageDecisionReason = "";
    update.stripeRefundId = "";
    update.refundStatus = hasDeposit ?
      REFUND_STATUS_NOT_STARTED :
      REFUND_STATUS_NOT_REQUIRED;
    update.refundFailureReason = "";
    update.lenderBaseEarning = usageFeeAmount;
    update.lenderDamageEarning = 0;
    update.lenderTotalEarning = usageFeeAmount;
    update.manualPayoutStatus = MANUAL_PAYOUT_NOT_READY;
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

// Stripe webhook: updates payments/{paymentId} from PaymentIntent events and then syncs the borrow request.
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
  const latestCharge = intent.latest_charge;
  const stripeChargeId = typeof latestCharge === "string" ?
    latestCharge :
    latestCharge?.id ?? "";
  const update: Record<string, unknown> = {
    id: paymentId,
    status,
    stripePaymentIntentId: intent.id,
    lastStripeEventAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (stripeChargeId) {
    update.stripeChargeId = stripeChargeId;
  }
  await paymentRef.set(update, {merge: true});
  const latest = await paymentRef.get();
  const payment = latest.data();
  if (!payment) return;
  await updateMarketplaceBorrowRequest({...payment, id: paymentId}, status);
}

// Stripe webhook: updates borrower refund status and starts lender payout once the refund is final.
async function updateRefundFromStripe(refund: Stripe.Refund): Promise<void> {
  const borrowRequestId = refund.metadata?.borrowRequestId;
  if (!borrowRequestId) {
    logger.warn("Stripe refund missing borrowRequestId metadata", {
      refundId: refund.id,
    });
    return;
  }

  const update: Record<string, unknown> = {
    stripeRefundId: refund.id,
    lastStripeRefundEventAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (refund.status === "succeeded") {
    update.refundStatus = REFUND_STATUS_SUCCEEDED;
    update.depositRefundedAt = admin.firestore.FieldValue.serverTimestamp();
    update.manualPayoutStatus = MANUAL_PAYOUT_PENDING_MANUAL;
    update.refundFailureReason = "";
  } else if (refund.status === "failed" || refund.status === "canceled") {
    update.refundStatus = REFUND_STATUS_FAILED;
    update.depositStatus = DEPOSIT_STATUS_REFUND_FAILED;
    update.manualPayoutStatus = MANUAL_PAYOUT_BLOCKED;
    update.refundFailureReason = refund.failure_reason ??
      "Stripe refund did not complete.";
  } else {
    update.refundStatus = REFUND_STATUS_PENDING;
    update.manualPayoutStatus = MANUAL_PAYOUT_BLOCKED;
  }

  const db = admin.firestore();
  const requestRef = db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId);
  await requestRef.set(update, {merge: true});
  if (update.manualPayoutStatus === MANUAL_PAYOUT_PENDING_MANUAL) {
    const latest = await requestRef.get();
    const requestData = latest.data();
    if (requestData) {
      let transferResult = {transferred: false, transferId: "", reason: ""};
      try {
        transferResult = await createStripeLenderTransferIfReady(
          db,
          borrowRequestId,
          requestData,
          "stripeWebhook",
        );
      } catch (error) {
        await requestRef.set({
          stripeTransferStatus: STRIPE_TRANSFER_STATUS_FAILED,
          stripeTransferFailureReason: safeErrorMessage(error),
          manualPayoutStatus: MANUAL_PAYOUT_PENDING_MANUAL,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        transferResult = {
          transferred: false,
          transferId: "",
          reason: "transfer_failed",
        };
      }
      if (!transferResult.transferred) {
        await notifyManualPayoutReady(
          db,
          borrowRequestId,
          requestData,
          "stripeWebhook",
        );
      }
    }
  }
}

// Stripe webhook: handles charge.refunded by forwarding each marketplace refund into the normal refund updater.
async function updateRefundsFromCharge(charge: Stripe.Charge): Promise<void> {
  const refunds = charge.refunds?.data ?? [];
  for (const refund of refunds) {
    if (refund.metadata?.borrowRequestId) {
      await updateRefundFromStripe(refund);
    }
  }
}

// Stripe webhook: records automatic lender transfer status on the borrow request.
async function updateTransferFromStripe(transfer: Stripe.Transfer): Promise<void> {
  const borrowRequestId = transfer.metadata?.borrowRequestId;
  if (!borrowRequestId) {
    logger.warn("Stripe transfer missing borrowRequestId metadata", {
      transferId: transfer.id,
    });
    return;
  }

  await admin.firestore()
    .collection(BORROW_REQUESTS_COLLECTION)
    .doc(borrowRequestId)
    .set({
      stripeTransferId: transfer.id,
      stripeTransferDestinationAccountId:
        typeof transfer.destination === "string" ? transfer.destination : "",
      stripeTransferAmount: transfer.amount / 100,
      stripeTransferStatus: transfer.reversed ?
        STRIPE_TRANSFER_STATUS_FAILED :
        STRIPE_TRANSFER_STATUS_PAID,
      stripeTransferUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      manualPayoutStatus: transfer.reversed ?
        MANUAL_PAYOUT_PENDING_MANUAL :
        MANUAL_PAYOUT_PAID,
      manualPayoutReference: transfer.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
}

// Stripe webhook: keeps users/{uid} Connect capability fields current when Stripe updates an Express account.
async function updateConnectAccountFromStripe(account: Stripe.Account): Promise<void> {
  const uid = account.metadata?.firebaseUid;
  if (!uid) return;
  await syncConnectAccountStatus(admin.firestore(), uid, account.id);
}

// HTTP API: verifies Stripe webhook signatures and applies final payment/refund/transfer/account updates server-side.
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
    case "refund.created":
    case "refund.updated":
    case "refund.failed":
      await updateRefundFromStripe(event.data.object as Stripe.Refund);
      break;
    case "charge.refunded":
      await updateRefundsFromCharge(event.data.object as Stripe.Charge);
      break;
    case "transfer.created":
    case "transfer.updated":
    case "transfer.reversed":
      await updateTransferFromStripe(event.data.object as Stripe.Transfer);
      break;
    case "account.updated":
      await updateConnectAccountFromStripe(event.data.object as Stripe.Account);
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
