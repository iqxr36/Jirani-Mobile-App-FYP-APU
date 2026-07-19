// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : borrow_notifications.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import { createInAppNotification } from "./notifications";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const NOTIFICATION_TYPE_BORROW_REQUEST = "borrowRequest";
const NOTIFICATION_TYPE_BORROW_APPROVED = "borrowApproved";
const NOTIFICATION_TYPE_BORROW_REJECTED = "borrowRejected";

// Borrow notification feature: safely reads string fields from borrow request documents.
function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

// Borrow notification feature: notifies the lender when a borrower creates a new pending request.
export async function notifyBorrowRequestCreated(
  db: Firestore,
  requestId: string,
  data: DocumentData,
): Promise<void> {
  const ownerId = asString(data.ownerId);
  const borrowerId = asString(data.borrowerId);
  const borrowerName = asString(data.borrowerName).trim() || "Resident";
  const itemTitle = asString(data.itemTitle).trim() || "your item";

  if (!ownerId || !borrowerId) return;

  await createInAppNotification(db, {
    userId: ownerId,
    actorId: borrowerId,
    type: NOTIFICATION_TYPE_BORROW_REQUEST,
    title: borrowerName,
    body: `Requested to borrow "${itemTitle}".`,
    category: "Marketplace",
    borrowRequestId: requestId,
  });
}

// Borrow notification feature: sends approval/rejection notifications when borrow request status changes.
export async function handleBorrowRequestNotificationChanges(
  db: Firestore,
  requestId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): Promise<void> {
  if (!after) return;

  const beforeStatus = asString(before?.status);
  const afterStatus = asString(after.status);
  const borrowerId = asString(after.borrowerId);
  const ownerId = asString(after.ownerId);
  const itemTitle = asString(after.itemTitle).trim() || "the item";

  if (!before && afterStatus === "pending") {
    await notifyBorrowRequestCreated(db, requestId, after);
    return;
  }

  if (beforeStatus === "pending" && afterStatus === "approved" && borrowerId) {
    await createInAppNotification(db, {
      userId: borrowerId,
      actorId: ownerId,
      type: NOTIFICATION_TYPE_BORROW_APPROVED,
      title: "Borrow request approved",
      body: `Your request for "${itemTitle}" was approved.`,
      category: "Marketplace",
      borrowRequestId: requestId,
    });
    return;
  }

  if (beforeStatus === "pending" && afterStatus === "rejected" && borrowerId) {
    await createInAppNotification(db, {
      userId: borrowerId,
      actorId: ownerId,
      type: NOTIFICATION_TYPE_BORROW_REJECTED,
      title: "Borrow request declined",
      body: `Your request for "${itemTitle}" was declined.`,
      category: "Marketplace",
      borrowRequestId: requestId,
    });
  }
}
