// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : community_post_notifications.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import {
  communityPostNotificationId,
  createInAppNotificationIfAbsent,
} from "./notifications";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const NOTIFICATION_TYPE_COMMUNITY_NEWS = "communityNews";
const NOTIFICATION_TYPE_COMMUNITY_ANNOUNCEMENT = "communityAnnouncement";
const NOTIFICATION_TYPE_COMMUNITY_WARNING = "communityWarning";
const NOTIFICATION_TYPE_COMMUNITY_EVENT = "communityEvent";
const NOTIFICATION_TYPE_MAINTENANCE_NOTICE = "maintenanceNotice";

const FAN_OUT_BATCH_SIZE = 100;

// Community post notification feature: safely reads string fields from post and user documents.
function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

// Community post notification feature: only sends published post notifications to verified residents.
function isVerifiedResident(data: DocumentData): boolean {
  const status = asString(data.verificationStatus);
  return (
    data.role === "resident" &&
    (status === "verified" || status === "approved")
  );
}

// Community post notification feature: detects the first transition from draft/scheduled to published.
export function postBecamePublished(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  if (!after) return false;
  const beforeStatus = asString(before?.status);
  const afterStatus = asString(after.status);
  return beforeStatus !== "published" && afterStatus === "published";
}

// Community post notification feature: maps post category to the resident notification type.
export function notificationTypeForPostType(type: string): string {
  switch (type) {
    case "announcement":
      return NOTIFICATION_TYPE_COMMUNITY_ANNOUNCEMENT;
    case "warning":
      return NOTIFICATION_TYPE_COMMUNITY_WARNING;
    case "event":
      return NOTIFICATION_TYPE_COMMUNITY_EVENT;
    case "maintenance":
      return NOTIFICATION_TYPE_MAINTENANCE_NOTICE;
    default:
      return NOTIFICATION_TYPE_COMMUNITY_NEWS;
  }
}

// Community post notification feature: maps post type to the display category shown in the notification inbox.
function categoryForPostType(type: string): string {
  switch (type) {
    case "announcement":
      return "Announcements";
    case "warning":
      return "Warnings";
    case "event":
      return "Events";
    case "maintenance":
      return "Maintenance";
    default:
      return "News";
  }
}

// Community post notification feature: shortens long post bodies for notification preview text.
function excerpt(body: string, maxLength = 120): string {
  const trimmed = body.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return `${trimmed.slice(0, maxLength - 1).trimEnd()}…`;
}

// Community post notification feature: prevents duplicate fan-out when a published post is edited again.
function notificationsAlreadySent(after: DocumentData): boolean {
  return after.notificationsSentAt != null;
}

// Community post notification feature: creates deterministic notifications in small batches for all recipients.
async function fanOutNotifications(
  db: Firestore,
  postId: string,
  actorId: string,
  notificationType: string,
  category: string,
  title: string,
  body: string,
  recipientIds: string[],
): Promise<void> {
  for (let index = 0; index < recipientIds.length; index += FAN_OUT_BATCH_SIZE) {
    const batch = recipientIds.slice(index, index + FAN_OUT_BATCH_SIZE);
    await Promise.all(
      batch.map((userId) =>
        createInAppNotificationIfAbsent(
          db,
          communityPostNotificationId(postId, userId),
          {
            userId,
            actorId,
            type: notificationType,
            title,
            body,
            category,
            postId,
          },
        ),
      ),
    );
  }
}

// Community post notification feature: fans out notifications when an admin publishes a community post.
export async function handleCommunityPostNotificationChanges(
  db: Firestore,
  postId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): Promise<void> {
  if (!postBecamePublished(before, after) || !after) return;
  if (notificationsAlreadySent(after)) return;

  const communityId = asString(after.communityId);
  const authorId = asString(after.authorId);
  if (!communityId) return;

  const actorId = authorId || `community:${communityId}`;
  const title = asString(after.title).trim() || "Community update";
  const body = excerpt(asString(after.body));
  const postType = asString(after.type);
  const notificationType = notificationTypeForPostType(postType);
  const category = categoryForPostType(postType);
  const notificationBody = body.length > 0 ? body : title;

  const residents = await db
    .collection("users")
    .where("communityId", "==", communityId)
    .get();

  const recipientIds = residents.docs
    .filter((doc) => isVerifiedResident(doc.data()))
    .map((doc) => doc.id);

  await fanOutNotifications(
    db,
    postId,
    actorId,
    notificationType,
    category,
    title,
    notificationBody,
    recipientIds,
  );

  await db.collection("communityPosts").doc(postId).update({
    notificationsSentAt: admin.firestore.FieldValue.serverTimestamp(),
    notificationRecipientCount: recipientIds.length,
  });
}
