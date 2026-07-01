import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {createInAppNotification} from "./notifications";

type DocumentData = admin.firestore.DocumentData;

const PAYMENTS_COLLECTION = "payments";
const USERS_COLLECTION = "users";
const ADMINS_COLLECTION = "admins";
const BORROW_REQUESTS_COLLECTION = "borrowRequests";
const REPORTS_COLLECTION = "reports";
const PAYMENT_TYPE_MARKETPLACE = "marketplace";
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

const xenditSecret = defineSecret("XENDIT_SECRET_KEY");
const xenditWebhookToken = defineSecret("XENDIT_WEBHOOK_TOKEN");

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

function readNumber(data: Record<string, unknown>, key: string): number {
  const value = data[key];
  if (value === undefined || value === null) return 0;
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new HttpsError("invalid-argument", `${key} must be a number.`);
  }
  return value;
}

function toMoneyNumber(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function moneyToXenditAmount(value: number): number {
  return Math.max(0, Math.round(value * 100) / 100);
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
  if (payment) await updateMarketplaceBorrowRequest({...payment, id: referenceId}, status);
}

export const xenditWebhook = onRequest(
  {secrets: [xenditWebhookToken]},
  async (request, response) => {
  if (!verifyXenditWebhook(request)) {
    response.status(401).send("Invalid Xendit callback token.");
    return;
  }
  try {
    await updatePaymentFromXenditEvent(asRecord(request.body));
    response.json({received: true});
  } catch (error) {
    logger.error("Failed to process Xendit webhook", {error});
    response.status(500).send("Webhook processing failed.");
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
      updatedAt: now,
    };
    await requestRef.set(noDepositUpdate, {merge: true});
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

  if (refundAmount > 0) {
    if (!xenditInvoiceId) throw new HttpsError("failed-precondition", "Missing Xendit invoice id.");
    await requestRef.set({
      refundStatus: REFUND_STATUS_PENDING,
      manualPayoutStatus: MANUAL_PAYOUT_BLOCKED,
      updatedAt: now,
    }, {merge: true});
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
      if (readString(refund, "status").toUpperCase() === "SUCCEEDED") {
        refundStatus = REFUND_STATUS_SUCCEEDED;
      }
    } catch (error) {
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
    manualPayoutStatus: refundStatus === REFUND_STATUS_PENDING ? MANUAL_PAYOUT_BLOCKED : MANUAL_PAYOUT_PENDING_MANUAL,
    updatedAt: now,
  };
  if (refundAmount > 0 && refundStatus === REFUND_STATUS_SUCCEEDED) {
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
    update.manualPayoutStatus === MANUAL_PAYOUT_PENDING_MANUAL ?
      notifyManualPayoutReady(db, borrowRequestId, {ownerId, itemTitle, lenderTotalEarning}, uid) :
      Promise.resolve(),
  ]);

  return {
    success: true,
    refundAmount,
    xenditRefundId,
    payoutMode: "manual",
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
