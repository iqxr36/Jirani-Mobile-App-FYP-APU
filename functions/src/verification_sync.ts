import * as admin from "firebase-admin";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

function hasUploadedDocument(data: DocumentData): boolean {
  const documentUrl = data.documentUrl;
  return typeof documentUrl === "string" && documentUrl.trim().length > 0;
}

export function verificationRequestReadyForUserSync(
  data: DocumentData | undefined,
): boolean {
  if (!data) return false;
  return data.status === "submitted" && hasUploadedDocument(data);
}

export function verificationRequestBecameReady(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  return (
    !verificationRequestReadyForUserSync(before) &&
    verificationRequestReadyForUserSync(after)
  );
}

export function verificationRequestBecameCancelled(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  if (!before || !after) return false;
  return before.status !== "cancelled" && after.status === "cancelled";
}

export async function syncUserFromSubmittedVerificationRequest(
  db: Firestore,
  data: DocumentData,
): Promise<void> {
  const userId = data.userId;
  if (typeof userId !== "string" || userId.length === 0) return;

  const userRef = db.collection("users").doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return;

  const currentStatus = userSnap.data()?.verificationStatus;
  if (currentStatus === "verified") return;

  const updates: DocumentData = {
    verificationStatus: "submitted",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (typeof data.communityId === "string" && data.communityId.length > 0) {
    updates.communityId = data.communityId;
  }
  if (typeof data.communityName === "string") {
    updates.communityName = data.communityName;
  }
  if (typeof data.unitNumber === "string") {
    updates.unitNumber = data.unitNumber;
  }

  await userRef.update(updates);
}

export async function syncUserFromCancelledVerificationRequest(
  db: Firestore,
  data: DocumentData,
): Promise<void> {
  const userId = data.userId;
  if (typeof userId !== "string" || userId.length === 0) return;

  const userRef = db.collection("users").doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return;

  if (userSnap.data()?.verificationStatus !== "submitted") return;

  await userRef.update({
    verificationStatus: "pending",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
