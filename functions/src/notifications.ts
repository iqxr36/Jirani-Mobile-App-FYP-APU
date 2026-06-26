import * as admin from "firebase-admin";
import { getMessaging } from "firebase-admin/messaging";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

export type InAppNotificationInput = {
  userId: string;
  actorId: string;
  type: string;
  title: string;
  body: string;
  category?: string;
  chatId?: string;
  senderId?: string;
  connectionId?: string;
  borrowRequestId?: string;
  serviceRequestId?: string;
  postId?: string;
  notificationId?: string;
};

export async function residentDisplayName(
  db: Firestore,
  uid: string,
): Promise<string> {
  const publicSnap = await db.collection("publicProfiles").doc(uid).get();
  if (publicSnap.exists) {
    const fullName = publicSnap.data()?.fullName;
    if (typeof fullName === "string" && fullName.trim().length > 0) {
      return fullName.trim();
    }
  }

  const userSnap = await db.collection("users").doc(uid).get();
  const data = userSnap.data();
  if (!data) return "Resident";

  if (typeof data.fullName === "string" && data.fullName.trim().length > 0) {
    return data.fullName.trim();
  }

  const firstName = typeof data.firstName === "string" ? data.firstName : "";
  const lastName = typeof data.lastName === "string" ? data.lastName : "";
  const combined = `${firstName} ${lastName}`.trim();
  return combined.length > 0 ? combined : "Resident";
}

export function communityPostNotificationId(
  postId: string,
  userId: string,
): string {
  return `cp_${postId}_${userId}`.replace(/\//g, "_");
}

function buildNotificationPayload(input: InAppNotificationInput): DocumentData {
  const payload: DocumentData = {
    userId: input.userId,
    actorId: input.actorId,
    type: input.type,
    title: input.title.trim(),
    body: input.body.trim(),
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (input.category?.trim()) payload.category = input.category.trim();
  if (input.chatId) payload.chatId = input.chatId;
  if (input.senderId) payload.senderId = input.senderId;
  if (input.connectionId) payload.connectionId = input.connectionId;
  if (input.borrowRequestId) payload.borrowRequestId = input.borrowRequestId;
  if (input.serviceRequestId) payload.serviceRequestId = input.serviceRequestId;
  if (input.postId) payload.postId = input.postId;

  return payload;
}

function isAlreadyExistsError(error: unknown): boolean {
  const code = (error as { code?: number | string }).code;
  return code === 6 || code === "already-exists" || code === "ALREADY_EXISTS";
}

export async function createInAppNotificationIfAbsent(
  db: Firestore,
  notificationId: string,
  input: InAppNotificationInput,
): Promise<string | null> {
  if (!input.userId || input.userId === input.actorId) {
    return null;
  }

  const ref = db.collection("notifications").doc(notificationId);
  const payload = buildNotificationPayload(input);

  try {
    await ref.create(payload);
    return ref.id;
  } catch (error) {
    if (isAlreadyExistsError(error)) {
      return ref.id;
    }
    throw error;
  }
}

export async function createInAppNotification(
  db: Firestore,
  input: InAppNotificationInput,
): Promise<string | null> {
  if (!input.userId || input.userId === input.actorId) {
    return null;
  }

  if (input.notificationId) {
    return createInAppNotificationIfAbsent(db, input.notificationId, input);
  }

  const payload = buildNotificationPayload(input);
  const ref = await db.collection("notifications").add(payload);
  return ref.id;
}

export async function sendFcmForNotification(
  db: Firestore,
  notification: DocumentData,
): Promise<void> {
  const userId = notification.userId;
  if (typeof userId !== "string" || userId.length === 0) return;

  const userSnap = await db.collection("users").doc(userId).get();
  const fcmToken = userSnap.data()?.fcmToken;
  if (typeof fcmToken !== "string" || fcmToken.trim().length === 0) {
    return;
  }

  const title =
    typeof notification.title === "string" ? notification.title : "Jirani";
  const body = typeof notification.body === "string" ? notification.body : "";

  const data: Record<string, string> = {
    type: typeof notification.type === "string" ? notification.type : "",
  };
  if (typeof notification.chatId === "string" && notification.chatId) {
    data.chatId = notification.chatId;
  }
  if (
    typeof notification.borrowRequestId === "string" &&
    notification.borrowRequestId
  ) {
    data.borrowRequestId = notification.borrowRequestId;
  }
  if (
    typeof notification.serviceRequestId === "string" &&
    notification.serviceRequestId
  ) {
    data.serviceRequestId = notification.serviceRequestId;
  }
  if (typeof notification.connectionId === "string" && notification.connectionId) {
    data.connectionId = notification.connectionId;
  }
  if (typeof notification.postId === "string" && notification.postId) {
    data.postId = notification.postId;
  }

  try {
    await getMessaging().send({
      token: fcmToken.trim(),
      notification: { title, body },
      data,
    });
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (code === "messaging/registration-token-not-registered") {
      await db.collection("users").doc(userId).update({
        fcmToken: admin.firestore.FieldValue.delete(),
      });
      return;
    }
    throw error;
  }
}
