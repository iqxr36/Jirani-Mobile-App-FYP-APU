import * as admin from "firebase-admin";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

export function borrowBecameCompleted(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): boolean {
  if (!after) return false;
  return before?.status !== "completed" && after.status === "completed";
}

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
