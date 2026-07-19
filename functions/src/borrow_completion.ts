// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : borrow_completion.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

// Marketplace completion feature: detects the first transition of a borrow request into completed status.
export function borrowBecameCompleted(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  if (!after) return false;
  return before?.status !== "completed" && after.status === "completed";
}

// Marketplace completion feature: releases the item and increments borrower/lender completed counters once.
export async function applyBorrowCompletionSideEffects(
  db: Firestore,
  requestId: string,
  data: DocumentData,
): Promise<void> {
  const ownerId = data.ownerId;
  const borrowerId = data.borrowerId;
  const itemId = data.itemId;
  if (
    typeof ownerId !== "string" ||
    typeof borrowerId !== "string" ||
    typeof itemId !== "string"
  ) {
    return;
  }

  await db.runTransaction(async (txn) => {
    const requestRef = db.collection("borrowRequests").doc(requestId);
    const itemRef = db.collection("items").doc(itemId);
    const ownerRef = db.collection("users").doc(ownerId);
    const borrowerRef = db.collection("users").doc(borrowerId);

    const [requestSnap, itemSnap, ownerSnap, borrowerSnap] = await Promise.all([
      txn.get(requestRef),
      txn.get(itemRef),
      txn.get(ownerRef),
      txn.get(borrowerRef),
    ]);

    if (!requestSnap.exists) return;
    const requestData = requestSnap.data()!;
    if (requestData.status !== "completed") return;

    if (
      itemSnap.exists &&
      itemSnap.data()?.lastCompletedBorrowRequestId !== requestId
    ) {
      txn.update(itemRef, {
        status: "available",
        lastCompletedBorrowRequestId: requestId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    if (
      ownerSnap.exists &&
      ownerSnap.data()?.lastCompletedBorrowRequestId !== requestId
    ) {
      txn.update(ownerRef, {
        completedLendings: admin.firestore.FieldValue.increment(1),
        lastCompletedBorrowRequestId: requestId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    if (
      borrowerSnap.exists &&
      borrowerSnap.data()?.lastCompletedBorrowRequestId !== requestId
    ) {
      txn.update(borrowerRef, {
        completedBorrowings: admin.firestore.FieldValue.increment(1),
        lastCompletedBorrowRequestId: requestId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
}
