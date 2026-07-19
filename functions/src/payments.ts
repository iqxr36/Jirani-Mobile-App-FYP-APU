// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : payments.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,02-July-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import {createHash, randomInt} from "crypto";
import {logger} from "firebase-functions";
import {defineSecret, defineString} from "firebase-functions/params";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {createInAppNotification} from "./notifications";

type DocumentData = admin.firestore.DocumentData;

const PAYMENTS_COLLECTION = "payments";
const USERS_COLLECTION = "users";
const ADMINS_COLLECTION = "admins";
const BORROW_REQUESTS_COLLECTION = "borrowRequests";
const SERVICE_REQUESTS_COLLECTION = "serviceRequests";
const SERVICES_COLLECTION = "services";
const REPORTS_COLLECTION = "reports";
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
const BORROW_STATUS_COMPLETED = "completed";
const BORROW_STATUS_DISPUTED = "disputed";
const SERVICE_STATUS_ACCEPTED_AWAITING_PAYMENT = "acceptedAwaitingPayment";
const SERVICE_STATUS_PAID_HELD = "paidHeld";
const SERVICE_STATUS_IN_PROGRESS = "inProgress";
const SERVICE_STATUS_COMPLETED_PAYOUT_PENDING = "completedPayoutPending";
const SERVICE_STATUS_COMPLETED_PAYOUT_SENT = "completedPayoutSent";
const SERVICE_STATUS_DISPUTED = "disputed";
const SERVICE_STATUS_REFUNDED = "refunded";
const SERVICE_STATUS_PAYMENT_FAILED = "paymentFailed";
const SERVICE_PAYOUT_NOT_STARTED = "notStarted";
const SERVICE_PAYOUT_PENDING = "pending";
const SERVICE_PAYOUT_SENT = "sent";
const SERVICE_PAYOUT_FAILED = "failed";
const SERVICE_PAYOUT_BLOCKED = "blocked";
const PAYOUT_ACCOUNT_VERIFIED = "verified";
const XENDIT_PROVIDER = "xendit";
const ROLE_COMMUNITY_ADMIN = "communityAdmin";
const ROLE_SYSTEM_ADMIN = "systemAdmin";
const DEFAULT_CURRENCY = "myr";
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
const RESOLUTION_FULL_REFUND = "full_refund";
const RESOLUTION_PARTIAL_DEDUCTION = "partial_deduction";
const RESOLUTION_FULL_DEDUCTION = "full_deduction";
const MINOR_ISSUE_ACCEPTED = "accepted";
const DEPOSIT_DECISION_RETURN_DEPOSIT = "returnDeposit";
const DEPOSIT_DECISION_PARTIAL_DEDUCTION = "partialDeduction";
const DEPOSIT_DECISION_WITHHOLD_DEPOSIT = "withholdDeposit";
const ADMIN_RESOLUTION_FOR_BORROWER = "resolveForBorrower";
const ADMIN_RESOLUTION_FOR_LENDER = "resolveForLender";
const NOTIFICATION_TYPE_BORROW_DEPOSIT_RESOLVED = "borrowDepositResolved";
const NOTIFICATION_TYPE_BORROW_PAYOUT_READY = "borrowPayoutReady";
const NOTIFICATION_TYPE_BORROW_PAYOUT_PAID = "borrowPayoutPaid";
const NOTIFICATION_TYPE_SERVICE_PAYMENT_RECEIVED = "servicePaymentReceived";
const NOTIFICATION_TYPE_SERVICE_ARRIVAL_VERIFIED = "serviceArrivalVerified";
const NOTIFICATION_TYPE_SERVICE_COMPLETED = "serviceCompleted";
const NOTIFICATION_TYPE_SERVICE_DISPUTED = "serviceDisputed";
const REPORT_TYPE_SERVICE_DISPUTE = "serviceDispute";
const REPORT_STATUS_OPEN = "open";
const REPORT_STATUS_UNDER_REVIEW = "underReview";
const REPORT_STATUS_RESOLVED = "resolved";
const NOTIFICATION_TYPE_SERVICE_PAYOUT_SENT = "servicePayoutSent";
const NOTIFICATION_TYPE_SERVICE_PAYOUT_FAILED = "servicePayoutFailed";
const NOTIFICATION_TYPE_SERVICE_REFUNDED = "serviceRefunded";
const NOTIFICATION_TYPE_SERVICE_ADMIN_RESOLVED = "serviceAdminResolved";
const ALLOWED_TEST_PAYOUT_CHANNELS = new Set([
  "MY_MAYBANK",
  "MY_CIMB",
  "MY_PUBLIC_BANK",
  "MY_HLB",
  "MY_RHB",
  "MY_TNG",
]);
const SERVICE_DISPUTE_TYPE_INCOMPLETE = "incomplete";
const SERVICE_DISPUTE_TYPE_POOR_QUALITY = "poorQuality";
const SERVICE_DISPUTE_TYPE_NO_SHOW = "noShow";
const SERVICE_DISPUTE_TYPE_SCOPE_MISMATCH = "scopeMismatch";
const SERVICE_DISPUTE_TYPE_SAFETY_CONCERN = "safetyConcern";
const SERVICE_DISPUTE_TYPE_OTHER = "other";
const ALLOWED_SERVICE_DISPUTE_TYPES = new Set([
  SERVICE_DISPUTE_TYPE_INCOMPLETE,
  SERVICE_DISPUTE_TYPE_POOR_QUALITY,
  SERVICE_DISPUTE_TYPE_NO_SHOW,
  SERVICE_DISPUTE_TYPE_SCOPE_MISMATCH,
  SERVICE_DISPUTE_TYPE_SAFETY_CONCERN,
  SERVICE_DISPUTE_TYPE_OTHER,
]);
const SETTLEMENT_MODE_SIMULATED = "simulated";
const SETTLEMENT_MODE_LIVE = "live";
const RESOLVED_DEPOSIT_STATUSES = new Set([
  DEPOSIT_STATUS_REFUNDED,
  DEPOSIT_STATUS_PARTIALLY_REFUNDED,
  DEPOSIT_STATUS_DEDUCTED,
]);

const xenditSecret = defineSecret("XENDIT_SECRET_KEY");
const xenditWebhookToken = defineSecret("XENDIT_WEBHOOK_TOKEN");
const paymentSettlementMode = defineString("PAYMENT_SETTLEMENT_MODE", {
  default: SETTLEMENT_MODE_SIMULATED,
});

function isSimulatedSettlement(): boolean {
  const mode = (process.env.PAYMENT_SETTLEMENT_MODE ??
    paymentSettlementMode.value() ??
    SETTLEMENT_MODE_SIMULATED).toLowerCase();
  return mode !== SETTLEMENT_MODE_LIVE;
}

function currentSettlementMode(): string {
  return isSimulatedSettlement() ? SETTLEMENT_MODE_SIMULATED : SETTLEMENT_MODE_LIVE;
}

function manualPayoutStatusAfterDepositDecision(refundFailed: boolean): string {
  return refundFailed ? MANUAL_PAYOUT_BLOCKED : MANUAL_PAYOUT_PENDING_MANUAL;
}

function xenditRefundStatusToAppStatus(status: string): string {
  const normalized = status.toUpperCase();
  if (["SUCCEEDED", "SUCCESSFUL", "COMPLETED", "SUCCESS"].includes(normalized)) {
    return REFUND_STATUS_SUCCEEDED;
  }
  if (["FAILED", "CANCELED", "CANCELLED", "EXPIRED"].includes(normalized)) {
    return REFUND_STATUS_FAILED;
  }
  return REFUND_STATUS_PENDING;
}

function requireUid(auth: {uid?: string} | undefined): string {
  const uid = auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in first.");
  return uid;
}

function asRecord(data: unknown): Record<string, unknown> {
  return data && typeof data === "object" ? data as Record<string, unknown> : {};
}

function readString(data: Record<string, unknown>, key: string, fallback = ""): string {
  const value = data[key];
  return typeof value === "string" ? value.trim() : fallback;
}

function readStringList(data: Record<string, unknown>, key: string): string[] {
  const value = data[key];
  if (!Array.isArray(value)) return [];
  return value
    .filter((entry): entry is string => typeof entry === "string")
    .map((entry) => entry.trim())
    .filter((entry) => entry.length > 0)
    .slice(0, 5);
}

function readNumber(data: Record<string, unknown>, key: string): number {
  const value = data[key];
  if (value === undefined || value === null) return 0;
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new HttpsError("invalid-argument", `${key} must be a number.`);
  }
  return value;
}

function maskPayoutIdentifier(value: string): string {
  const normalized = value.replace(/\s+/g, "");
  if (normalized.length <= 4) return normalized;
  return `•••• ${normalized.slice(-4)}`;
}

function toMoneyNumber(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function moneyToXenditAmount(value: number): number {
  return Math.max(0, Math.round(value * 100) / 100);
}

function moneyToMinorUnits(value: number): number {
  return Math.round(Math.max(0, value) * 100);
}

function expectedHourlyServiceAmountMinor(hourlyRate: number, durationHours: number): number {
  return moneyToMinorUnits(hourlyRate * durationHours);
}

function expectedMarketplaceAmount(data: DocumentData): number {
  const usageFee = Math.max(0, toMoneyNumber(data.usageFeeAmount));
  const deposit = Math.max(0, toMoneyNumber(data.depositAmount));
  return Math.round((usageFee + deposit) * 100);
}

function marketplaceChatId(borrowerId: string, ownerId: string): string {
  return [borrowerId, ownerId].sort().join("_");
}

function moneyLabel(value: number): string {
  return `RM ${value.toFixed(2)}`;
}

function serviceAmountMinor(data: DocumentData): number {
  return moneyToMinorUnits(toMoneyNumber(data.amount));
}

function serviceCodeHash(requestId: string, purpose: string, code: string): string {
  return createHash("sha256").update(`${requestId}:${purpose}:${code}`).digest("hex");
}

function generateFourDigitCode(): string {
  return randomInt(0, 10000).toString().padStart(4, "0");
}

function codeExpiry(minutes = 15): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(Date.now() + minutes * 60 * 1000);
}

function timestampExpired(value: unknown): boolean {
  if (!value || typeof (value as {toMillis?: unknown}).toMillis !== "function") return true;
  return (value as admin.firestore.Timestamp).toMillis() < Date.now();
}

function assertFourDigitCode(code: string): void {
  if (!/^\d{4}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Enter the 4-digit verification code.");
  }
}

function assertServiceDisputeInput(disputeType: string, details: string): void {
  if (!ALLOWED_SERVICE_DISPUTE_TYPES.has(disputeType)) {
    throw new HttpsError("invalid-argument", "Choose a valid dispute type.");
  }
  if (disputeType === SERVICE_DISPUTE_TYPE_OTHER && !details.trim()) {
    throw new HttpsError("invalid-argument", "Please describe the issue when choosing Other.");
  }
}

function serviceDisputeNotificationBody(disputeType: string, details: string): string {
  const labels: Record<string, string> = {
    [SERVICE_DISPUTE_TYPE_INCOMPLETE]: "Service not performed or incomplete",
    [SERVICE_DISPUTE_TYPE_POOR_QUALITY]: "Poor quality or unsatisfactory work",
    [SERVICE_DISPUTE_TYPE_NO_SHOW]: "Provider late or did not show up",
    [SERVICE_DISPUTE_TYPE_SCOPE_MISMATCH]: "Work not as agreed",
    [SERVICE_DISPUTE_TYPE_SAFETY_CONCERN]: "Damage, mess, or safety concern",
    [SERVICE_DISPUTE_TYPE_OTHER]: "Other issue",
  };
  const label = labels[disputeType] ?? "Service dispute";
  const trimmed = details.trim();
  return trimmed ? `${label}: ${trimmed}` : label;
}

async function getServiceDisputeReport(
  db: admin.firestore.Firestore,
  reportId: string,
): Promise<{ref: admin.firestore.DocumentReference; data: DocumentData}> {
  const ref = db.collection(REPORTS_COLLECTION).doc(reportId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Dispute report not found.");
  }
  return {ref, data: snap.data() ?? {}};
}

async function assertServiceDisputeReadyForAdminResolution(
  db: admin.firestore.Firestore,
  data: DocumentData,
): Promise<void> {
  const reportId = typeof data.disputeReportId === "string" ? data.disputeReportId.trim() : "";
  if (!reportId) return;
  const {data: reportData} = await getServiceDisputeReport(db, reportId);
  const status = String(reportData.status ?? "");
  if (status !== REPORT_STATUS_UNDER_REVIEW) {
    throw new HttpsError(
      "failed-precondition",
      "Open the dispute in Reports and mark it under review before refunding or paying out.",
    );
  }
}

async function resolveServiceDisputeReport(
  db: admin.firestore.Firestore,
  reportId: string,
  adminUid: string,
  resolution: string,
  reason: string,
): Promise<void> {
  const trimmedReportId = reportId.trim();
  if (!trimmedReportId) return;
  await db.collection(REPORTS_COLLECTION).doc(trimmedReportId).set({
    status: REPORT_STATUS_RESOLVED,
    adminResolution: resolution,
    adminResolutionReason: reason.trim(),
    adminResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    adminResolvedBy: adminUid,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

async function loadResidentCommunity(
  db: admin.firestore.Firestore,
  userId: string,
): Promise<{communityId: string; communityName: string}> {
  const snap = await db.collection(USERS_COLLECTION).doc(userId).get();
  const data = snap.data() ?? {};
  return {
    communityId: typeof data.communityId === "string" ? data.communityId : "",
    communityName: typeof data.communityName === "string" ? data.communityName : "",
  };
}

function safeErrorMessage(error: unknown): string {
  if (error instanceof Error && error.message.trim()) {
    return error.message.trim().slice(0, 500);
  }
  return "Payment provider request failed.";
}

function notificationIdFor(...parts: string[]): string {
  return parts.join("_").replace(/\//g, "_");
}

async function xenditPost(
  path: string,
  body: Record<string, unknown>,
  extraHeaders: Record<string, string> = {},
): Promise<Record<string, unknown>> {
  const secretKey = process.env.XENDIT_SECRET_KEY;
  if (!secretKey) {
    throw new HttpsError(
      "failed-precondition",
      "Xendit secret key is not configured.",
    );
  }
  const auth = Buffer.from(`${secretKey}:`).toString("base64");
  const response = await fetch(`https://api.xendit.co${path}`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${auth}`,
      "Content-Type": "application/json",
      ...extraHeaders,
    },
    body: JSON.stringify(body),
  });
  const rawText = await response.text();
  let parsed: unknown = {};
  if (rawText.trim()) {
    try {
      parsed = JSON.parse(rawText);
    } catch (_) {
      parsed = {message: rawText};
    }
  }
  const data = asRecord(parsed);
  if (!response.ok) {
    throw new Error(readString(data, "message", `Xendit request failed (${response.status}).`));
  }
  return data;
}

function verifyXenditWebhook(request: {header(name: string): string | undefined}): boolean {
  const expectedToken = process.env.XENDIT_WEBHOOK_TOKEN;
  if (!expectedToken) return false;
  return request.header("x-callback-token") === expectedToken;
}

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

async function requireAdmin(db: admin.firestore.Firestore, uid: string): Promise<void> {
  if (!await isAdminUser(db, uid)) {
    throw new HttpsError("permission-denied", "Admin access is required.");
  }
}

async function clearPendingMarketplacePayment(
  requestRef: admin.firestore.DocumentReference,
): Promise<void> {
  await requestRef.set({
    pendingPaymentId: admin.firestore.FieldValue.delete(),
    pendingXenditInvoiceId: admin.firestore.FieldValue.delete(),
    pendingXenditPaymentRequestId: admin.firestore.FieldValue.delete(),
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
  await pendingRef.update({
    status: PAYMENT_STATUS_CANCELLED,
    replacementReason: "new_payment_attempt",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await clearPendingMarketplacePayment(requestRef);
}

async function validateXenditMarketplacePayment(
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
  requestRef: admin.firestore.DocumentReference;
  requestData: DocumentData;
}> {
  const amountValue = input.amount;
  if (typeof amountValue !== "number" || !Number.isInteger(amountValue) || amountValue <= 0) {
    throw new HttpsError("invalid-argument", "amount must be a positive int.");
  }
  const currency = readString(input, "currency", DEFAULT_CURRENCY).toLowerCase();
  const relatedId = readString(input, "relatedId");
  const payerId = readString(input, "payerId");
  const receiverId = readString(input, "receiverId");
  const itemId = readString(input, "itemId");

  if (currency !== DEFAULT_CURRENCY) {
    throw new HttpsError("invalid-argument", "Unsupported currency.");
  }
  if (!relatedId || !payerId || !receiverId || !itemId) {
    throw new HttpsError("invalid-argument", "Missing marketplace payment data.");
  }
  if (payerId !== uid) {
    throw new HttpsError("permission-denied", "You cannot pay for another user.");
  }

  const requestRef = db.collection(BORROW_REQUESTS_COLLECTION).doc(relatedId);
  const requestSnapshot = await requestRef.get();
  const requestData = requestSnapshot.data();
  if (!requestData) throw new HttpsError("not-found", "Borrow request was not found.");
  if (requestData.borrowerId !== uid || requestData.borrowerId !== payerId) {
    throw new HttpsError("permission-denied", "Invalid payer for this request.");
  }
  if (requestData.ownerId !== receiverId || requestData.itemId !== itemId) {
    throw new HttpsError("invalid-argument", "Payment target does not match request.");
  }
  if (requestData.status !== BORROW_STATUS_APPROVED) {
    throw new HttpsError("failed-precondition", "Payment is available after owner approval.");
  }
  if (requestData.paymentStatus === BORROW_PAYMENT_STATUS_COMPLETED) {
    throw new HttpsError("already-exists", "This request is already paid.");
  }

  const expectedAmount = expectedMarketplaceAmount(requestData);
  if (expectedAmount <= 0) throw new HttpsError("failed-precondition", "No payment is required.");
  if (amountValue !== expectedAmount) {
    throw new HttpsError("invalid-argument", "Payment amount does not match request.");
  }

  return {
    amount: amountValue,
    currency,
    relatedId,
    payerId,
    receiverId,
    itemId,
    requestRef,
    requestData,
  };
}

async function validateXenditServicePayment(
  db: admin.firestore.Firestore,
  uid: string,
  input: Record<string, unknown>,
): Promise<{
  amount: number;
  currency: string;
  relatedId: string;
  payerId: string;
  receiverId: string;
  serviceId: string;
  requestRef: admin.firestore.DocumentReference;
  requestData: DocumentData;
  providerData: DocumentData;
}> {
  const amountValue = input.amount;
  if (typeof amountValue !== "number" || !Number.isInteger(amountValue) || amountValue <= 0) {
    throw new HttpsError("invalid-argument", "amount must be a positive int.");
  }
  const currency = readString(input, "currency", DEFAULT_CURRENCY).toLowerCase();
  const relatedId = readString(input, "relatedId");
  const payerId = readString(input, "payerId");
  const receiverId = readString(input, "receiverId");
  const serviceId = readString(input, "serviceId");

  if (currency !== DEFAULT_CURRENCY) throw new HttpsError("invalid-argument", "Unsupported currency.");
  if (!relatedId || !payerId || !receiverId || !serviceId) {
    throw new HttpsError("invalid-argument", "Missing service payment data.");
  }
  if (payerId !== uid) throw new HttpsError("permission-denied", "You cannot pay for another user.");

  const requestRef = db.collection(SERVICE_REQUESTS_COLLECTION).doc(relatedId);
  const requestSnapshot = await requestRef.get();
  const requestData = requestSnapshot.data();
  if (!requestData) throw new HttpsError("not-found", "Service request was not found.");
  if (requestData.requesterId !== uid || requestData.requesterId !== payerId) {
    throw new HttpsError("permission-denied", "Invalid payer for this service request.");
  }
  if (requestData.providerId !== receiverId || requestData.serviceId !== serviceId) {
    throw new HttpsError("invalid-argument", "Payment target does not match service request.");
  }
  if (requestData.status !== SERVICE_STATUS_ACCEPTED_AWAITING_PAYMENT) {
    throw new HttpsError("failed-precondition", "Payment is available after the provider accepts.");
  }
  if (requestData.paymentStatus === PAYMENT_STATUS_SUCCEEDED) {
    throw new HttpsError("already-exists", "This service request is already paid.");
  }
  const expectedAmount = serviceAmountMinor(requestData);
  if (expectedAmount <= 0) throw new HttpsError("failed-precondition", "No service payment is required.");
  if (amountValue !== expectedAmount) {
    throw new HttpsError("invalid-argument", "Payment amount does not match service request.");
  }

  const [serviceSnapshot, providerSnapshot] = await Promise.all([
    db.collection(SERVICES_COLLECTION).doc(serviceId).get(),
    db.collection(USERS_COLLECTION).doc(receiverId).get(),
  ]);
  const serviceData = serviceSnapshot.data();
  const providerData = providerSnapshot.data();
  if (!serviceData || serviceData.providerId !== receiverId) {
    throw new HttpsError("failed-precondition", "Service payment target is invalid.");
  }
  const pricingMode = readString(serviceData, "pricingMode");
  if (pricingMode === "hourly") {
    const durationHours = Number(requestData.durationHours ?? 0);
    const hourlyRate = toMoneyNumber(requestData.hourlyRate ?? serviceData.hourlyRate);
    if (!Number.isInteger(durationHours) || durationHours < 1 || durationHours > 12 || hourlyRate <= 0) {
      throw new HttpsError("failed-precondition", "Hourly service duration is invalid.");
    }
    const expectedHourlyAmount = expectedHourlyServiceAmountMinor(hourlyRate, durationHours);
    if (amountValue !== expectedHourlyAmount) {
      throw new HttpsError("invalid-argument", "Hourly service amount does not match duration.");
    }
  } else if (pricingMode !== "fixedJob" && serviceData.priceType !== "fixed") {
    throw new HttpsError("failed-precondition", "Only priced services can use payment checkout.");
  }
  if (!providerData || providerData.payoutAccountStatus !== PAYOUT_ACCOUNT_VERIFIED) {
    throw new HttpsError("failed-precondition", "The provider must verify payout details before paid bookings.");
  }

  return {
    amount: amountValue,
    currency,
    relatedId,
    payerId,
    receiverId,
    serviceId,
    requestRef,
    requestData,
    providerData,
  };
}

export const createXenditMarketplacePayment = onCall(
  {secrets: [xenditSecret]},
  async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  if (readString(input, "paymentType") !== PAYMENT_TYPE_MARKETPLACE) {
    throw new HttpsError("invalid-argument", "Invalid payment type.");
  }

  const db = admin.firestore();
  const marketplace = await validateXenditMarketplacePayment(db, uid, input);
  await cancelExistingPendingMarketplacePayment(db, marketplace.requestRef, marketplace.requestData);

  const paymentRef = db.collection(PAYMENTS_COLLECTION).doc();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const paymentAmount = moneyToXenditAmount(marketplace.amount / 100);
  const description = readString(
    input,
    "description",
    `Jirani marketplace payment for ${String(marketplace.requestData.itemTitle ?? "item")}`,
  );
  const payerEmail = typeof marketplace.requestData.borrowerEmail === "string" ?
    marketplace.requestData.borrowerEmail :
    "";

  await paymentRef.set({
    payerId: marketplace.payerId,
    receiverId: marketplace.receiverId,
    paymentType: PAYMENT_TYPE_MARKETPLACE,
    paymentProvider: XENDIT_PROVIDER,
    relatedId: marketplace.relatedId,
    itemId: marketplace.itemId,
    amount: marketplace.amount,
    currency: marketplace.currency,
    usageFeeAmount: Math.max(0, toMoneyNumber(marketplace.requestData.usageFeeAmount)),
    depositAmount: Math.max(0, toMoneyNumber(marketplace.requestData.depositAmount)),
    status: PAYMENT_STATUS_PENDING,
    xenditReferenceId: paymentRef.id,
    xenditInvoiceId: "",
    xenditPaymentRequestId: "",
    xenditPaymentId: "",
    xenditHostedUrl: "",
    createdAt: now,
    updatedAt: now,
  });

  try {
    const invoice = await xenditPost("/v2/invoices", {
      external_id: paymentRef.id,
      amount: paymentAmount,
      currency: marketplace.currency.toUpperCase(),
      payer_email: payerEmail || undefined,
      description,
      success_redirect_url: readString(input, "successRedirectUrl"),
      failure_redirect_url: readString(input, "failureRedirectUrl"),
      metadata: {
        paymentId: paymentRef.id,
        paymentType: PAYMENT_TYPE_MARKETPLACE,
        relatedId: marketplace.relatedId,
        payerId: marketplace.payerId,
        receiverId: marketplace.receiverId,
        itemId: marketplace.itemId,
      },
    });
    const invoiceId = readString(invoice, "id");
    const invoiceUrl = readString(invoice, "invoice_url") ||
      readString(invoice, "checkout_url");
    if (!invoiceId || !invoiceUrl) {
      throw new Error("Xendit did not return a hosted checkout URL.");
    }

    await paymentRef.update({
      xenditInvoiceId: invoiceId,
      xenditHostedUrl: invoiceUrl,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await marketplace.requestRef.set({
      pendingPaymentId: paymentRef.id,
      pendingXenditInvoiceId: invoiceId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    return {
      paymentId: paymentRef.id,
      checkoutUrl: invoiceUrl,
      xenditInvoiceId: invoiceId,
      status: PAYMENT_STATUS_PENDING,
    };
  } catch (error) {
    await paymentRef.update({
      status: PAYMENT_STATUS_FAILED,
      xenditFailureReason: safeErrorMessage(error),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw new HttpsError("internal", safeErrorMessage(error));
  }
});

export const createXenditServicePayment = onCall(
  {secrets: [xenditSecret]},
  async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  if (readString(input, "paymentType") !== PAYMENT_TYPE_SERVICE) {
    throw new HttpsError("invalid-argument", "Invalid payment type.");
  }

  const db = admin.firestore();
  const service = await validateXenditServicePayment(db, uid, input);

  const paymentRef = db.collection(PAYMENTS_COLLECTION).doc();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const paymentAmount = moneyToXenditAmount(service.amount / 100);
  const description = readString(
    input,
    "description",
    `Jirani service payment for ${String(service.requestData.serviceTitle ?? "service")}`,
  );

  await paymentRef.set({
    payerId: service.payerId,
    receiverId: service.receiverId,
    paymentType: PAYMENT_TYPE_SERVICE,
    paymentProvider: XENDIT_PROVIDER,
    relatedId: service.relatedId,
    serviceId: service.serviceId,
    amount: service.amount,
    currency: service.currency,
    status: PAYMENT_STATUS_PENDING,
    xenditReferenceId: paymentRef.id,
    xenditInvoiceId: "",
    xenditPaymentRequestId: "",
    xenditPaymentId: "",
    xenditHostedUrl: "",
    createdAt: now,
    updatedAt: now,
  });

  try {
    const invoice = await xenditPost("/v2/invoices", {
      external_id: paymentRef.id,
      amount: paymentAmount,
      currency: service.currency.toUpperCase(),
      description,
      success_redirect_url: readString(input, "successRedirectUrl"),
      failure_redirect_url: readString(input, "failureRedirectUrl"),
      metadata: {
        paymentId: paymentRef.id,
        paymentType: PAYMENT_TYPE_SERVICE,
        relatedId: service.relatedId,
        payerId: service.payerId,
        receiverId: service.receiverId,
        serviceId: service.serviceId,
      },
    });
    const invoiceId = readString(invoice, "id");
    const invoiceUrl = readString(invoice, "invoice_url") || readString(invoice, "checkout_url");
    if (!invoiceId || !invoiceUrl) {
      throw new Error("Xendit did not return a hosted checkout URL.");
    }

    await paymentRef.update({
      xenditInvoiceId: invoiceId,
      xenditHostedUrl: invoiceUrl,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await service.requestRef.set({
      pendingPaymentId: paymentRef.id,
      pendingXenditInvoiceId: invoiceId,
      paymentStatus: PAYMENT_STATUS_PENDING,
      paymentProvider: XENDIT_PROVIDER,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    return {
      paymentId: paymentRef.id,
      checkoutUrl: invoiceUrl,
      xenditInvoiceId: invoiceId,
      status: PAYMENT_STATUS_PENDING,
    };
  } catch (error) {
    await paymentRef.update({
      status: PAYMENT_STATUS_FAILED,
      xenditFailureReason: safeErrorMessage(error),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw new HttpsError("internal", safeErrorMessage(error));
  }
});

export const getPaymentStatus = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const paymentId = readString(asRecord(request.data), "paymentId");
  if (!paymentId) throw new HttpsError("invalid-argument", "Missing payment id.");
  const snapshot = await admin.firestore().collection(PAYMENTS_COLLECTION).doc(paymentId).get();
  const data = snapshot.data();
  if (!data) throw new HttpsError("not-found", "Payment was not found.");
  if (data.payerId !== uid && data.receiverId !== uid) {
    throw new HttpsError("permission-denied", "You cannot view this payment.");
  }
  return {
    status: data.status ?? PAYMENT_STATUS_PENDING,
    paymentProvider: data.paymentProvider ?? "",
  };
});

export const saveTestPayoutAccount = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const channelCode = readString(input, "xenditPayoutChannel").toUpperCase();
  const accountName = readString(input, "payoutAccountName");
  const accountNumber = readString(input, "payoutAccountNumber");

  if (!ALLOWED_TEST_PAYOUT_CHANNELS.has(channelCode)) {
    throw new HttpsError("invalid-argument", "Choose a supported payout destination.");
  }
  if (accountName.length < 2 || accountName.length > 100) {
    throw new HttpsError("invalid-argument", "Enter the account holder name.");
  }
  if (accountNumber.length < 4 || accountNumber.length > 64) {
    throw new HttpsError("invalid-argument", "Enter a valid account or e-wallet identifier.");
  }

  const userRef = admin.firestore().collection(USERS_COLLECTION).doc(uid);
  const userSnap = await userRef.get();
  const userData = userSnap.data();
  if (!userData || userData.role !== "resident") {
    throw new HttpsError("failed-precondition", "Resident profile was not found.");
  }

  await userRef.set({
    payoutAccountStatus: PAYOUT_ACCOUNT_VERIFIED,
    xenditPayoutChannel: channelCode,
    payoutAccountName: accountName,
    payoutAccountNumber: accountNumber,
    payoutAccountMaskedIdentifier: maskPayoutIdentifier(accountNumber),
    payoutAccountVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    payoutAccountUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {
    success: true,
    payoutAccountStatus: PAYOUT_ACCOUNT_VERIFIED,
    xenditPayoutChannel: channelCode,
    payoutAccountName: accountName,
    payoutAccountMaskedIdentifier: maskPayoutIdentifier(accountNumber),
  };
});

function xenditStatusToPaymentStatus(status: string, event: string): string {
  const normalizedStatus = status.toUpperCase();
  const normalizedEvent = event.toLowerCase();
  if (["PAID", "SETTLED", "SUCCEEDED"].includes(normalizedStatus) ||
      normalizedEvent === "payment.capture") {
    return PAYMENT_STATUS_SUCCEEDED;
  }
  if (normalizedStatus === "FAILED" || normalizedEvent === "payment.failure") {
    return PAYMENT_STATUS_FAILED;
  }
  if (["EXPIRED", "CANCELED", "CANCELLED"].includes(normalizedStatus) ||
      normalizedEvent === "payment_request.expiry") {
    return PAYMENT_STATUS_CANCELLED;
  }
  return PAYMENT_STATUS_PENDING;
}

function isXenditRefundEvent(eventBody: Record<string, unknown>): boolean {
  const event = readString(eventBody, "event").toLowerCase();
  const data = asRecord(eventBody.data ?? eventBody);
  return event.includes("refund") ||
    readString(data, "refund_id").trim().length > 0 ||
    readString(data, "refund_request_id").trim().length > 0 ||
    readString(data, "refund_status").trim().length > 0;
}

function isXenditPayoutEvent(eventBody: Record<string, unknown>): boolean {
  const event = readString(eventBody, "event").toLowerCase();
  const data = asRecord(eventBody.data ?? eventBody);
  return event.includes("payout") ||
    readString(data, "payout_id").trim().length > 0 ||
    readString(data, "payout_status").trim().length > 0 ||
    readString(data, "reference_id").startsWith("service_");
}

function xenditStatusToRefundStatus(status: string, event: string): string {
  const normalizedStatus = status.toUpperCase();
  const normalizedEvent = event.toLowerCase();
  if (["SUCCEEDED", "SUCCESSFUL", "COMPLETED", "SUCCESS"].includes(normalizedStatus) ||
      normalizedEvent.includes("refund.succeeded") ||
      normalizedEvent.includes("refund.successful") ||
      normalizedEvent.includes("refund.completed")) {
    return REFUND_STATUS_SUCCEEDED;
  }
  if (["FAILED", "CANCELED", "CANCELLED", "EXPIRED"].includes(normalizedStatus) ||
      normalizedEvent.includes("refund.failed")) {
    return REFUND_STATUS_FAILED;
  }
  return REFUND_STATUS_PENDING;
}

function xenditStatusToServicePayoutStatus(status: string, event: string): string {
  const normalizedStatus = status.toUpperCase();
  const normalizedEvent = event.toLowerCase();
  if (["SUCCEEDED", "SUCCESSFUL", "COMPLETED", "SUCCESS"].includes(normalizedStatus) ||
      normalizedEvent.includes("payout.succeeded")) {
    return SERVICE_PAYOUT_SENT;
  }
  if (["FAILED", "CANCELED", "CANCELLED", "EXPIRED"].includes(normalizedStatus) ||
      normalizedEvent.includes("payout.failed")) {
    return SERVICE_PAYOUT_FAILED;
  }
  return SERVICE_PAYOUT_PENDING;
}

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
    update.paymentStatus = BORROW_PAYMENT_STATUS_COMPLETED;
    update.paymentProvider = XENDIT_PROVIDER;
    update.paymentCompletedAt = admin.firestore.FieldValue.serverTimestamp();
    update.paymentId = payment.id;
    update.xenditInvoiceId = payment.xenditInvoiceId ?? "";
    update.xenditPaymentRequestId = payment.xenditPaymentRequestId ?? "";
    update.xenditPaymentId = payment.xenditPaymentId ?? "";
    update.xenditReferenceId = payment.xenditReferenceId ?? payment.id;
    update.xenditChannelCode = payment.xenditChannelCode ?? "";
    update.chatId = marketplaceChatId(String(payment.payerId ?? ""), String(payment.receiverId ?? ""));
    const depositAmount = Math.max(0, toMoneyNumber(payment.depositAmount));
    const usageFeeAmount = Math.max(0, toMoneyNumber(payment.usageFeeAmount));
    update.depositStatus = depositAmount > 0 ? DEPOSIT_STATUS_HELD : DEPOSIT_STATUS_NOT_REQUIRED;
    update.depositHeldAmount = depositAmount > 0 ? depositAmount : 0;
    update.depositRefundAmount = 0;
    update.damageDeductionAmount = 0;
    update.damageDecision = DAMAGE_DECISION_NONE;
    update.damageDecisionReason = "";
    update.refundStatus = depositAmount > 0 ? REFUND_STATUS_NOT_STARTED : REFUND_STATUS_NOT_REQUIRED;
    update.refundFailureReason = "";
    update.lenderBaseEarning = usageFeeAmount;
    update.lenderDamageEarning = 0;
    update.lenderTotalEarning = usageFeeAmount;
    update.manualPayoutStatus = MANUAL_PAYOUT_NOT_READY;
    update.pendingPaymentId = admin.firestore.FieldValue.delete();
    update.pendingXenditInvoiceId = admin.firestore.FieldValue.delete();
    update.pendingXenditPaymentRequestId = admin.firestore.FieldValue.delete();
  } else if (status === PAYMENT_STATUS_FAILED) {
    update.paymentStatus = BORROW_PAYMENT_STATUS_FAILED;
    update.pendingPaymentId = admin.firestore.FieldValue.delete();
    update.pendingXenditInvoiceId = admin.firestore.FieldValue.delete();
    update.pendingXenditPaymentRequestId = admin.firestore.FieldValue.delete();
  } else if (status === PAYMENT_STATUS_CANCELLED) {
    update.paymentStatus = BORROW_PAYMENT_STATUS_CANCELLED;
    update.pendingPaymentId = admin.firestore.FieldValue.delete();
    update.pendingXenditInvoiceId = admin.firestore.FieldValue.delete();
    update.pendingXenditPaymentRequestId = admin.firestore.FieldValue.delete();
  }

  await admin.firestore().collection(BORROW_REQUESTS_COLLECTION).doc(relatedId).set(update, {merge: true});
}

async function updateServiceRequestFromPayment(
  payment: DocumentData,
  status: string,
): Promise<void> {
  if (payment.paymentType !== PAYMENT_TYPE_SERVICE) return;
  const relatedId = typeof payment.relatedId === "string" ? payment.relatedId : "";
  if (!relatedId) return;

  const requestRef = admin.firestore().collection(SERVICE_REQUESTS_COLLECTION).doc(relatedId);
  const snapshot = await requestRef.get();
  const requestData = snapshot.data();
  if (!requestData) return;

  const update: Record<string, unknown> = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (status === PAYMENT_STATUS_SUCCEEDED) {
    update.status = SERVICE_STATUS_PAID_HELD;
    update.paymentStatus = PAYMENT_STATUS_SUCCEEDED;
    update.paymentProvider = XENDIT_PROVIDER;
    update.paymentCompletedAt = admin.firestore.FieldValue.serverTimestamp();
    update.paymentId = payment.id;
    update.xenditInvoiceId = payment.xenditInvoiceId ?? "";
    update.xenditPaymentRequestId = payment.xenditPaymentRequestId ?? "";
    update.xenditPaymentId = payment.xenditPaymentId ?? "";
    update.xenditReferenceId = payment.xenditReferenceId ?? payment.id;
    update.xenditChannelCode = payment.xenditChannelCode ?? "";
    update.payoutStatus = SERVICE_PAYOUT_NOT_STARTED;
    update.refundStatus = REFUND_STATUS_NOT_STARTED;
    update.pendingPaymentId = admin.firestore.FieldValue.delete();
    update.pendingXenditInvoiceId = admin.firestore.FieldValue.delete();
  } else if (status === PAYMENT_STATUS_FAILED) {
    update.status = SERVICE_STATUS_PAYMENT_FAILED;
    update.paymentStatus = PAYMENT_STATUS_FAILED;
    update.pendingPaymentId = admin.firestore.FieldValue.delete();
    update.pendingXenditInvoiceId = admin.firestore.FieldValue.delete();
  } else if (status === PAYMENT_STATUS_CANCELLED) {
    update.paymentStatus = PAYMENT_STATUS_CANCELLED;
    update.pendingPaymentId = admin.firestore.FieldValue.delete();
    update.pendingXenditInvoiceId = admin.firestore.FieldValue.delete();
  }

  await requestRef.set(update, {merge: true});

  if (status === PAYMENT_STATUS_SUCCEEDED) {
    await Promise.all([
      createInAppNotification(admin.firestore(), {
        userId: String(requestData.providerId ?? ""),
        actorId: String(requestData.requesterId ?? ""),
        type: NOTIFICATION_TYPE_SERVICE_PAYMENT_RECEIVED,
        title: "Service payment received",
        body: `Payment is held for "${String(requestData.serviceTitle ?? "your service")}". You can coordinate arrival now.`,
        category: "Services",
        serviceRequestId: relatedId,
        notificationId: notificationIdFor("servicePaid", relatedId, String(requestData.providerId ?? "")),
      }),
      createInAppNotification(admin.firestore(), {
        userId: String(requestData.requesterId ?? ""),
        actorId: String(requestData.providerId ?? ""),
        type: NOTIFICATION_TYPE_SERVICE_PAYMENT_RECEIVED,
        title: "Payment held securely",
        body: `Your payment for "${String(requestData.serviceTitle ?? "the service")}" is held until completion is verified.`,
        category: "Services",
        serviceRequestId: relatedId,
        notificationId: notificationIdFor("servicePaid", relatedId, String(requestData.requesterId ?? "")),
      }),
    ]);
  }
}

function borrowRequestIdFromRefundEvent(eventBody: Record<string, unknown>): string {
  const data = asRecord(eventBody.data ?? eventBody);
  const metadata = asRecord(data.metadata ?? eventBody.metadata);
  const metadataBorrowRequestId = readString(metadata, "borrowRequestId");
  if (metadataBorrowRequestId) return metadataBorrowRequestId;

  const referenceId = readString(data, "reference_id") ||
    readString(eventBody, "reference_id") ||
    readString(data, "external_id") ||
    readString(eventBody, "external_id");
  const match = /^borrow_(.+)_(full_refund|partial_deduction|full_deduction)$/.exec(referenceId);
  return match?.[1] ?? "";
}

async function borrowRequestRefForRefundEvent(
  db: admin.firestore.Firestore,
  eventBody: Record<string, unknown>,
): Promise<admin.firestore.DocumentReference | null> {
  const data = asRecord(eventBody.data ?? eventBody);
  const borrowRequestId = borrowRequestIdFromRefundEvent(eventBody);
  if (borrowRequestId) {
    return db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId);
  }

  const refundId = readString(data, "id") ||
    readString(data, "refund_id") ||
    readString(data, "refund_request_id");
  if (!refundId) return null;

  const snapshot = await db.collection(BORROW_REQUESTS_COLLECTION)
    .where("xenditRefundId", "==", refundId)
    .limit(1)
    .get();
  return snapshot.empty ? null : snapshot.docs[0].ref;
}

async function updateMarketplaceRefundFromXenditEvent(
  eventBody: Record<string, unknown>,
): Promise<void> {
  const event = readString(eventBody, "event");
  const data = asRecord(eventBody.data ?? eventBody);
  const db = admin.firestore();
  const requestRef = await borrowRequestRefForRefundEvent(db, eventBody);
  if (!requestRef) {
    logger.warn("Xendit refund webhook borrow request not found", {
      event,
      referenceId: readString(data, "reference_id"),
      refundId: readString(data, "id") || readString(data, "refund_id"),
    });
    return;
  }

  const snapshot = await requestRef.get();
  const requestData = snapshot.data();
  if (!requestData) {
    logger.warn("Xendit refund webhook request document missing", {
      event,
      borrowRequestId: requestRef.id,
    });
    return;
  }

  const status = xenditStatusToRefundStatus(
    readString(data, "status") ||
      readString(data, "refund_status") ||
      readString(eventBody, "status"),
    event,
  );
  const refundId = readString(data, "id") ||
    readString(data, "refund_id") ||
    readString(data, "refund_request_id") ||
    String(requestData.xenditRefundId ?? "");
  const failureReason = readString(data, "failure_code") ||
    readString(data, "failure_reason") ||
    readString(data, "reason");
  const now = admin.firestore.FieldValue.serverTimestamp();
  const update: Record<string, unknown> = {
    refundStatus: status,
    xenditRefundId: refundId,
    lastXenditRefundEvent: event,
    lastXenditRefundEventAt: now,
    updatedAt: now,
  };

  if (status === REFUND_STATUS_SUCCEEDED) {
    update.refundFailureReason = "";
    update.depositRefundedAt = now;
  } else if (status === REFUND_STATUS_FAILED) {
    update.depositStatus = DEPOSIT_STATUS_REFUND_FAILED;
    update.refundFailureReason = failureReason || "Xendit refund failed.";
    update.xenditFailureReason = update.refundFailureReason;
    if (requestData.manualPayoutStatus !== MANUAL_PAYOUT_PAID) {
      update.manualPayoutStatus = MANUAL_PAYOUT_BLOCKED;
    }
  }

  await requestRef.set(update, {merge: true});
}

async function updatePaymentFromXenditEvent(eventBody: Record<string, unknown>): Promise<void> {
  const event = readString(eventBody, "event");
  const data = asRecord(eventBody.data ?? eventBody);
  const referenceId = readString(data, "reference_id") ||
    readString(data, "external_id") ||
    readString(eventBody, "external_id");
  if (!referenceId) {
    logger.warn("Xendit webhook missing reference id", {event});
    return;
  }

  const paymentRef = admin.firestore().collection(PAYMENTS_COLLECTION).doc(referenceId);
  const snapshot = await paymentRef.get();
  if (!snapshot.exists) {
    logger.warn("Xendit webhook payment not found", {event, referenceId});
    return;
  }

  const status = xenditStatusToPaymentStatus(
    readString(data, "status") || readString(eventBody, "status"),
    event,
  );
  const update: Record<string, unknown> = {
    id: referenceId,
    status,
    paymentProvider: XENDIT_PROVIDER,
    xenditReferenceId: referenceId,
    xenditPaymentRequestId: readString(data, "payment_request_id"),
    xenditPaymentId: readString(data, "payment_id"),
    xenditInvoiceId: readString(data, "id") || readString(data, "invoice_id"),
    xenditChannelCode: readString(data, "channel_code") ||
      readString(data, "payment_channel"),
    lastXenditEvent: event,
    lastXenditEventAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const failureCode = readString(data, "failure_code") ||
    readString(data, "failure_reason");
  if (failureCode) update.xenditFailureReason = failureCode;
  await paymentRef.set(update, {merge: true});

  const latest = await paymentRef.get();
  const payment = latest.data();
  if (payment) {
    const enriched = {...payment, id: referenceId};
    await updateMarketplaceBorrowRequest(enriched, status);
    await updateServiceRequestFromPayment(enriched, status);
  }
}

function serviceRequestIdFromPayoutEvent(eventBody: Record<string, unknown>): string {
  const data = asRecord(eventBody.data ?? eventBody);
  const metadata = asRecord(data.metadata ?? eventBody.metadata);
  const metadataServiceRequestId = readString(metadata, "serviceRequestId");
  if (metadataServiceRequestId) return metadataServiceRequestId;

  const referenceId = readString(data, "reference_id") ||
    readString(eventBody, "reference_id");
  const match = /^service_(.+)_payout$/.exec(referenceId);
  return match?.[1] ?? "";
}

async function updateServicePayoutFromXenditEvent(
  eventBody: Record<string, unknown>,
): Promise<void> {
  const event = readString(eventBody, "event");
  const data = asRecord(eventBody.data ?? eventBody);
  const serviceRequestId = serviceRequestIdFromPayoutEvent(eventBody);
  if (!serviceRequestId) {
    logger.warn("Xendit payout webhook service request not found", {
      event,
      referenceId: readString(data, "reference_id"),
      payoutId: readString(data, "id") || readString(data, "payout_id"),
    });
    return;
  }

  const db = admin.firestore();
  const requestRef = db.collection(SERVICE_REQUESTS_COLLECTION).doc(serviceRequestId);
  const snapshot = await requestRef.get();
  const requestData = snapshot.data();
  if (!requestData) {
    logger.warn("Xendit payout webhook request document missing", {
      event,
      serviceRequestId,
    });
    return;
  }

  const payoutStatus = xenditStatusToServicePayoutStatus(
    readString(data, "status") ||
      readString(data, "payout_status") ||
      readString(eventBody, "status"),
    event,
  );
  const payoutId = readString(data, "id") ||
    readString(data, "payout_id") ||
    String(requestData.xenditPayoutId ?? "");
  const failureReason = readString(data, "failure_code") ||
    readString(data, "failure_reason") ||
    readString(data, "reason");
  const now = admin.firestore.FieldValue.serverTimestamp();
  const update: Record<string, unknown> = {
    payoutStatus,
    xenditPayoutId: payoutId,
    lastXenditPayoutEvent: event,
    lastXenditPayoutEventAt: now,
    updatedAt: now,
  };

  if (payoutStatus === SERVICE_PAYOUT_SENT) {
    update.status = SERVICE_STATUS_COMPLETED_PAYOUT_SENT;
    update.payoutFailureReason = "";
    update.payoutSentAt = now;
  } else if (payoutStatus === SERVICE_PAYOUT_FAILED) {
    update.status = SERVICE_STATUS_COMPLETED_PAYOUT_PENDING;
    update.payoutFailureReason = failureReason || "Xendit payout failed.";
  }

  await requestRef.set(update, {merge: true});

  if (payoutStatus === SERVICE_PAYOUT_SENT) {
    await createInAppNotification(db, {
      userId: String(requestData.providerId ?? ""),
      actorId: "system",
      type: NOTIFICATION_TYPE_SERVICE_PAYOUT_SENT,
      title: "Service payout sent",
      body: `Your ${moneyLabel(toMoneyNumber(requestData.providerPayoutAmount || requestData.amount))} payout for "${String(requestData.serviceTitle ?? "your service")}" was sent.`,
      category: "Services",
      serviceRequestId,
      notificationId: notificationIdFor("servicePayoutSent", serviceRequestId, String(requestData.providerId ?? "")),
    });
  } else if (payoutStatus === SERVICE_PAYOUT_FAILED) {
    await createInAppNotification(db, {
      userId: String(requestData.providerId ?? ""),
      actorId: "system",
      type: NOTIFICATION_TYPE_SERVICE_PAYOUT_FAILED,
      title: "Service payout failed",
      body: failureReason || "Xendit payout failed.",
      category: "Services",
      serviceRequestId,
      notificationId: notificationIdFor("servicePayoutFailed", serviceRequestId, String(requestData.providerId ?? "")),
    });
  }
}

export const xenditWebhook = onRequest(
  {secrets: [xenditWebhookToken]},
  async (request, response) => {
  if (!verifyXenditWebhook(request)) {
    response.status(401).send("Invalid Xendit callback token.");
    return;
  }
  try {
    const eventBody = asRecord(request.body);
    if (isXenditRefundEvent(eventBody)) {
      await updateMarketplaceRefundFromXenditEvent(eventBody);
    } else if (isXenditPayoutEvent(eventBody)) {
      await updateServicePayoutFromXenditEvent(eventBody);
    } else {
      await updatePaymentFromXenditEvent(eventBody);
    }
    response.json({received: true});
  } catch (error) {
    logger.error("Failed to process Xendit webhook", {error});
    response.status(500).send("Webhook processing failed.");
  }
});

async function applySimulatedServicePayout(
  db: admin.firestore.Firestore,
  requestId: string,
  requestData: DocumentData,
  actorId: string,
  amount: number,
): Promise<{payoutId: string; payoutStatus: string}> {
  const requestRef = db.collection(SERVICE_REQUESTS_COLLECTION).doc(requestId);
  const providerId = typeof requestData.providerId === "string" ? requestData.providerId : "";
  const now = admin.firestore.FieldValue.serverTimestamp();
  await requestRef.set({
    payoutStatus: SERVICE_PAYOUT_SENT,
    status: SERVICE_STATUS_COMPLETED_PAYOUT_SENT,
    settlementMode: SETTLEMENT_MODE_SIMULATED,
    xenditPayoutId: "",
    payoutFailureReason: "",
    payoutSentAt: now,
    updatedAt: now,
  }, {merge: true});
  await createInAppNotification(db, {
    userId: providerId,
    actorId,
    type: NOTIFICATION_TYPE_SERVICE_PAYOUT_SENT,
    title: "Service payout sent",
    body: `Your ${moneyLabel(amount)} test payout for "${String(requestData.serviceTitle ?? "your service")}" was recorded.`,
    category: "Services",
    serviceRequestId: requestId,
    notificationId: notificationIdFor("servicePayoutSent", requestId, providerId),
  });
  return {payoutId: "", payoutStatus: SERVICE_PAYOUT_SENT};
}

async function createServicePayout(
  db: admin.firestore.Firestore,
  requestId: string,
  requestData: DocumentData,
  actorId: string,
  options: {throwOnFailure?: boolean} = {},
): Promise<{payoutId: string; payoutStatus: string; payoutFailureReason?: string}> {
  const throwOnFailure = options.throwOnFailure ?? true;
  const requestRef = db.collection(SERVICE_REQUESTS_COLLECTION).doc(requestId);
  const existingPayoutId = typeof requestData.xenditPayoutId === "string" ? requestData.xenditPayoutId : "";
  if (existingPayoutId && requestData.payoutStatus === SERVICE_PAYOUT_SENT) {
    return {payoutId: existingPayoutId, payoutStatus: SERVICE_PAYOUT_SENT};
  }

  const amount = Math.max(0, toMoneyNumber(requestData.providerPayoutAmount || requestData.amount));
  if (amount <= 0) throw new HttpsError("failed-precondition", "Service payout amount is missing.");
  const providerId = typeof requestData.providerId === "string" ? requestData.providerId : "";
  const providerSnapshot = await db.collection(USERS_COLLECTION).doc(providerId).get();
  const provider = providerSnapshot.data();
  if (!provider || provider.payoutAccountStatus !== PAYOUT_ACCOUNT_VERIFIED) {
    throw new HttpsError("failed-precondition", "Provider payout account is not verified.");
  }
  const payoutChannel = readString(provider, "xenditPayoutChannel");
  const payoutAccountName = readString(provider, "payoutAccountName");
  const payoutAccountNumber = readString(provider, "payoutAccountNumber");
  if (!payoutChannel || !payoutAccountName || !payoutAccountNumber) {
    throw new HttpsError("failed-precondition", "Provider payout account details are incomplete.");
  }

  await requestRef.set({
    payoutStatus: SERVICE_PAYOUT_PENDING,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  if (isSimulatedSettlement()) {
    return applySimulatedServicePayout(db, requestId, requestData, actorId, amount);
  }

  try {
    const payoutReferenceId = `service_${requestId}_payout`;
    const payout = await xenditPost("/v2/payouts", {
      reference_id: payoutReferenceId,
      amount: moneyToXenditAmount(amount),
      currency: DEFAULT_CURRENCY.toUpperCase(),
      channel_code: payoutChannel,
      channel_properties: {
        account_number: payoutAccountNumber,
        account_holder_name: payoutAccountName,
      },
      description: `Jirani service payout for ${String(requestData.serviceTitle ?? "service")}`,
      metadata: {serviceRequestId: requestId, providerId, actorId},
    }, {
      "Idempotency-key": payoutReferenceId,
    });
    const payoutId = readString(payout, "id") || readString(payout, "payout_id");
    const payoutStatus = xenditStatusToServicePayoutStatus(
      readString(payout, "status") || readString(payout, "payout_status"),
      "",
    );
    const payoutUpdate: Record<string, unknown> = {
      payoutStatus,
      xenditPayoutId: payoutId,
      settlementMode: SETTLEMENT_MODE_LIVE,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (payoutStatus === SERVICE_PAYOUT_SENT) {
      payoutUpdate.status = SERVICE_STATUS_COMPLETED_PAYOUT_SENT;
      payoutUpdate.payoutFailureReason = "";
      payoutUpdate.payoutSentAt = admin.firestore.FieldValue.serverTimestamp();
    }
    await requestRef.set(payoutUpdate, {merge: true});
    if (payoutStatus === SERVICE_PAYOUT_SENT) {
      await createInAppNotification(db, {
        userId: providerId,
        actorId,
        type: NOTIFICATION_TYPE_SERVICE_PAYOUT_SENT,
        title: "Service payout sent",
        body: `Your ${moneyLabel(amount)} payout for "${String(requestData.serviceTitle ?? "your service")}" was sent.`,
        category: "Services",
        serviceRequestId: requestId,
        notificationId: notificationIdFor("servicePayoutSent", requestId, providerId),
      });
    }
    return {payoutId, payoutStatus};
  } catch (error) {
    const message = safeErrorMessage(error);
    await requestRef.set({
      payoutStatus: SERVICE_PAYOUT_FAILED,
      payoutFailureReason: message,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    await createInAppNotification(db, {
      userId: providerId,
      actorId,
      type: NOTIFICATION_TYPE_SERVICE_PAYOUT_FAILED,
      title: "Service payout failed",
      body: message,
      category: "Services",
      serviceRequestId: requestId,
      notificationId: notificationIdFor("servicePayoutFailed", requestId, providerId),
    });
    if (throwOnFailure) {
      throw new HttpsError("internal", message);
    }
    return {
      payoutId: "",
      payoutStatus: SERVICE_PAYOUT_FAILED,
      payoutFailureReason: message,
    };
  }
}

async function getServiceRequestForActor(
  db: admin.firestore.Firestore,
  requestId: string,
): Promise<{
  ref: admin.firestore.DocumentReference;
  data: DocumentData;
}> {
  if (!requestId) throw new HttpsError("invalid-argument", "Missing service request id.");
  const ref = db.collection(SERVICE_REQUESTS_COLLECTION).doc(requestId);
  const snapshot = await ref.get();
  const data = snapshot.data();
  if (!data) throw new HttpsError("not-found", "Service request was not found.");
  return {ref, data};
}

export const generateServiceArrivalCode = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const requestId = readString(input, "requestId");
  const providerId = readString(input, "providerId");
  if (uid !== providerId) throw new HttpsError("permission-denied", "Only the provider can generate this code.");
  const db = admin.firestore();
  const {ref, data} = await getServiceRequestForActor(db, requestId);
  if (data.providerId !== uid) throw new HttpsError("permission-denied", "Only the provider can generate this code.");
  if (data.status !== SERVICE_STATUS_PAID_HELD) {
    throw new HttpsError("failed-precondition", "Arrival code is available after payment is held.");
  }
  const code = generateFourDigitCode();
  await ref.set({
    arrivalCodeHash: serviceCodeHash(requestId, "arrival", code),
    arrivalCodeExpiresAt: codeExpiry(),
    arrivalCodeAttempts: 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  return {code, expiresInSeconds: 900};
});

export const submitServiceArrivalCode = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const requestId = readString(input, "requestId");
  const requesterId = readString(input, "requesterId");
  const code = readString(input, "code");
  assertFourDigitCode(code);
  if (uid !== requesterId) throw new HttpsError("permission-denied", "Only the requester can submit this code.");
  const db = admin.firestore();
  const {ref, data} = await getServiceRequestForActor(db, requestId);
  if (data.requesterId !== uid) throw new HttpsError("permission-denied", "Only the requester can submit this code.");
  if (data.status !== SERVICE_STATUS_PAID_HELD) throw new HttpsError("failed-precondition", "This service is not awaiting arrival.");
  if (timestampExpired(data.arrivalCodeExpiresAt)) throw new HttpsError("deadline-exceeded", "Arrival code expired.");
  const attempts = Math.max(0, toMoneyNumber(data.arrivalCodeAttempts));
  if (attempts >= 5) throw new HttpsError("resource-exhausted", "Too many code attempts.");
  if (data.arrivalCodeHash !== serviceCodeHash(requestId, "arrival", code)) {
    await ref.set({arrivalCodeAttempts: attempts + 1}, {merge: true});
    throw new HttpsError("permission-denied", "Invalid arrival code.");
  }
  const now = admin.firestore.FieldValue.serverTimestamp();
  await ref.set({
    status: SERVICE_STATUS_IN_PROGRESS,
    arrivalVerifiedAt: now,
    startedAt: now,
    arrivalCodeHash: admin.firestore.FieldValue.delete(),
    updatedAt: now,
  }, {merge: true});
  await createInAppNotification(db, {
    userId: String(data.providerId ?? ""),
    actorId: uid,
    type: NOTIFICATION_TYPE_SERVICE_ARRIVAL_VERIFIED,
    title: "Service started",
    body: `Arrival was verified for "${String(data.serviceTitle ?? "your service")}".`,
    category: "Services",
    serviceRequestId: requestId,
    notificationId: notificationIdFor("serviceArrivalVerified", requestId, String(data.providerId ?? "")),
  });
  return {success: true};
});

export const generateServiceCompletionCode = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const requestId = readString(input, "requestId");
  const requesterId = readString(input, "requesterId");
  if (uid !== requesterId) throw new HttpsError("permission-denied", "Only the requester can generate this code.");
  const db = admin.firestore();
  const {ref, data} = await getServiceRequestForActor(db, requestId);
  if (data.requesterId !== uid) throw new HttpsError("permission-denied", "Only the requester can generate this code.");
  if (data.status !== SERVICE_STATUS_IN_PROGRESS) {
    throw new HttpsError("failed-precondition", "Completion code is available only while work is in progress.");
  }
  const code = generateFourDigitCode();
  await ref.set({
    completionCodeHash: serviceCodeHash(requestId, "completion", code),
    completionCodeExpiresAt: codeExpiry(),
    completionCodeAttempts: 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  return {code, expiresInSeconds: 900};
});

export const submitServiceCompletionCode = onCall(
  {secrets: [xenditSecret]},
  async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const requestId = readString(input, "requestId");
  const providerId = readString(input, "providerId");
  const code = readString(input, "code");
  assertFourDigitCode(code);
  if (uid !== providerId) throw new HttpsError("permission-denied", "Only the provider can submit this code.");
  const db = admin.firestore();
  const {ref, data} = await getServiceRequestForActor(db, requestId);
  if (data.providerId !== uid) throw new HttpsError("permission-denied", "Only the provider can submit this code.");
  if (data.status !== SERVICE_STATUS_IN_PROGRESS) throw new HttpsError("failed-precondition", "This service is not in progress.");
  if (timestampExpired(data.completionCodeExpiresAt)) throw new HttpsError("deadline-exceeded", "Completion code expired.");
  const attempts = Math.max(0, toMoneyNumber(data.completionCodeAttempts));
  if (attempts >= 5) throw new HttpsError("resource-exhausted", "Too many code attempts.");
  if (data.completionCodeHash !== serviceCodeHash(requestId, "completion", code)) {
    await ref.set({completionCodeAttempts: attempts + 1}, {merge: true});
    throw new HttpsError("permission-denied", "Invalid completion code.");
  }
  const now = admin.firestore.FieldValue.serverTimestamp();
  await ref.set({
    status: SERVICE_STATUS_COMPLETED_PAYOUT_PENDING,
    completionVerifiedAt: now,
    completedAt: now,
    completionCodeHash: admin.firestore.FieldValue.delete(),
    payoutStatus: SERVICE_PAYOUT_PENDING,
    updatedAt: now,
  }, {merge: true});
  const latest = await ref.get();
  await createServicePayout(db, requestId, latest.data() ?? data, uid, {
    throwOnFailure: false,
  });
  await createInAppNotification(db, {
    userId: String(data.requesterId ?? ""),
    actorId: uid,
    type: NOTIFICATION_TYPE_SERVICE_COMPLETED,
    title: "Service completed",
    body: `"${String(data.serviceTitle ?? "Your service")}" was completed and payout was released.`,
    category: "Services",
    serviceRequestId: requestId,
    notificationId: notificationIdFor("serviceCompleted", requestId, String(data.requesterId ?? "")),
  });
  return {success: true};
});

export const disputeServiceRequest = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const requestId = readString(input, "requestId");
  const requesterId = readString(input, "requesterId");
  const disputeType = readString(input, "disputeType");
  const details = readString(input, "details");
  const legacyReason = readString(input, "reason");
  const resolvedDetails = details || legacyReason;
  const evidenceUrls = readStringList(input, "evidenceUrls");
  assertServiceDisputeInput(disputeType, resolvedDetails);
  if (uid !== requesterId) throw new HttpsError("permission-denied", "Only the requester can dispute this service.");
  const db = admin.firestore();
  const {ref, data} = await getServiceRequestForActor(db, requestId);
  if (data.requesterId !== uid) throw new HttpsError("permission-denied", "Only the requester can dispute this service.");
  if (data.status !== SERVICE_STATUS_IN_PROGRESS) throw new HttpsError("failed-precondition", "Only in-progress services can be disputed.");
  const community = await loadResidentCommunity(db, uid);
  const serviceTitle = String(data.serviceTitle ?? "Service booking");
  const reportRef = db.collection(REPORTS_COLLECTION).doc();
  const notificationBody = serviceDisputeNotificationBody(disputeType, resolvedDetails);
  const batch = db.batch();
  batch.set(reportRef, {
    type: REPORT_TYPE_SERVICE_DISPUTE,
    relatedServiceRequestId: requestId,
    relatedBorrowRequestId: "",
    serviceId: String(data.serviceId ?? ""),
    itemId: "",
    communityId: community.communityId,
    communityName: community.communityName,
    reporterId: uid,
    reporterName: String(data.requesterName ?? ""),
    reportedUserId: String(data.providerId ?? ""),
    reportedUserName: String(data.providerName ?? ""),
    title: `Service dispute: ${serviceTitle}`,
    description: resolvedDetails.trim(),
    disputeType,
    serviceAmount: toMoneyNumber(data.amount),
    evidenceImageUrl: evidenceUrls[0] ?? null,
    requesterEvidenceUrls: evidenceUrls,
    providerEvidenceUrls: [],
    providerStatement: "",
    status: REPORT_STATUS_OPEN,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  batch.set(ref, {
    status: SERVICE_STATUS_DISPUTED,
    disputeType,
    disputeReason: resolvedDetails.trim(),
    disputeReportId: reportRef.id,
    requesterDisputeEvidenceUrls: evidenceUrls,
    providerDisputeEvidenceUrls: [],
    providerDisputeStatement: "",
    disputedAt: admin.firestore.FieldValue.serverTimestamp(),
    payoutStatus: SERVICE_PAYOUT_BLOCKED,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  await batch.commit();
  await createInAppNotification(db, {
    userId: String(data.providerId ?? ""),
    actorId: uid,
    type: NOTIFICATION_TYPE_SERVICE_DISPUTED,
    title: "Service disputed",
    body: notificationBody,
    category: "Services",
    serviceRequestId: requestId,
    reportId: reportRef.id,
    notificationId: notificationIdFor("serviceDisputed", requestId, String(data.providerId ?? "")),
  });
  return {success: true, reportId: reportRef.id};
});

export const submitServiceDisputeEvidence = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const requestId = readString(input, "requestId");
  const statement = readString(input, "statement");
  const evidenceUrls = readStringList(input, "evidenceUrls");
  if (!requestId) throw new HttpsError("invalid-argument", "requestId is required.");
  if (evidenceUrls.length === 0 && !statement) {
    throw new HttpsError("invalid-argument", "Add proof photos or a short statement.");
  }
  const db = admin.firestore();
  const {ref, data} = await getServiceRequestForActor(db, requestId);
  if (data.status !== SERVICE_STATUS_DISPUTED) {
    throw new HttpsError("failed-precondition", "This service is not under dispute.");
  }
  const isRequester = data.requesterId === uid;
  const isProvider = data.providerId === uid;
  if (!isRequester && !isProvider) {
    throw new HttpsError("permission-denied", "Only the requester or provider can submit dispute proof.");
  }
  const reportId = typeof data.disputeReportId === "string" ? data.disputeReportId.trim() : "";
  const requestUpdate: Record<string, unknown> = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const reportUpdate: Record<string, unknown> = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (isRequester) {
    const existing = Array.isArray(data.requesterDisputeEvidenceUrls) ?
      data.requesterDisputeEvidenceUrls.filter((entry): entry is string => typeof entry === "string") :
      [];
    const merged = [...existing, ...evidenceUrls].slice(0, 5);
    requestUpdate.requesterDisputeEvidenceUrls = merged;
    reportUpdate.requesterEvidenceUrls = merged;
    if (merged.length > 0) reportUpdate.evidenceImageUrl = merged[0];
  } else {
    const existing = Array.isArray(data.providerDisputeEvidenceUrls) ?
      data.providerDisputeEvidenceUrls.filter((entry): entry is string => typeof entry === "string") :
      [];
    const merged = [...existing, ...evidenceUrls].slice(0, 5);
    requestUpdate.providerDisputeEvidenceUrls = merged;
    reportUpdate.providerEvidenceUrls = merged;
    const nextStatement = statement || String(data.providerDisputeStatement ?? "");
    if (nextStatement.trim()) {
      requestUpdate.providerDisputeStatement = nextStatement.trim();
      reportUpdate.providerStatement = nextStatement.trim();
    }
  }
  const batch = db.batch();
  batch.set(ref, requestUpdate, {merge: true});
  if (reportId) {
    batch.set(db.collection(REPORTS_COLLECTION).doc(reportId), reportUpdate, {merge: true});
  }
  await batch.commit();
  return {success: true};
});

export const forceServicePayout = onCall(
  {secrets: [xenditSecret]},
  async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const requestId = readString(input, "requestId");
  const reason = readString(input, "reason");
  const db = admin.firestore();
  await requireAdmin(db, uid);
  const {ref, data} = await getServiceRequestForActor(db, requestId);
  if (data.status !== SERVICE_STATUS_DISPUTED) throw new HttpsError("failed-precondition", "Only disputed services can be force-paid.");
  await assertServiceDisputeReadyForAdminResolution(db, data);
  await ref.set({
    status: SERVICE_STATUS_COMPLETED_PAYOUT_PENDING,
    payoutStatus: SERVICE_PAYOUT_PENDING,
    adminResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    adminResolvedBy: uid,
    adminResolution: "forcePayout",
    adminResolutionReason: reason,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  await resolveServiceDisputeReport(
    db,
    String(data.disputeReportId ?? ""),
    uid,
    "forcePayout",
    reason,
  );
  await createServicePayout(db, requestId, {...data, adminResolutionReason: reason}, uid);
  await createInAppNotification(db, {
    userId: String(data.requesterId ?? ""),
    actorId: uid,
    type: NOTIFICATION_TYPE_SERVICE_ADMIN_RESOLVED,
    title: "Service dispute resolved",
    body: "Admin released the service payout to the provider.",
    category: "Services",
    serviceRequestId: requestId,
    notificationId: notificationIdFor("serviceAdminResolved", requestId, String(data.requesterId ?? "")),
  });
  return {success: true};
});

export const refundServicePayment = onCall(
  {secrets: [xenditSecret]},
  async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const requestId = readString(input, "requestId");
  const reason = readString(input, "reason");
  const db = admin.firestore();
  await requireAdmin(db, uid);
  const {ref, data} = await getServiceRequestForActor(db, requestId);
  if (data.status !== SERVICE_STATUS_DISPUTED) throw new HttpsError("failed-precondition", "Only disputed services can be refunded.");
  await assertServiceDisputeReadyForAdminResolution(db, data);
  const invoiceId = typeof data.xenditInvoiceId === "string" ? data.xenditInvoiceId : "";
  const amount = Math.max(0, toMoneyNumber(data.amount));
  if (!invoiceId || amount <= 0) throw new HttpsError("failed-precondition", "Missing service payment details.");

  if (isSimulatedSettlement()) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    await ref.set({
      status: SERVICE_STATUS_REFUNDED,
      refundStatus: REFUND_STATUS_SUCCEEDED,
      settlementMode: SETTLEMENT_MODE_SIMULATED,
      xenditRefundId: "",
      refundFailureReason: "",
      adminResolvedAt: now,
      adminResolvedBy: uid,
      adminResolution: "refund",
      adminResolutionReason: reason,
      updatedAt: now,
    }, {merge: true});
    await resolveServiceDisputeReport(
      db,
      String(data.disputeReportId ?? ""),
      uid,
      "refund",
      reason,
    );
    await createInAppNotification(db, {
      userId: String(data.requesterId ?? ""),
      actorId: uid,
      type: NOTIFICATION_TYPE_SERVICE_REFUNDED,
      title: "Service payment refunded",
      body: `Admin refunded ${moneyLabel(amount)} for "${String(data.serviceTitle ?? "your service")}" (test settlement).`,
      category: "Services",
      serviceRequestId: requestId,
      notificationId: notificationIdFor("serviceRefunded", requestId, String(data.requesterId ?? "")),
    });
    return {success: true, xenditRefundId: ""};
  }

  await ref.set({
    refundStatus: REFUND_STATUS_PENDING,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  try {
    const refund = await xenditPost("/refunds", {
      reference_id: `service_${requestId}_refund`,
      invoice_id: invoiceId,
      currency: DEFAULT_CURRENCY.toUpperCase(),
      amount: moneyToXenditAmount(amount),
      reason: "REQUESTED_BY_CUSTOMER",
      metadata: {serviceRequestId: requestId, adminId: uid},
    });
    const refundId = readString(refund, "id") || readString(refund, "refund_id");
    const refundStatus = xenditRefundStatusToAppStatus(readString(refund, "status"));
    const refundUpdate: Record<string, unknown> = {
      status: SERVICE_STATUS_REFUNDED,
      refundStatus,
      settlementMode: SETTLEMENT_MODE_LIVE,
      xenditRefundId: refundId,
      refundFailureReason: "",
      adminResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminResolvedBy: uid,
      adminResolution: "refund",
      adminResolutionReason: reason,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (refundStatus === REFUND_STATUS_SUCCEEDED) {
      refundUpdate.refundCompletedAt = admin.firestore.FieldValue.serverTimestamp();
    }
    await ref.set(refundUpdate, {merge: true});
    await resolveServiceDisputeReport(
      db,
      String(data.disputeReportId ?? ""),
      uid,
      "refund",
      reason,
    );
    await createInAppNotification(db, {
      userId: String(data.requesterId ?? ""),
      actorId: uid,
      type: NOTIFICATION_TYPE_SERVICE_REFUNDED,
      title: "Service payment refunded",
      body: `Admin refunded ${moneyLabel(amount)} for "${String(data.serviceTitle ?? "your service")}".`,
      category: "Services",
      serviceRequestId: requestId,
      notificationId: notificationIdFor("serviceRefunded", requestId, String(data.requesterId ?? "")),
    });
    return {success: true, xenditRefundId: refundId};
  } catch (error) {
    const message = safeErrorMessage(error);
    await ref.set({
      refundStatus: REFUND_STATUS_FAILED,
      refundFailureReason: message,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    throw new HttpsError("internal", message);
  }
});

function assertDepositResolutionInput(
  decision: string,
  depositAmount: number,
  deductionAmount: number,
): void {
  if (decision === RESOLUTION_FULL_REFUND && deductionAmount !== 0) {
    throw new HttpsError("invalid-argument", "Full refund cannot deduct deposit.");
  }
  if (decision === RESOLUTION_PARTIAL_DEDUCTION &&
      (deductionAmount <= 0 || deductionAmount >= depositAmount)) {
    throw new HttpsError("invalid-argument", "Partial deduction must be greater than 0 and less than the deposit.");
  }
  if (decision === RESOLUTION_FULL_DEDUCTION && deductionAmount !== depositAmount) {
    throw new HttpsError("invalid-argument", "Full deduction must equal the full deposit.");
  }
  if (![RESOLUTION_FULL_REFUND, RESOLUTION_PARTIAL_DEDUCTION, RESOLUTION_FULL_DEDUCTION].includes(decision)) {
    throw new HttpsError("invalid-argument", "Invalid deposit decision.");
  }
}

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
    return isOwner && decision === RESOLUTION_FULL_REFUND && requestData.status === BORROW_STATUS_COMPLETED;
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

function damageDecisionFor(decision: string, isAdmin: boolean): string {
  if (decision === RESOLUTION_FULL_REFUND) {
    return isAdmin ? DAMAGE_DECISION_ADMIN_FULL_REFUND : DAMAGE_DECISION_NONE;
  }
  if (decision === RESOLUTION_PARTIAL_DEDUCTION) {
    return isAdmin ? DAMAGE_DECISION_ADMIN_PARTIAL_DEDUCTION : DAMAGE_DECISION_BORROWER_ACCEPTED;
  }
  return DAMAGE_DECISION_ADMIN_FULL_DEDUCTION;
}

function depositStatusFor(decision: string): string {
  if (decision === RESOLUTION_FULL_REFUND) return DEPOSIT_STATUS_REFUNDED;
  if (decision === RESOLUTION_PARTIAL_DEDUCTION) return DEPOSIT_STATUS_PARTIALLY_REFUNDED;
  return DEPOSIT_STATUS_DEDUCTED;
}

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
    lender: `Admin awarded the ${moneyLabel(depositAmount)} deposit to you for "${itemTitle}". Your manual payout is being prepared.${note}`,
  };
}

async function notifyManualPayoutReady(
  db: admin.firestore.Firestore,
  borrowRequestId: string,
  data: {ownerId: string; itemTitle: string; lenderTotalEarning: number},
  actorId: string,
): Promise<void> {
  await createInAppNotification(db, {
    userId: data.ownerId,
    actorId,
    type: NOTIFICATION_TYPE_BORROW_PAYOUT_READY,
    title: "Payout ready",
    body: `Your ${moneyLabel(data.lenderTotalEarning)} payout for "${data.itemTitle}" is ready for admin payment.`,
    category: "Marketplace",
    borrowRequestId,
    notificationId: notificationIdFor("borrowPayoutReady", borrowRequestId, data.ownerId),
  });
}

export const resolveMarketplaceDeposit = onCall(
  {secrets: [xenditSecret]},
  async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const borrowRequestId = readString(input, "borrowRequestId");
  const decision = readString(input, "decision");
  const reason = readString(input, "reason");
  const requestedDeductionAmount = readNumber(input, "damageDeductionAmount");
  const reportId = readString(input, "reportId");
  if (!borrowRequestId) throw new HttpsError("invalid-argument", "Missing borrow request id.");

  const db = admin.firestore();
  const requestRef = db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId);
  const requestSnapshot = await requestRef.get();
  const requestData = requestSnapshot.data();
  if (!requestData) throw new HttpsError("not-found", "Borrow request was not found.");

  const adminCaller = await isAdminUser(db, uid);
  if (!adminCaller && !resolutionAllowedForParticipant(requestData, uid, decision, requestedDeductionAmount)) {
    throw new HttpsError("permission-denied", "You cannot resolve this marketplace deposit.");
  }
  if (requestData.paymentStatus !== BORROW_PAYMENT_STATUS_COMPLETED ||
      requestData.paymentProvider !== XENDIT_PROVIDER) {
    throw new HttpsError("failed-precondition", "Xendit payment must be completed before resolving deposit.");
  }

  const xenditInvoiceId = typeof requestData.xenditInvoiceId === "string" ? requestData.xenditInvoiceId : "";
  const depositAmount = Math.max(0, toMoneyNumber(requestData.depositAmount));
  const usageFeeAmount = Math.max(0, toMoneyNumber(requestData.usageFeeAmount));
  const now = admin.firestore.FieldValue.serverTimestamp();

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
      settlementMode: currentSettlementMode(),
      updatedAt: now,
    };
    await requestRef.set(noDepositUpdate, {merge: true});
    if (usageFeeAmount > 0) {
      const ownerId = typeof requestData.ownerId === "string" ? requestData.ownerId : "";
      const itemTitle = typeof requestData.itemTitle === "string" && requestData.itemTitle.trim() ?
        requestData.itemTitle.trim() :
        "your marketplace item";
      await notifyManualPayoutReady(db, borrowRequestId, {
        ownerId,
        itemTitle,
        lenderTotalEarning: usageFeeAmount,
      }, uid);
    }
    return {success: true, refundAmount: 0, payoutMode: "manual"};
  }

  const currentDepositStatus = typeof requestData.depositStatus === "string" ?
    requestData.depositStatus :
    DEPOSIT_STATUS_HELD;
  if ([DEPOSIT_STATUS_REFUNDED, DEPOSIT_STATUS_PARTIALLY_REFUNDED, DEPOSIT_STATUS_DEDUCTED].includes(currentDepositStatus)) {
    throw new HttpsError("already-exists", "Deposit is already resolved.");
  }

  const deductionAmount = decision === RESOLUTION_FULL_DEDUCTION ? depositAmount : requestedDeductionAmount;
  assertDepositResolutionInput(decision, depositAmount, deductionAmount);
  const refundAmount = Math.max(0, depositAmount - deductionAmount);
  const lenderTotalEarning = usageFeeAmount + deductionAmount;
  let xenditRefundId = "";
  let refundStatus = refundAmount > 0 ? REFUND_STATUS_PENDING : REFUND_STATUS_NOT_REQUIRED;
  let refundFailed = false;

  if (refundAmount > 0) {
    if (isSimulatedSettlement()) {
      refundStatus = REFUND_STATUS_SUCCEEDED;
      xenditRefundId = "";
    } else {
      if (!xenditInvoiceId) throw new HttpsError("failed-precondition", "Missing Xendit invoice id.");
      try {
        const refund = await xenditPost("/refunds", {
          reference_id: `borrow_${borrowRequestId}_${decision}`,
          invoice_id: xenditInvoiceId,
          currency: DEFAULT_CURRENCY.toUpperCase(),
          amount: moneyToXenditAmount(refundAmount),
          reason: "REQUESTED_BY_CUSTOMER",
          metadata: {borrowRequestId, refundType: "marketplace_deposit", decision},
        });
        xenditRefundId = readString(refund, "id");
        refundStatus = xenditRefundStatusToAppStatus(readString(refund, "status"));
      } catch (error) {
        refundFailed = true;
        await requestRef.set({
          depositStatus: DEPOSIT_STATUS_REFUND_FAILED,
          refundStatus: REFUND_STATUS_FAILED,
          refundFailureReason: safeErrorMessage(error),
          xenditFailureReason: safeErrorMessage(error),
          manualPayoutStatus: MANUAL_PAYOUT_BLOCKED,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        throw new HttpsError("internal", "Refund failed. The deposit remains blocked for admin review.");
      }
    }
  }

  const manualPayoutStatus = manualPayoutStatusAfterDepositDecision(refundFailed);

  const update: Record<string, unknown> = {
    status: BORROW_STATUS_COMPLETED,
    depositStatus: depositStatusFor(decision),
    depositHeldAmount: depositAmount,
    depositRefundAmount: refundAmount,
    damageDeductionAmount: deductionAmount,
    damageDecision: damageDecisionFor(decision, adminCaller),
    damageDecisionReason: reason,
    damageDecidedAt: now,
    refundStatus,
    refundFailureReason: "",
    xenditRefundId,
    lenderBaseEarning: usageFeeAmount,
    lenderDamageEarning: deductionAmount,
    lenderTotalEarning,
    manualPayoutStatus,
    settlementMode: currentSettlementMode(),
    updatedAt: now,
  };
  if (refundAmount > 0 &&
      (refundStatus === REFUND_STATUS_SUCCEEDED || isSimulatedSettlement())) {
    update.depositRefundedAt = now;
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

  const itemTitle = typeof requestData.itemTitle === "string" && requestData.itemTitle.trim() ?
    requestData.itemTitle.trim() :
    "your marketplace item";
  const borrowerId = typeof requestData.borrowerId === "string" ? requestData.borrowerId : "";
  const ownerId = typeof requestData.ownerId === "string" ? requestData.ownerId : "";
  const bodies = depositDecisionNotificationBodies(decision, itemTitle, depositAmount, deductionAmount, refundAmount, reason);
  await Promise.all([
    createInAppNotification(db, {
      userId: borrowerId,
      actorId: uid,
      type: NOTIFICATION_TYPE_BORROW_DEPOSIT_RESOLVED,
      title: "Deposit decision updated",
      body: bodies.borrower,
      category: "Marketplace",
      borrowRequestId,
      notificationId: notificationIdFor("borrowDepositResolved", borrowRequestId, borrowerId),
    }),
    createInAppNotification(db, {
      userId: ownerId,
      actorId: uid,
      type: NOTIFICATION_TYPE_BORROW_DEPOSIT_RESOLVED,
      title: "Deposit decision updated",
      body: bodies.lender,
      category: "Marketplace",
      borrowRequestId,
      notificationId: notificationIdFor("borrowDepositResolved", borrowRequestId, ownerId),
    }),
    update.manualPayoutStatus === MANUAL_PAYOUT_PENDING_MANUAL && lenderTotalEarning > 0 ?
      notifyManualPayoutReady(db, borrowRequestId, {ownerId, itemTitle, lenderTotalEarning}, uid) :
      Promise.resolve(),
  ]);

  return {
    success: true,
    refundAmount,
    xenditRefundId,
    payoutMode: "manual",
    settlementMode: currentSettlementMode(),
  };
});

export const markManualPayoutPaid = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const borrowRequestId = readString(input, "borrowRequestId");
  const manualPayoutReference = readString(input, "manualPayoutReference");
  const manualPayoutNote = readString(input, "manualPayoutNote");
  if (!borrowRequestId) throw new HttpsError("invalid-argument", "Missing borrow request id.");

  const db = admin.firestore();
  await requireAdmin(db, uid);
  const requestRef = db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId);
  const snapshot = await requestRef.get();
  const data = snapshot.data();
  if (!data) throw new HttpsError("not-found", "Borrow request was not found.");
  if (data.manualPayoutStatus !== MANUAL_PAYOUT_PENDING_MANUAL) {
    throw new HttpsError("failed-precondition", "Manual payout is not ready to be marked paid.");
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
  const referenceText = manualPayoutReference ? ` Reference: ${manualPayoutReference}.` : "";
  await createInAppNotification(db, {
    userId: ownerId,
    actorId: uid,
    type: NOTIFICATION_TYPE_BORROW_PAYOUT_PAID,
    title: "Manual payout marked paid",
    body: `Admin marked your ${moneyLabel(Math.max(0, toMoneyNumber(data.lenderTotalEarning)))} payout for "${itemTitle}" as paid.${referenceText}`,
    category: "Marketplace",
    borrowRequestId,
    notificationId: notificationIdFor("borrowPayoutPaid", borrowRequestId, ownerId),
  });
  return {success: true};
});

function isStuckMarketplaceSettlement(data: DocumentData): boolean {
  const depositStatus = typeof data.depositStatus === "string" ? data.depositStatus : "";
  if (!RESOLVED_DEPOSIT_STATUSES.has(depositStatus)) return false;
  if (data.manualPayoutStatus !== MANUAL_PAYOUT_BLOCKED) return false;
  return Math.max(0, toMoneyNumber(data.lenderTotalEarning)) > 0;
}

async function repairOneStuckMarketplaceSettlement(
  db: admin.firestore.Firestore,
  requestRef: admin.firestore.DocumentReference,
  data: DocumentData,
  actorId: string,
): Promise<boolean> {
  if (!isStuckMarketplaceSettlement(data)) return false;
  const now = admin.firestore.FieldValue.serverTimestamp();
  const update: Record<string, unknown> = {
    manualPayoutStatus: MANUAL_PAYOUT_PENDING_MANUAL,
    settlementMode: currentSettlementMode(),
    updatedAt: now,
  };
  if (isSimulatedSettlement() && data.refundStatus === REFUND_STATUS_PENDING) {
    update.refundStatus = REFUND_STATUS_SUCCEEDED;
    update.depositRefundedAt = now;
    update.refundFailureReason = "";
  }
  await requestRef.set(update, {merge: true});
  const ownerId = typeof data.ownerId === "string" ? data.ownerId : "";
  const itemTitle = typeof data.itemTitle === "string" && data.itemTitle.trim() ?
    data.itemTitle.trim() :
    "your marketplace item";
  const lenderTotalEarning = Math.max(0, toMoneyNumber(data.lenderTotalEarning));
  if (ownerId && lenderTotalEarning > 0) {
    await notifyManualPayoutReady(db, requestRef.id, {ownerId, itemTitle, lenderTotalEarning}, actorId);
  }
  return true;
}

export const repairStuckMarketplaceSettlement = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const db = admin.firestore();
  await requireAdmin(db, uid);
  const borrowRequestId = readString(asRecord(request.data), "borrowRequestId");

  if (borrowRequestId) {
    const requestRef = db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId);
    const snapshot = await requestRef.get();
    const data = snapshot.data();
    if (!data) throw new HttpsError("not-found", "Borrow request was not found.");
    const repaired = await repairOneStuckMarketplaceSettlement(db, requestRef, data, uid);
    return {success: true, repairedCount: repaired ? 1 : 0};
  }

  const snapshot = await db.collection(BORROW_REQUESTS_COLLECTION)
    .where("manualPayoutStatus", "==", MANUAL_PAYOUT_BLOCKED)
    .get();
  let repairedCount = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (await repairOneStuckMarketplaceSettlement(db, doc.ref, data, uid)) {
      repairedCount += 1;
    }
  }
  return {success: true, repairedCount};
});

export async function markMarketplaceDepositDisputedIfNeeded(
  db: admin.firestore.Firestore,
  borrowRequestId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): Promise<void> {
  if (!after || before?.status === BORROW_STATUS_DISPUTED) return;
  if (after.status !== BORROW_STATUS_DISPUTED) return;
  if (after.paymentProvider !== XENDIT_PROVIDER ||
      after.paymentStatus !== BORROW_PAYMENT_STATUS_COMPLETED) {
    return;
  }
  const depositAmount = Math.max(0, toMoneyNumber(after.depositAmount));
  if (depositAmount <= 0) return;
  const depositStatus = typeof after.depositStatus === "string" ? after.depositStatus : DEPOSIT_STATUS_HELD;
  if ([DEPOSIT_STATUS_REFUNDED, DEPOSIT_STATUS_PARTIALLY_REFUNDED, DEPOSIT_STATUS_DEDUCTED].includes(depositStatus)) {
    return;
  }
  await db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId).set({
    depositStatus: DEPOSIT_STATUS_DISPUTED,
    refundStatus: REFUND_STATUS_NOT_STARTED,
    manualPayoutStatus: MANUAL_PAYOUT_BLOCKED,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

export const settlementTestExports = {
  manualPayoutStatusAfterDepositDecision,
  xenditRefundStatusToAppStatus,
  isStuckMarketplaceSettlement,
  assertServiceDisputeInput,
  serviceDisputeNotificationBody,
  moneyToMinorUnits,
  expectedHourlyServiceAmountMinor,
};
