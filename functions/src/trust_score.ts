import * as admin from "firebase-admin";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const TRUSTED_RESIDENT_THRESHOLD = 4.5;
const LOW_TRUST_THRESHOLD = 3.5;
const TRUSTED_RESIDENT_MINIMUM_REVIEWS = 3;

const REVIEW_ROLE_OWNER_TO_BORROWER = "ownerToBorrower";
const BORROW_CONDITION_AFTER_SAME = "sameCondition";
const REPORT_TYPE_DAMAGED_ITEM = "damagedItem";
const REPORT_TYPE_USER_MISCONDUCT = "userMisconduct";
const REPORT_STATUS_OPEN = "open";

type ReviewData = {
  borrowRequestId?: string;
  revieweeId?: string;
  revieweeName?: string;
  reviewerName?: string;
  rating?: number;
  comment?: string;
  role?: string;
  visible?: boolean;
  status?: string;
  createdAt?: admin.firestore.Timestamp;
};

type BorrowRequestData = {
  itemId?: string;
  itemConditionAfter?: string;
};

function displayName(data: DocumentData | undefined): string {
  if (!data) return "Resident";
  const fullName = typeof data.fullName === "string" ? data.fullName.trim() : "";
  if (fullName) return fullName;
  const first = typeof data.firstName === "string" ? data.firstName.trim() : "";
  const last = typeof data.lastName === "string" ? data.lastName.trim() : "";
  const combined = `${first} ${last}`.trim();
  return combined || "Resident";
}

function reviewCreatedAt(review: ReviewData): Date {
  const createdAt = review.createdAt;
  if (createdAt instanceof admin.firestore.Timestamp) {
    return createdAt.toDate();
  }
  return new Date();
}

export async function recalculateTrustScoreForUser(
  db: Firestore,
  userId: string,
  triggerReviewId: string,
): Promise<void> {
  const reviewsSnap = await db
    .collection("reviews")
    .where("revieweeId", "==", userId)
    .where("visible", "==", true)
    .get();

  if (reviewsSnap.empty) {
    return;
  }

  const now = new Date();
  let weightedTotal = 0;
  let weightSum = 0;

  for (const doc of reviewsSnap.docs) {
    const review = doc.data() as ReviewData;
    const rating = typeof review.rating === "number" ? review.rating : 0;
    const createdAt = reviewCreatedAt(review);
    const ageDays = Math.min(
      3650,
      Math.max(0, Math.floor((now.getTime() - createdAt.getTime()) / 86_400_000)),
    );
    const weight = 1 / (1 + ageDays / 90);
    weightedTotal += rating * weight;
    weightSum += weight;
  }

  const totalReviews = reviewsSnap.size;
  const trustScore = weightSum === 0 ? 0 : weightedTotal / weightSum;
  const trustedResident =
    trustScore >= TRUSTED_RESIDENT_THRESHOLD &&
    totalReviews >= TRUSTED_RESIDENT_MINIMUM_REVIEWS;
  const accountFlagged = trustScore < LOW_TRUST_THRESHOLD;
  const flagReason = accountFlagged
    ? `Community Trust Score dropped below ${LOW_TRUST_THRESHOLD.toFixed(1)}.`
    : "";

  await db.collection("users").doc(userId).update({
    reputationScore: trustScore,
    communityTrustScore: trustScore,
    totalReviews,
    trustedResident,
    accountFlagged,
    trustFlagReason: flagReason,
    lastTrustReviewId: triggerReviewId,
    trustScoreUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  if (accountFlagged) {
    await createLowTrustReportIfNeeded(db, userId, trustScore, totalReviews);
  }
}

export async function createDamageReportIfNeeded(
  db: Firestore,
  reviewId: string,
  review: ReviewData,
): Promise<void> {
  const borrowRequestId = review.borrowRequestId ?? "";
  if (!borrowRequestId) return;

  const borrowSnap = await db.collection("borrowRequests").doc(borrowRequestId).get();
  const borrow = borrowSnap.data() as BorrowRequestData | undefined;
  if (!borrow) return;

  const looksLikeDamageCase =
    review.rating === 1 &&
    review.role === REVIEW_ROLE_OWNER_TO_BORROWER &&
    borrow.itemConditionAfter !== BORROW_CONDITION_AFTER_SAME;
  if (!looksLikeDamageCase) return;

  const revieweeId = review.revieweeId ?? "";
  const revieweeName = review.revieweeName ?? "Resident";
  const reviewerName = review.reviewerName ?? "Resident";
  const comment = (review.comment ?? "").trim();

  await createAdminReportIfNeeded(db, {
    reportId: `trust_damage_${reviewId}`,
    type: REPORT_TYPE_DAMAGED_ITEM,
    relatedBorrowRequestId: borrowRequestId,
    itemId: borrow.itemId ?? "",
    reportedUserId: revieweeId,
    reportedUserName: revieweeName,
    title: "1-star damage review",
    description: `${reviewerName} rated ${revieweeName} 1 star after an item return issue. Comment: ${
      comment || "No comment provided."
    }`,
    communityId: "",
    communityName: "",
  });
}

async function createLowTrustReportIfNeeded(
  db: Firestore,
  reportedUserId: string,
  trustScore: number,
  totalReviews: number,
): Promise<void> {
  const reportedSnap = await db.collection("users").doc(reportedUserId).get();
  const reported = reportedSnap.data();
  const reportedName = displayName(reported);

  await createAdminReportIfNeeded(db, {
    reportId: `trust_low_${reportedUserId}`,
    type: REPORT_TYPE_USER_MISCONDUCT,
    relatedBorrowRequestId: "",
    itemId: "",
    reportedUserId,
    reportedUserName: reportedName,
    title: "Low Community Trust Score",
    description: `${reportedName} has a Community Trust Score of ${trustScore.toFixed(
      2,
    )} from ${totalReviews} published reviews.`,
    communityId: typeof reported?.communityId === "string" ? reported.communityId : "",
    communityName:
      typeof reported?.communityName === "string" ? reported.communityName : "",
  });
}

async function createAdminReportIfNeeded(
  db: Firestore,
  input: {
    reportId: string;
    type: string;
    relatedBorrowRequestId: string;
    itemId: string;
    reportedUserId: string;
    reportedUserName: string;
    title: string;
    description: string;
    communityId: string;
    communityName: string;
  },
): Promise<void> {
  const reportRef = db.collection("reports").doc(input.reportId);
  const existing = await reportRef.get();
  if (existing.exists) {
    return;
  }

  await reportRef.set({
    type: input.type,
    relatedBorrowRequestId: input.relatedBorrowRequestId,
    itemId: input.itemId,
    reporterId: "system",
    reporterName: "Automated",
    reportedUserId: input.reportedUserId,
    reportedUserName: input.reportedUserName,
    communityId: input.communityId,
    communityName: input.communityName,
    title: input.title,
    description: input.description,
    status: REPORT_STATUS_OPEN,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export function reviewBecamePublished(
  before: ReviewData | undefined,
  after: ReviewData | undefined,
): boolean {
  if (!before || !after) return false;
  const wasPublished = before.visible === true && before.status === "published";
  const isPublished = after.visible === true && after.status === "published";
  return !wasPublished && isPublished;
}
