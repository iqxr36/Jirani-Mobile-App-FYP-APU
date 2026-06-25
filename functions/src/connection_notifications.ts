import * as admin from "firebase-admin";
import { createInAppNotification, residentDisplayName } from "./notifications";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const NOTIFICATION_TYPE_CONNECTION_REQUEST = "connectionRequest";
const NOTIFICATION_TYPE_CONNECTION_ACCEPTED = "connectionAccepted";

function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

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
