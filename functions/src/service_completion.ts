// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : service_completion.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,09-July-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import {logger} from "firebase-functions";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const COMPLETED_SERVICE_STATUSES = new Set([
  "completed",
  "completedPayoutPending",
  "completedPayoutSent",
]);

// Service completion feature: detects the first transition of a service request into any completed status.
export function serviceBecameCompleted(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  if (!after) return false;
  const beforeStatus = typeof before?.status === "string" ? before.status : "";
  const afterStatus = typeof after.status === "string" ? after.status : "";
  return !COMPLETED_SERVICE_STATUSES.has(beforeStatus) &&
    COMPLETED_SERVICE_STATUSES.has(afterStatus);
}

// Service completion feature: increments provider/requester service counters once per completed request.
export async function applyServiceCompletionSideEffects(
  db: Firestore,
  requestId: string,
  data: DocumentData,
): Promise<void> {
  const providerId = data.providerId;
  const requesterId = data.requesterId;
  if (typeof providerId !== "string" || typeof requesterId !== "string") {
    logger.warn("Skipped service completion side effects: missing participant ids", {
      requestId,
      providerId,
      requesterId,
    });
    return;
  }

  logger.info("Applying service completion side effects", {
    requestId,
    providerId,
    requesterId,
    status: data.status,
  });

  await db.runTransaction(async (txn) => {
    const requestRef = db.collection("serviceRequests").doc(requestId);
    const providerRef = db.collection("users").doc(providerId);
    const requesterRef = db.collection("users").doc(requesterId);

    const [requestSnap, providerSnap, requesterSnap] = await Promise.all([
      txn.get(requestRef),
      txn.get(providerRef),
      txn.get(requesterRef),
    ]);

    if (!requestSnap.exists) {
      logger.warn("Skipped service completion side effects: request missing", {requestId});
      return;
    }
    const requestData = requestSnap.data()!;
    if (!COMPLETED_SERVICE_STATUSES.has(String(requestData.status ?? ""))) {
      logger.info("Skipped service completion side effects: request not completed", {
        requestId,
        status: requestData.status,
      });
      return;
    }

    if (requestData.lastCompletedServiceStatsRequestId === requestId) {
      logger.info("Skipped service completion side effects: already counted", {requestId});
      return;
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    txn.update(requestRef, {
      lastCompletedServiceStatsRequestId: requestId,
      updatedAt: now,
    });

    if (providerSnap.exists) {
      txn.update(providerRef, {
        completedServices: admin.firestore.FieldValue.increment(1),
        completedServicesProvided: admin.firestore.FieldValue.increment(1),
        lastCompletedServiceStatsRequestId: requestId,
        updatedAt: now,
      });
    } else {
      logger.warn("Skipped provider service counter increment: user missing", {
        requestId,
        providerId,
      });
    }

    if (requesterSnap.exists && requesterId !== providerId) {
      txn.update(requesterRef, {
        completedServices: admin.firestore.FieldValue.increment(1),
        completedServicesRequested: admin.firestore.FieldValue.increment(1),
        lastCompletedServiceStatsRequestId: requestId,
        updatedAt: now,
      });
    } else if (!requesterSnap.exists) {
      logger.warn("Skipped requester service counter increment: user missing", {
        requestId,
        requesterId,
      });
    }
  });

  logger.info("Applied service completion side effects", {
    requestId,
    providerId,
    requesterId,
  });
}
