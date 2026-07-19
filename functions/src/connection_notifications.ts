// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : connection_notifications.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import { createInAppNotification, residentDisplayName } from "./notifications";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const NOTIFICATION_TYPE_CONNECTION_REQUEST = "connectionRequest";
const NOTIFICATION_TYPE_CONNECTION_ACCEPTED = "connectionAccepted";

// Connection notification feature: safely reads string fields from connection documents.
function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

// Connection notification feature: notifies residents about new and accepted neighbor connection requests.
export async function handleConnectionNotificationChanges(
  db: Firestore,
  connectionId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): Promise<void> {
  if (!after) return;

  const beforeStatus = asString(before?.status);
  const afterStatus = asString(after.status);
  const fromUserId = asString(after.fromUserId);
  const toUserId = asString(after.toUserId);

  if (!before && afterStatus === "pending" && fromUserId && toUserId) {
    const senderName = await residentDisplayName(db, fromUserId);
    await createInAppNotification(db, {
      userId: toUserId,
      actorId: fromUserId,
      type: NOTIFICATION_TYPE_CONNECTION_REQUEST,
      title: senderName,
      body: "Sent you a neighbor connection request.",
      category: "Community",
      connectionId,
    });
    return;
  }

  if (
    beforeStatus === "pending" &&
    afterStatus === "accepted" &&
    fromUserId &&
    toUserId
  ) {
    const accepterName = await residentDisplayName(db, toUserId);
    await createInAppNotification(db, {
      userId: fromUserId,
      actorId: toUserId,
      type: NOTIFICATION_TYPE_CONNECTION_ACCEPTED,
      title: accepterName,
      body: "Accepted your connection request.",
      category: "Community",
      connectionId,
    });
  }
}
