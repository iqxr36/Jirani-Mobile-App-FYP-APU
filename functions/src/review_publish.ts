// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : review_publish.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

// Review feature: builds deterministic review IDs so each user can review a borrow request only once.
export function buildReviewDocId(
  borrowRequestId: string,
  reviewerId: string,
): string {
  return `${borrowRequestId.replace(/\//g, "_")}_${reviewerId}`;
}

// Service review feature: deterministic IDs prevent duplicate requester reviews for a service job.
export function buildServiceReviewDocId(
  serviceRequestId: string,
  reviewerId: string,
): string {
  return `service_${serviceRequestId.replace(/\//g, "_")}_${reviewerId}`;
}

// Review feature: detects when a completed borrow request has a newly submitted hidden review to publish.
export function shouldAttemptPublishAfterBorrowUpdate(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  if (!after || after.status !== "completed") return false;
  if (after.reviewsPublishedAt) return false;

  const borrowerJustSubmitted =
    after.borrowerReviewSubmitted === true &&
    before?.borrowerReviewSubmitted !== true;
  const ownerJustSubmitted =
    after.ownerReviewSubmitted === true &&
    before?.ownerReviewSubmitted !== true;

  return borrowerJustSubmitted || ownerJustSubmitted;
}

// Review feature: checks whether the private review waiting period has ended.
function isGraceExpired(publishAfter: unknown): boolean {
  if (!(publishAfter instanceof admin.firestore.Timestamp)) return false;
  return publishAfter.toMillis() <= Date.now();
}

// Review feature: publishes hidden reviews when both parties reviewed or the grace period expired.
export async function publishEligibleReviewsForBorrowRequest(
  db: Firestore,
  borrowRequestId: string,
): Promise<void> {
  const reqRef = db.collection("borrowRequests").doc(borrowRequestId);

  await db.runTransaction(async (txn) => {
    const reqSnap = await txn.get(reqRef);
    if (!reqSnap.exists) return;

    const reqData = reqSnap.data()!;
    if (reqData.status !== "completed") return;
    if (reqData.reviewsPublishedAt) return;

    const borrowerSubmitted = reqData.borrowerReviewSubmitted === true;
    const ownerSubmitted = reqData.ownerReviewSubmitted === true;
    if (!borrowerSubmitted && !ownerSubmitted) return;

    const hasBothReviews = borrowerSubmitted && ownerSubmitted;
    const graceExpired = isGraceExpired(reqData.reviewGraceEndsAt);
    if (!hasBothReviews && !graceExpired) return;

    const reviewerIds: string[] = [];
    if (borrowerSubmitted && typeof reqData.borrowerId === "string") {
      reviewerIds.push(reqData.borrowerId);
    }
    if (ownerSubmitted && typeof reqData.ownerId === "string") {
      reviewerIds.push(reqData.ownerId);
    }

    const pendingReviewRefs: FirebaseFirestore.DocumentReference[] = [];

    for (const reviewerId of reviewerIds) {
      const reviewRef = db
        .collection("reviews")
        .doc(buildReviewDocId(borrowRequestId, reviewerId));
      const reviewSnap = await txn.get(reviewRef);
      if (!reviewSnap.exists) continue;

      const reviewData = reviewSnap.data()!;
      if (reviewData.visible === true && reviewData.status === "published") {
        continue;
      }
      if (reviewData.visible !== false || reviewData.status !== "hidden") {
        continue;
      }
      pendingReviewRefs.push(reviewRef);
    }

    if (pendingReviewRefs.length === 0) return;

    for (const reviewRef of pendingReviewRefs) {
      txn.update(reviewRef, {
        visible: true,
        status: "published",
        publishedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    txn.update(reqRef, {
      reviewsPublishedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

// Review feature: scheduled job publishes reviews whose grace period expired without both parties reviewing.
export async function publishGraceExpiredBorrowReviews(
  db: Firestore,
  batchSize = 100,
): Promise<number> {
  const now = admin.firestore.Timestamp.now();
  const snapshot = await db
    .collection("borrowRequests")
    .where("status", "==", "completed")
    .where("reviewGraceEndsAt", "<=", now)
    .limit(batchSize)
    .get();

  let processed = 0;
  for (const docSnap of snapshot.docs) {
    const data = docSnap.data();
    if (data.reviewsPublishedAt) continue;
    if (!data.borrowerReviewSubmitted && !data.ownerReviewSubmitted) continue;
    await publishEligibleReviewsForBorrowRequest(db, docSnap.id);
    processed += 1;
  }
  return processed;
}
