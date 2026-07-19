// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : notifications.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import { getMessaging } from "firebase-admin/messaging";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

// Notification feature: common input shape used by all backend notification helpers.
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
  itemId?: string;
  serviceId?: string;
  verificationRequestId?: string;
  residentId?: string;
  reportId?: string;
  communityId?: string;
  ocrDecision?: string;
  notificationId?: string;
};

// Notification feature: resolves the best display name for a resident from publicProfiles or users.
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

// Community post notification feature: builds deterministic IDs so fan-out retries do not duplicate notifications.
export function communityPostNotificationId(
  postId: string,
  userId: string,
): string {
  return `cp_${postId}_${userId}`.replace(/\//g, "_");
}

// Notification feature: converts a typed notification input into the Firestore notifications payload.
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
  if (input.itemId) payload.itemId = input.itemId;
  if (input.serviceId) payload.serviceId = input.serviceId;
  if (input.verificationRequestId) {
    payload.verificationRequestId = input.verificationRequestId;
  }
  if (input.residentId) payload.residentId = input.residentId;
  if (input.reportId) payload.reportId = input.reportId;
  if (input.communityId) payload.communityId = input.communityId;
  if (input.ocrDecision) payload.ocrDecision = input.ocrDecision;

  return payload;
}

// Notification feature: detects idempotent-create conflicts from Firestore.
function isAlreadyExistsError(error: unknown): boolean {
  const code = (error as { code?: number | string }).code;
  return code === 6 || code === "already-exists" || code === "ALREADY_EXISTS";
}

// Notification feature: creates a notification with a fixed id and treats duplicate retries as success.
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

// Notification feature: creates an in-app notification unless it would notify the actor about their own action.
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

// Push notification feature: sends FCM for a created notification and clears invalid device tokens.
export async function sendFcmForNotification(
  db: Firestore,
  notification: DocumentData,
): Promise<void> {
  const userId = notification.userId;
  if (typeof userId !== "string" || userId.length === 0) return;

  const userSnap = await db.collection("users").doc(userId).get();
  const userData = userSnap.data();
  if (userData?.notificationEnabled === false) {
    return;
  }

  const notificationType =
    typeof notification.type === "string" ? notification.type : "";
  if (
    (notificationType === "neighborNewItem" ||
      notificationType === "neighborNewService" ||
      notificationType === "neighborTrustWarning") &&
    userData?.neighborUpdatesEnabled === false
  ) {
    return;
  }

  const fcmToken = userData?.fcmToken;
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
  if (typeof notification.itemId === "string" && notification.itemId) {
    data.itemId = notification.itemId;
  }
  if (typeof notification.serviceId === "string" && notification.serviceId) {
    data.serviceId = notification.serviceId;
  }
  if (typeof notification.residentId === "string" && notification.residentId) {
    data.residentId = notification.residentId;
  }
  if (
    typeof notification.verificationRequestId === "string" &&
    notification.verificationRequestId
  ) {
    data.verificationRequestId = notification.verificationRequestId;
  }
  if (typeof notification.reportId === "string" && notification.reportId) {
    data.reportId = notification.reportId;
  }
  if (typeof notification.ocrDecision === "string" && notification.ocrDecision) {
    data.ocrDecision = notification.ocrDecision;
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
