import {createHash} from "crypto";
import * as admin from "firebase-admin";
import {HttpsError, onCall} from "firebase-functions/v2/https";

const USERS = "users";
const RESTRICTIONS = "residentEmailRestrictions";
const PHONE_REGISTRY = "residentPhoneNumbers";
const ACCOUNT_ACTIVE = "active";
const ACCOUNT_SUSPENDED = "suspended";
const ACCOUNT_DELETED = "deleted";

const MAX_PERSON_NAME_LENGTH = 60;
const MAX_PHONE_LENGTH = 16;
const MAX_PROFILE_IMAGE_URL_LENGTH = 2048;
const MAX_REVIEW_COMMENT_LENGTH = 1000;

const PERSON_NAME_REGEX = /^[A-Za-z][A-Za-z\s'-]*$/;

const TERMINAL_BORROW_STATUSES = new Set([
  "rejected",
  "cancelled",
  "completed",
]);
const TERMINAL_SERVICE_STATUSES = new Set([
  "rejected",
  "cancelled",
  "completed",
  "completedPayoutSent",
  "refunded",
  "paymentFailed",
]);

const PHONE_TAKEN_MESSAGE =
  "This phone number is already registered to another account.";

export function normalizeResidentEmail(value: unknown): string {
  if (typeof value !== "string") return "";
  return value.trim().toLowerCase();
}

export function residentEmailHash(email: string): string {
  return createHash("sha256").update(normalizeResidentEmail(email)).digest("hex");
}

/** Mirrors Dart Validators.normalizePhoneNumber. */
export function normalizeResidentPhone(value: unknown): string {
  if (typeof value !== "string") return "";
  const trimmed = value.trim();
  if (!trimmed) return "";

  const cleaned = trimmed.replace(/[\s-]/g, "");
  if (cleaned.startsWith("+")) {
    return `+${cleaned.substring(1).replace(/[^0-9]/g, "")}`;
  }
  return cleaned.replace(/[^0-9]/g, "");
}

export function residentPhoneHash(phone: string): string {
  return createHash("sha256").update(normalizeResidentPhone(phone)).digest("hex");
}

function requiredString(data: unknown, key: string): string {
  if (!data || typeof data !== "object") return "";
  const value = (data as Record<string, unknown>)[key];
  return typeof value === "string" ? value.trim() : "";
}

export function validatePersonName(value: string, fieldName: string): string {
  const name = value.trim();
  if (!name) {
    throw new HttpsError("invalid-argument", `${fieldName} is required.`);
  }
  if (name.length < 2 || name.length > MAX_PERSON_NAME_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} must be between 2 and ${MAX_PERSON_NAME_LENGTH} characters.`,
    );
  }
  if (!PERSON_NAME_REGEX.test(name)) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} can only contain letters, spaces, apostrophes, and hyphens.`,
    );
  }
  return name;
}

export function validateResidentPhone(value: string): string {
  const raw = value.trim();
  if (!raw) {
    throw new HttpsError("invalid-argument", "Phone number is required.");
  }
  if (!raw.startsWith("+")) {
    throw new HttpsError(
      "invalid-argument",
      "Include country code starting with + (e.g. +60).",
    );
  }
  if (/[^0-9+\s-]/.test(raw)) {
    throw new HttpsError(
      "invalid-argument",
      "Phone number can only contain +, digits, spaces, and dashes.",
    );
  }
  const normalized = normalizeResidentPhone(raw);
  if (!/^\+[0-9]+$/.test(normalized)) {
    throw new HttpsError(
      "invalid-argument",
      "Phone number must contain only digits after +.",
    );
  }
  const digits = normalized.substring(1);
  if (digits.length < 8 || digits.length > 15) {
    throw new HttpsError(
      "invalid-argument",
      "Enter a valid phone number with country code (8-15 digits).",
    );
  }
  if (normalized.length > MAX_PHONE_LENGTH) {
    throw new HttpsError("invalid-argument", "Phone number is too long.");
  }
  return normalized;
}

function validateProfileImageUrl(value: string): string {
  const url = value.trim();
  if (!url) return "";
  if (url.length > MAX_PROFILE_IMAGE_URL_LENGTH) {
    throw new HttpsError("invalid-argument", "Profile image URL is too long.");
  }
  return url;
}

async function isEmailRestricted(
  db: admin.firestore.Firestore,
  email: string,
): Promise<boolean> {
  if (!email) return false;
  const snapshot = await db.collection(RESTRICTIONS).doc(residentEmailHash(email)).get();
  return snapshot.exists && snapshot.data()?.blocked === true;
}

async function readPhoneRegistryOwner(
  db: admin.firestore.Firestore,
  phone: string,
): Promise<string | null> {
  const normalized = normalizeResidentPhone(phone);
  if (!normalized) return null;
  const snapshot = await db
    .collection(PHONE_REGISTRY)
    .doc(residentPhoneHash(normalized))
    .get();
  if (!snapshot.exists) return null;
  const uid = snapshot.data()?.uid;
  return typeof uid === "string" ? uid : null;
}

export async function assertPhoneAvailable(
  db: admin.firestore.Firestore,
  phone: string,
  excludeUid?: string,
): Promise<string> {
  const normalized = validateResidentPhone(phone);
  const ownerUid = await readPhoneRegistryOwner(db, normalized);
  if (ownerUid && ownerUid !== excludeUid) {
    throw new HttpsError("already-exists", PHONE_TAKEN_MESSAGE);
  }

  // Fallback when the registry was never backfilled for an existing profile.
  const takenByProfile = await db
    .collection(USERS)
    .where("phoneNumber", "==", normalized)
    .limit(5)
    .get();
  for (const doc of takenByProfile.docs) {
    if (doc.id !== excludeUid) {
      throw new HttpsError("already-exists", PHONE_TAKEN_MESSAGE);
    }
  }

  return normalized;
}

async function claimResidentPhone(
  db: admin.firestore.Firestore,
  uid: string,
  phone: string,
  previousPhone?: string,
): Promise<string> {
  const normalized = validateResidentPhone(phone);
  // Reject duplicates even if residentPhoneNumbers was never backfilled.
  await assertPhoneAvailable(db, normalized, uid);
  const previousNormalized = normalizeResidentPhone(previousPhone ?? "");

  await db.runTransaction(async (transaction) => {
    const registryRef = db
      .collection(PHONE_REGISTRY)
      .doc(residentPhoneHash(normalized));
    const releasingPrevious =
      previousNormalized.length > 0 && previousNormalized !== normalized;
    const previousRegistryRef = releasingPrevious ?
      db.collection(PHONE_REGISTRY).doc(residentPhoneHash(previousNormalized)) :
      null;

    // Firestore requires all reads before any writes in a transaction.
    const previousSnap = previousRegistryRef ?
      await transaction.get(previousRegistryRef) :
      null;
    const registrySnap = await transaction.get(registryRef);
    const ownerUid = registrySnap.data()?.uid;
    if (registrySnap.exists && ownerUid !== uid) {
      throw new HttpsError("already-exists", PHONE_TAKEN_MESSAGE);
    }

    if (
      previousRegistryRef &&
      previousSnap?.exists &&
      previousSnap.data()?.uid === uid
    ) {
      transaction.delete(previousRegistryRef);
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    transaction.set(
      registryRef,
      {
        uid,
        normalizedPhone: normalized,
        createdAt: registrySnap.exists ?
          registrySnap.data()?.createdAt ?? now :
          now,
        updatedAt: now,
      },
      {merge: true},
    );
  });

  return normalized;
}

async function isSystemAdminUid(uid: string): Promise<boolean> {
  const adminDoc = await admin.firestore().collection("admins").doc(uid).get();
  return adminDoc.data()?.role === "systemAdmin";
}

async function isAdminUid(uid: string): Promise<boolean> {
  const adminDoc = await admin.firestore().collection("admins").doc(uid).get();
  const role = adminDoc.data()?.role;
  return role === "systemAdmin" || role === "communityAdmin";
}

async function hasOpenRecords(
  db: admin.firestore.Firestore,
  collection: string,
  participantFields: string[],
  uid: string,
  terminalStatuses: Set<string>,
): Promise<boolean> {
  for (const field of participantFields) {
    const snapshot = await db.collection(collection).where(field, "==", uid).get();
    if (snapshot.docs.some((doc) => {
      const data = doc.data();
      const status = typeof data.status === "string" ? data.status : "";
      if (!terminalStatuses.has(status)) return true;
      if (collection === "borrowRequests") {
        return data.refundStatus === "pending" ||
          data.refundStatus === "failed" ||
          data.manualPayoutStatus === "pending_manual" ||
          data.manualPayoutStatus === "blocked";
      }
      return data.refundStatus === "pending" ||
        data.refundStatus === "failed" ||
        data.payoutStatus === "pending" ||
        data.payoutStatus === "failed" ||
        data.payoutStatus === "blocked";
    })) {
      return true;
    }
  }
  return false;
}

async function assertNoOpenObligations(
  db: admin.firestore.Firestore,
  uid: string,
): Promise<void> {
  const [openBorrow, openService] = await Promise.all([
    hasOpenRecords(
      db,
      "borrowRequests",
      ["borrowerId", "ownerId"],
      uid,
      TERMINAL_BORROW_STATUSES,
    ),
    hasOpenRecords(
      db,
      "serviceRequests",
      ["requesterId", "providerId"],
      uid,
      TERMINAL_SERVICE_STATUSES,
    ),
  ]);
  if (openBorrow || openService) {
    throw new HttpsError(
      "failed-precondition",
      "Resolve active loans, services, disputes, payouts, and refunds before deleting your account.",
      {reason: "active-transactions"},
    );
  }
}

async function hideResidentListings(
  db: admin.firestore.Firestore,
  uid: string,
): Promise<void> {
  const [items, services] = await Promise.all([
    db.collection("items").where("ownerId", "==", uid).get(),
    db.collection("services").where("providerId", "==", uid).get(),
  ]);
  const writer = db.bulkWriter();
  const deletedAt = admin.firestore.FieldValue.serverTimestamp();
  items.docs.forEach((doc) => writer.set(doc.ref, {
    status: "archived",
    archivedAt: deletedAt,
    updatedAt: deletedAt,
  }, {merge: true}));
  services.docs.forEach((doc) => writer.set(doc.ref, {
    status: "archived",
    archivedAt: deletedAt,
    updatedAt: deletedAt,
  }, {merge: true}));
  await writer.close();
}

export function deletedResidentProfileFields(
  data: Record<string, unknown>,
  suspended: boolean,
): Record<string, unknown> {
  const communityId =
    typeof data.communityId === "string" ? data.communityId : "";
  const communityName =
    typeof data.communityName === "string" ? data.communityName : "";
  const unitNumber =
    typeof data.unitNumber === "string" ? data.unitNumber : "";

  return {
    firstName: "Deleted",
    lastName: "Resident",
    fullName: "Deleted Resident",
    email: "",
    phoneNumber: "",
    profileImageUrl: "",
    unitNumber,
    communityId,
    communityName,
    notificationEnabled: false,
    accountStatus: ACCOUNT_DELETED,
    accountFlagged: suspended,
    phoneVerified: false,
  };
}

export const checkResidentRegistrationEligibility = onCall(async (request) => {
  const email = normalizeResidentEmail(requiredString(request.data, "email"));
  if (!email || !email.includes("@")) {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
  }
  const blocked = await isEmailRestricted(admin.firestore(), email);
  if (blocked) {
    throw new HttpsError(
      "permission-denied",
      "This email is linked to a suspended account. Contact support for assistance.",
      {reason: "suspended-email"},
    );
  }
  return {eligible: true};
});

export const checkResidentPhoneAvailability = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }
  const phoneInput = requiredString(request.data, "phoneNumber");
  const db = admin.firestore();
  // Residents may only exclude their own profile from duplicate checks.
  await assertPhoneAvailable(db, phoneInput, uid);
  return {available: true};
});

export const updateResidentPhoneNumber = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }

  const phoneInput = requiredString(request.data, "phoneNumber");
  const markVerified = request.data?.markVerified === true;
  const db = admin.firestore();
  const userRef = db.collection(USERS).doc(uid);
  const userSnap = await userRef.get();
  const userData = userSnap.data();
  if (!userSnap.exists || userData?.role !== "resident") {
    throw new HttpsError("not-found", "Resident profile was not found.");
  }

  const previousPhone =
    typeof userData.phoneNumber === "string" ? userData.phoneNumber : "";
  const normalized = await claimResidentPhone(db, uid, phoneInput, previousPhone);
  const phoneChanged = normalizeResidentPhone(previousPhone) !== normalized;

  await userRef.set(
    {
      phoneNumber: normalized,
      phoneVerified: markVerified ?
        true :
        phoneChanged ?
          false :
          userData.phoneVerified === true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  return {updated: true, phoneNumber: normalized};
});

export const adminUpdateResidentPhoneNumber = onCall(async (request) => {
  const adminUid = request.auth?.uid;
  if (!adminUid) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }
  if (!(await isAdminUid(adminUid))) {
    throw new HttpsError("permission-denied", "Admin access is required.");
  }

  const residentUid = requiredString(request.data, "residentUid");
  const phoneInput = requiredString(request.data, "phoneNumber");
  if (!residentUid) {
    throw new HttpsError("invalid-argument", "residentUid is required.");
  }

  const db = admin.firestore();
  const userRef = db.collection(USERS).doc(residentUid);
  const userSnap = await userRef.get();
  const userData = userSnap.data();
  if (!userSnap.exists || userData?.role !== "resident") {
    throw new HttpsError("not-found", "Resident profile was not found.");
  }

  const previousPhone =
    typeof userData.phoneNumber === "string" ? userData.phoneNumber : "";
  const normalized = await claimResidentPhone(
    db,
    residentUid,
    phoneInput,
    previousPhone,
  );
  const phoneChanged = normalizeResidentPhone(previousPhone) !== normalized;

  await userRef.set(
    {
      phoneNumber: normalized,
      ...(phoneChanged ? {phoneVerified: false} : {}),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  return {updated: true, phoneNumber: normalized};
});

export const finalizeResidentRegistration = onCall(async (request) => {
  const uid = request.auth?.uid;
  const authEmail = normalizeResidentEmail(request.auth?.token.email);
  if (!uid || !authEmail) {
    throw new HttpsError("unauthenticated", "A verified Firebase session is required.");
  }

  const db = admin.firestore();
  if (await isEmailRestricted(db, authEmail)) {
    await admin.auth().deleteUser(uid).catch(() => undefined);
    throw new HttpsError(
      "permission-denied",
      "This email is linked to a suspended account. Contact support for assistance.",
      {reason: "suspended-email"},
    );
  }

  const firstName = validatePersonName(
    requiredString(request.data, "firstName"),
    "First name",
  );
  const lastName = validatePersonName(
    requiredString(request.data, "lastName"),
    "Last name",
  );
  const phoneRaw = requiredString(request.data, "phoneNumber");
  const phoneNumber = phoneRaw ? validateResidentPhone(phoneRaw) : "";
  const communityId = requiredString(request.data, "communityId");
  const communityName = requiredString(request.data, "communityName");
  const profileImageUrl = validateProfileImageUrl(
    requiredString(request.data, "profileImageUrl"),
  );
  if (!communityId) {
    throw new HttpsError("invalid-argument", "Community is required.");
  }
  if (!communityName) {
    throw new HttpsError("invalid-argument", "Community name is required.");
  }

  const termsAccepted = request.data?.termsAccepted === true;
  const signInProvider = request.auth?.token.firebase?.sign_in_provider;
  if (!termsAccepted && signInProvider === "password") {
    throw new HttpsError("failed-precondition", "Accept the terms and conditions to continue.");
  }

  if (phoneNumber) {
    await assertPhoneAvailable(db, phoneNumber, uid);
  }

  const userRecord = await admin.auth().getUser(uid);
  const profile = {
    uid,
    firstName,
    lastName,
    fullName: `${firstName} ${lastName}`.trim(),
    email: authEmail,
    phoneNumber,
    role: "resident",
    verificationStatus: "pending",
    emailVerified: userRecord.emailVerified,
    phoneVerified: false,
    profileImageUrl,
    communityId,
    communityName,
    unitNumber: "",
    reputationScore: 0,
    totalReviews: 0,
    completedBorrowings: 0,
    completedLendings: 0,
    completedServices: 0,
    completedServicesProvided: 0,
    completedServicesRequested: 0,
    termsAccepted,
    locationVerified: false,
    accountStatus: ACCOUNT_ACTIVE,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const userRef = db.collection(USERS).doc(uid);
  const created = await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(userRef);
    if (existing.exists) {
      const existingData = existing.data();
      if (existingData?.uid === uid && existingData?.role === "resident") {
        return false;
      }
      throw new HttpsError("already-exists", "A conflicting resident profile already exists.");
    }

    const registryRef = phoneNumber ?
      db.collection(PHONE_REGISTRY).doc(residentPhoneHash(phoneNumber)) :
      null;
    const registrySnap = registryRef ? await transaction.get(registryRef) : null;
    if (registrySnap?.exists && registrySnap.data()?.uid !== uid) {
      throw new HttpsError("already-exists", PHONE_TAKEN_MESSAGE);
    }

    transaction.create(userRef, profile);
    if (registryRef && phoneNumber) {
      const now = admin.firestore.FieldValue.serverTimestamp();
      transaction.set(
        registryRef,
        {
          uid,
          normalizedPhone: phoneNumber,
          createdAt: registrySnap?.exists ?
            registrySnap.data()?.createdAt ?? now :
            now,
          updatedAt: now,
        },
        {merge: true},
      );
    }
    return true;
  });
  return {created};
});

export const deleteResidentAccount = onCall({timeoutSeconds: 120}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in first.");

  const authTime = Number(request.auth?.token.auth_time ?? 0);
  if (!authTime || Date.now() / 1000 - authTime > 10 * 60) {
    throw new HttpsError(
      "failed-precondition",
      "Please sign in again before deleting your account.",
      {reason: "recent-login-required"},
    );
  }

  const db = admin.firestore();
  const userRef = db.collection(USERS).doc(uid);
  const snapshot = await userRef.get();
  const data = snapshot.data();
  if (!snapshot.exists || !data || data.role !== "resident") {
    throw new HttpsError("not-found", "Resident profile was not found.");
  }
  await assertNoOpenObligations(db, uid);
  await hideResidentListings(db, uid);

  const authRecord = await admin.auth().getUser(uid);
  const email = normalizeResidentEmail(authRecord.email ?? data.email);
  const suspended = data.accountStatus === ACCOUNT_SUSPENDED;
  const currentPhone =
    typeof data.phoneNumber === "string" ? data.phoneNumber : "";

  const batch = db.batch();
  if (suspended && email) {
    batch.set(db.collection(RESTRICTIONS).doc(residentEmailHash(email)), {
      blocked: true,
      sourceUid: uid,
      reason: typeof data.suspendedReason === "string" ? data.suspendedReason : "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  batch.set(userRef, {
    ...deletedResidentProfileFields(data, suspended),
    pendingEmail: admin.firestore.FieldValue.delete(),
    fcmToken: admin.firestore.FieldValue.delete(),
    fcmTokens: admin.firestore.FieldValue.delete(),
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  batch.delete(db.collection("publicProfiles").doc(uid));

  const normalizedPhone = normalizeResidentPhone(currentPhone);
  if (normalizedPhone) {
    const registryRef = db
      .collection(PHONE_REGISTRY)
      .doc(residentPhoneHash(normalizedPhone));
    const registrySnap = await registryRef.get();
    if (registrySnap.exists && registrySnap.data()?.uid === uid) {
      batch.delete(registryRef);
    }
  }

  await batch.commit();

  await admin.storage().bucket().deleteFiles({
    prefix: `profile_images/residents/${uid}/`,
  }).catch(() => undefined);

  await admin.auth().revokeRefreshTokens(uid);
  await admin.auth().deleteUser(uid);
  return {deleted: true};
});

export const clearResidentEmailRestriction = onCall(async (request) => {
  const adminUid = request.auth?.uid;
  if (!adminUid) throw new HttpsError("unauthenticated", "Please sign in first.");
  if (!(await isSystemAdminUid(adminUid))) {
    throw new HttpsError("permission-denied", "System admin access is required.");
  }
  const residentUid = requiredString(request.data, "residentUid");
  if (!residentUid) throw new HttpsError("invalid-argument", "residentUid is required.");
  const matches = await admin.firestore()
    .collection(RESTRICTIONS)
    .where("sourceUid", "==", residentUid)
    .get();
  const batch = admin.firestore().batch();
  matches.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  return {cleared: matches.size};
});

/**
 * One-time deploy helper: scans active resident profiles and populates
 * `residentPhoneNumbers`. Run once after deploying phone-uniqueness callables
 * and before enforcing client phone-write blocks in Firestore rules.
 */
export const backfillResidentPhoneRegistry = onCall(async (request) => {
  const adminUid = request.auth?.uid;
  if (!adminUid) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }
  if (!(await isSystemAdminUid(adminUid))) {
    throw new HttpsError("permission-denied", "System admin access is required.");
  }

  const db = admin.firestore();
  const snapshot = await db
    .collection(USERS)
    .where("role", "==", "resident")
    .get();

  let claimed = 0;
  let skipped = 0;
  const conflicts: Array<{uid: string; phone: string; ownerUid: string}> = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.accountStatus === ACCOUNT_DELETED) {
      skipped++;
      continue;
    }
    const phone =
      typeof data.phoneNumber === "string" ? data.phoneNumber : "";
    const normalized = normalizeResidentPhone(phone);
    if (!normalized) {
      skipped++;
      continue;
    }

    const registryRef = db
      .collection(PHONE_REGISTRY)
      .doc(residentPhoneHash(normalized));
    const registrySnap = await registryRef.get();
    const ownerUid = registrySnap.data()?.uid;
    if (registrySnap.exists && ownerUid && ownerUid !== doc.id) {
      conflicts.push({uid: doc.id, phone: normalized, ownerUid});
      continue;
    }

    await registryRef.set(
      {
        uid: doc.id,
        normalizedPhone: normalized,
        createdAt: registrySnap.data()?.createdAt ??
          admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    claimed++;
  }

  return {claimed, skipped, conflicts};
});

export {MAX_REVIEW_COMMENT_LENGTH};
