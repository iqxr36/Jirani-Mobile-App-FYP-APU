import * as admin from "firebase-admin";

type DocumentData = admin.firestore.DocumentData;

function parseName(data: DocumentData): { firstName: string; lastName: string } {
  const firstName =
    typeof data.firstName === "string" ? data.firstName.trim() : "";
  const lastName = typeof data.lastName === "string" ? data.lastName.trim() : "";
  if (firstName || lastName) {
    return { firstName, lastName };
  }

  const fullName =
    typeof data.fullName === "string" ? data.fullName.trim() : "";
  if (!fullName) return { firstName: "", lastName: "" };
  const parts = fullName.split(/\s+/);
  if (parts.length === 1) return { firstName: parts[0], lastName: "" };
  return { firstName: parts[0], lastName: parts.slice(1).join(" ") };
}

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

function asInt(value: unknown, fallback = 0): number {
  return Math.trunc(asNumber(value, fallback));
}

function normalizeVerificationStatus(status: unknown): string {
  if (typeof status !== "string") return "";
  return status === "approved" ? "verified" : status;
}

export function buildPublicProfilePayload(
  uid: string,
  data: DocumentData,
): DocumentData | null {
  if (data.role !== "resident") {
    return null;
  }

  const names = parseName(data);
  const fullName = `${names.firstName} ${names.lastName}`.trim();
  const verificationStatus = normalizeVerificationStatus(data.verificationStatus);

  return {
    uid,
    firstName: names.firstName,
    lastName: names.lastName,
    fullName,
    profileImageUrl:
      typeof data.profileImageUrl === "string" ? data.profileImageUrl : "",
    communityId: typeof data.communityId === "string" ? data.communityId : "",
    communityName:
      typeof data.communityName === "string" ? data.communityName : "",
    role: "resident",
    verificationStatus,
    accountStatus:
      typeof data.accountStatus === "string" ? data.accountStatus : "active",
    reputationScore: asNumber(data.reputationScore),
    communityTrustScore: asNumber(
      data.communityTrustScore ?? data.reputationScore,
    ),
    totalReviews: asInt(data.totalReviews),
    trustedResident: data.trustedResident === true,
    completedBorrowings: asInt(data.completedBorrowings),
    completedLendings: asInt(data.completedLendings),
    completedServices: asInt(data.completedServices),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

export async function syncPublicProfileFromUser(
  db: admin.firestore.Firestore,
  uid: string,
  data: DocumentData | undefined,
): Promise<void> {
  const publicRef = db.collection("publicProfiles").doc(uid);

  if (!data) {
    await publicRef.delete().catch(() => undefined);
    return;
  }

  const payload = buildPublicProfilePayload(uid, data);
  if (!payload) {
    await publicRef.delete().catch(() => undefined);
    return;
  }

  await publicRef.set(payload, { merge: false });
}
