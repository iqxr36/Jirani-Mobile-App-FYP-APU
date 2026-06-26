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

function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function isVerifiedResident(data: DocumentData): boolean {
  const status = asString(data.verificationStatus);
  return (
    data.role === "resident" &&
    (status === "verified" || status === "approved")
  );
}

export function postBecamePublished(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  if (!after) return false;
  const beforeStatus = asString(before?.status);
  const afterStatus = asString(after.status);
  return beforeStatus !== "published" && afterStatus === "published";
}

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

function excerpt(body: string, maxLength = 120): string {
  const trimmed = body.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return `${trimmed.slice(0, maxLength - 1).trimEnd()}…`;
}

function notificationsAlreadySent(after: DocumentData): boolean {
  return after.notificationsSentAt != null;
}

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
