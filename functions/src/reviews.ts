import * as admin from "firebase-admin";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {buildReviewDocId} from "./review_publish";

type DocumentData = admin.firestore.DocumentData;

const BORROW_REQUESTS_COLLECTION = "borrowRequests";
const REVIEWS_COLLECTION = "reviews";
const BORROW_STATUS_COMPLETED = "completed";
const REVIEW_ROLE_BORROWER_TO_OWNER = "borrowerToOwner";
const REVIEW_ROLE_OWNER_TO_BORROWER = "ownerToBorrower";
const REVIEW_STATUS_HIDDEN = "hidden";
const REVIEW_GRACE_DAYS = 3;

function requireUid(auth: {uid?: string} | undefined): string {
  const uid = auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in first.");
  return uid;
}

function asRecord(data: unknown): Record<string, unknown> {
  return data && typeof data === "object" ? data as Record<string, unknown> : {};
}

function readString(data: Record<string, unknown>, key: string): string {
  const value = data[key];
  return typeof value === "string" ? value.trim() : "";
}

function readRating(data: Record<string, unknown>): number {
  const value = data.rating;
  if (!Number.isInteger(value) || typeof value !== "number" || value < 1 || value > 5) {
    throw new HttpsError("invalid-argument", "Rating must be between 1 and 5.");
  }
  return value;
}

function publishAfterFor(data: DocumentData): admin.firestore.Timestamp {
  const base = data.completedAt instanceof admin.firestore.Timestamp ?
    data.completedAt :
    data.updatedAt instanceof admin.firestore.Timestamp ?
      data.updatedAt :
      admin.firestore.Timestamp.now();
  return admin.firestore.Timestamp.fromMillis(
    base.toMillis() + REVIEW_GRACE_DAYS * 24 * 60 * 60 * 1000,
  );
}

function reviewTargetFor(
  borrowRequest: DocumentData,
  reviewerId: string,
  role: string,
): {revieweeId: string; revieweeName: string; flagField: string; flagAtField: string} {
  if (role === REVIEW_ROLE_BORROWER_TO_OWNER) {
    if (borrowRequest.borrowerId !== reviewerId) {
      throw new HttpsError("permission-denied", "Only the borrower can submit this review.");
    }
    if (borrowRequest.borrowerReviewSubmitted === true) {
      throw new HttpsError("already-exists", "You already submitted a review for this borrow request.");
    }
    return {
      revieweeId: String(borrowRequest.ownerId ?? ""),
      revieweeName: String(borrowRequest.ownerName ?? ""),
      flagField: "borrowerReviewSubmitted",
      flagAtField: "borrowerReviewSubmittedAt",
    };
  }
  if (role === REVIEW_ROLE_OWNER_TO_BORROWER) {
    if (borrowRequest.ownerId !== reviewerId) {
      throw new HttpsError("permission-denied", "Only the owner can submit this review.");
    }
    if (borrowRequest.ownerReviewSubmitted === true) {
      throw new HttpsError("already-exists", "You already submitted a review for this borrow request.");
    }
    return {
      revieweeId: String(borrowRequest.borrowerId ?? ""),
      revieweeName: String(borrowRequest.borrowerName ?? ""),
      flagField: "ownerReviewSubmitted",
      flagAtField: "ownerReviewSubmittedAt",
    };
  }
  throw new HttpsError("invalid-argument", "Invalid review role.");
}

export const createMarketplaceReview = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = asRecord(request.data);
  const borrowRequestId = readString(input, "borrowRequestId");
  const reviewerName = readString(input, "reviewerName");
  const role = readString(input, "role");
  const comment = readString(input, "comment");
  const rating = readRating(input);

  if (!borrowRequestId) {
    throw new HttpsError("invalid-argument", "Missing borrow request id.");
  }

  const db = admin.firestore();
  const requestRef = db.collection(BORROW_REQUESTS_COLLECTION).doc(borrowRequestId);
  const reviewRef = db.collection(REVIEWS_COLLECTION).doc(buildReviewDocId(borrowRequestId, uid));

  await db.runTransaction(async (txn) => {
    const requestSnap = await txn.get(requestRef);
    const borrowRequest = requestSnap.data();
    if (!borrowRequest) {
      throw new HttpsError("not-found", "Borrow request was not found.");
    }
    if (borrowRequest.status !== BORROW_STATUS_COMPLETED) {
      throw new HttpsError("failed-precondition", "Only completed borrow requests can be reviewed.");
    }

    const target = reviewTargetFor(borrowRequest, uid, role);
    if (!target.revieweeId || target.revieweeId === uid) {
      throw new HttpsError("failed-precondition", "Review target is invalid.");
    }

    const existingReview = await txn.get(reviewRef);
    if (existingReview.exists) {
      throw new HttpsError("already-exists", "You already submitted a review for this borrow request.");
    }

    const publishAfter = publishAfterFor(borrowRequest);
    const now = admin.firestore.FieldValue.serverTimestamp();
    txn.set(reviewRef, {
      borrowRequestId,
      itemId: String(borrowRequest.itemId ?? ""),
      reviewerId: uid,
      reviewerName,
      revieweeId: target.revieweeId,
      revieweeName: target.revieweeName,
      rating,
      comment,
      role,
      visible: false,
      status: REVIEW_STATUS_HIDDEN,
      publishAfter,
      publishedAt: null,
      createdAt: now,
    });
    txn.update(requestRef, {
      [target.flagField]: true,
      [target.flagAtField]: now,
      reviewGraceEndsAt: publishAfter,
      updatedAt: now,
    });
  });

  return {
    success: true,
    reviewId: reviewRef.id,
  };
});
