// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : service_visibility.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Monday,06-July-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import {HttpsError, onCall} from "firebase-functions/v2/https";

const USERS_COLLECTION = "users";
const ADMINS_COLLECTION = "admins";
const SERVICES_COLLECTION = "services";
const ROLE_COMMUNITY_ADMIN = "communityAdmin";
const ROLE_SYSTEM_ADMIN = "systemAdmin";

type BackfillSummary = {
  updated: number;
  skipped: number;
  missingProvider: number;
};

function requireUid(auth: {uid?: string} | undefined): string {
  const uid = auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in first.");
  return uid;
}

function asString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

async function isAdminUser(db: admin.firestore.Firestore, uid: string): Promise<boolean> {
  const [userSnapshot, adminSnapshot] = await Promise.all([
    db.collection(USERS_COLLECTION).doc(uid).get(),
    db.collection(ADMINS_COLLECTION).doc(uid).get(),
  ]);
  const userRole = asString(userSnapshot.data()?.role);
  const adminRole = asString(adminSnapshot.data()?.role);
  return userRole === ROLE_COMMUNITY_ADMIN ||
    userRole === ROLE_SYSTEM_ADMIN ||
    adminRole === ROLE_COMMUNITY_ADMIN ||
    adminRole === ROLE_SYSTEM_ADMIN;
}

async function requireAdmin(db: admin.firestore.Firestore, uid: string): Promise<void> {
  if (!await isAdminUser(db, uid)) {
    throw new HttpsError("permission-denied", "Admin access is required.");
  }
}

async function backfillServiceSnapshot(
  db: admin.firestore.Firestore,
  serviceDocs: admin.firestore.DocumentSnapshot[],
): Promise<BackfillSummary> {
  let updated = 0;
  let skipped = 0;
  let missingProvider = 0;

  for (const serviceDoc of serviceDocs) {
    const service = serviceDoc.data();
    const existingCommunityId = asString(service?.communityId);
    if (existingCommunityId) {
      skipped += 1;
      continue;
    }

    const providerId = asString(service?.providerId);
    if (!providerId) {
      missingProvider += 1;
      continue;
    }

    const providerSnapshot = await db.collection(USERS_COLLECTION).doc(providerId).get();
    const provider = providerSnapshot.data();
    const communityId = asString(provider?.communityId);
    if (!provider || !communityId) {
      missingProvider += 1;
      continue;
    }

    await serviceDoc.ref.set({
      communityId,
      communityName: asString(provider.communityName),
      visibilityBackfilledAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    updated += 1;
  }

  return {updated, skipped, missingProvider};
}

export const backfillServiceCommunityIds = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const db = admin.firestore();
  await requireAdmin(db, uid);

  const servicesSnapshot = await db.collection(SERVICES_COLLECTION).get();
  return backfillServiceSnapshot(db, servicesSnapshot.docs);
});

export const repairOwnServiceCommunityIds = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const db = admin.firestore();
  const input = request.data && typeof request.data === "object" ?
    request.data as Record<string, unknown> :
    {};
  const requestedIds = asStringArray(input.serviceIds);
  if (requestedIds.length === 0) {
    return {updated: 0, skipped: 0, missingProvider: 0};
  }

  const snapshots = await Promise.all(
    requestedIds.map((serviceId) => db.collection(SERVICES_COLLECTION).doc(serviceId).get()),
  );
  const ownedDocs = snapshots.filter((doc) => {
    const data = doc.data();
    return doc.exists && asString(data?.providerId) === uid;
  });
  return backfillServiceSnapshot(db, ownedDocs);
});
