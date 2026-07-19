// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_sync.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

// Verification sync feature: checks whether a verification request has an uploaded proof document.
function hasUploadedDocument(data: DocumentData): boolean {
  const documentUrl = data.documentUrl;
  return typeof documentUrl === "string" && documentUrl.trim().length > 0;
}

// Verification sync feature: returns true once a request is submitted and ready to update users/{uid}.
export function verificationRequestReadyForUserSync(
  data: DocumentData | undefined,
): boolean {
  if (!data) return false;
  return data.status === "submitted" && hasUploadedDocument(data);
}

// Verification sync feature: detects the first time a verification request becomes submitted with a document.
export function verificationRequestBecameReady(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  return (
    !verificationRequestReadyForUserSync(before) &&
    verificationRequestReadyForUserSync(after)
  );
}

// Verification sync feature: detects when a resident cancels a verification request.
export function verificationRequestBecameCancelled(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  if (!before || !after) return false;
  return before.status !== "cancelled" && after.status === "cancelled";
}

// Verification sync feature: mirrors submitted request community/unit fields onto users/{uid}.
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

// Verification sync feature: resets users/{uid}.verificationStatus back to pending after request cancellation.
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
