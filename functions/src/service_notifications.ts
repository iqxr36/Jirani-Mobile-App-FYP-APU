import * as admin from "firebase-admin";
import { createInAppNotification } from "./notifications";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const NOTIFICATION_TYPE_SERVICE_REQUEST = "serviceRequest";
const NOTIFICATION_TYPE_SERVICE_ACCEPTED = "serviceAccepted";
const NOTIFICATION_TYPE_SERVICE_REJECTED = "serviceRejected";

// Service notification feature: safely reads string fields from service request documents.
function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

// Service notification feature: notifies service providers/requesters when service request state changes.
export async function handleServiceRequestNotificationChanges(
  db: Firestore,
  requestId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): Promise<void> {
  if (!after) return;

  const beforeStatus = asString(before?.status);
  const afterStatus = asString(after.status);
  const providerId = asString(after.providerId);
  const requesterId = asString(after.requesterId);
  const requesterName = asString(after.requesterName).trim() || "Resident";
  const serviceTitle = asString(after.serviceTitle).trim() || "your service";

  if (!before && afterStatus === "pending" && providerId && requesterId) {
    await createInAppNotification(db, {
      userId: providerId,
      actorId: requesterId,
      type: NOTIFICATION_TYPE_SERVICE_REQUEST,
      title: requesterName,
      body: `Requested your service "${serviceTitle}".`,
      category: "Services",
      serviceRequestId: requestId,
    });
    return;
  }

  if (!requesterId || !providerId) return;

  if (beforeStatus === "pending" && afterStatus === "accepted") {
    await createInAppNotification(db, {
      userId: requesterId,
      actorId: providerId,
      type: NOTIFICATION_TYPE_SERVICE_ACCEPTED,
      title: "Service request accepted",
      body: `Your request for "${serviceTitle}" was accepted.`,
      category: "Services",
      serviceRequestId: requestId,
    });
    return;
  }

  if (beforeStatus === "pending" && afterStatus === "rejected") {
    await createInAppNotification(db, {
      userId: requesterId,
      actorId: providerId,
      type: NOTIFICATION_TYPE_SERVICE_REJECTED,
      title: "Service request declined",
      body: `Your request for "${serviceTitle}" was declined.`,
      category: "Services",
      serviceRequestId: requestId,
    });
  }
}
