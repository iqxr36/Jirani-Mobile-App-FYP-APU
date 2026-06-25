import * as admin from "firebase-admin";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

export function buildReviewDocId(
  borrowRequestId: string,
  reviewerId: string,
): string {
  return `${borrowRequestId.replace(/\//g, "_")}_${reviewerId}`;
}

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

function isGraceExpired(publishAfter: unknown): boolean {
  if (!(publishAfter instanceof admin.firestore.Timestamp)) return false;
  return publishAfter.toMillis() <= Date.now();
}

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
