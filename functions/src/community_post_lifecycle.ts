import * as admin from "firebase-admin";
import {logger} from "firebase-functions";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;
type Timestamp = admin.firestore.Timestamp;

const STATUS_DRAFT = "draft";
const STATUS_PUBLISHED = "published";
const STATUS_EXPIRED = "expired";
const DURATION_ONE_DAY = "oneDay";
const DURATION_ONE_MONTH = "oneMonth";

function asTimestamp(value: unknown): Timestamp | null {
  return value instanceof admin.firestore.Timestamp ? value : null;
}

function asDuration(value: unknown): string {
  return typeof value === "string" ? value : "oneWeek";
}

function expiresAtFor(publishedAt: Date, duration: string): Date {
  if (duration === DURATION_ONE_DAY) {
    return new Date(publishedAt.getTime() + 24 * 60 * 60 * 1000);
  }
  if (duration === DURATION_ONE_MONTH) {
    const expiry = new Date(publishedAt);
    expiry.setMonth(expiry.getMonth() + 1);
    return expiry;
  }
  return new Date(publishedAt.getTime() + 7 * 24 * 60 * 60 * 1000);
}

function isDueDraft(data: DocumentData, now: Timestamp): boolean {
  if (data.status !== STATUS_DRAFT) return false;
  const scheduledAt = asTimestamp(data.scheduledPublishAt);
  return scheduledAt != null && scheduledAt.toMillis() <= now.toMillis();
}

function isExpiredPost(data: DocumentData, now: Timestamp): boolean {
  if (data.status !== STATUS_PUBLISHED) return false;
  const expiresAt = asTimestamp(data.expiresAt);
  return expiresAt != null && expiresAt.toMillis() <= now.toMillis();
}

export async function processCommunityPostLifecycle(
  db: Firestore,
): Promise<{published: number; expired: number}> {
  const now = admin.firestore.Timestamp.now();
  const nowDate = now.toDate();
  const snapshot = await db.collection("communityPosts").get();
  const batch = db.batch();
  let published = 0;
  let expired = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (isDueDraft(data, now)) {
      const duration = asDuration(data.publishDuration);
      batch.update(doc.ref, {
        status: STATUS_PUBLISHED,
        publishedAt: now,
        expiresAt: admin.firestore.Timestamp.fromDate(
          expiresAtFor(nowDate, duration),
        ),
        publishDuration: duration,
        updatedAt: now,
      });
      published++;
      continue;
    }

    if (isExpiredPost(data, now)) {
      batch.update(doc.ref, {
        status: STATUS_EXPIRED,
        publishedAt: null,
        scheduledPublishAt: null,
        expiresAt: null,
        expiredAt: now,
        updatedAt: now,
      });
      expired++;
    }
  }

  if (published > 0 || expired > 0) {
    await batch.commit();
    logger.info("Processed community post lifecycle", {published, expired});
  }

  return {published, expired};
}
