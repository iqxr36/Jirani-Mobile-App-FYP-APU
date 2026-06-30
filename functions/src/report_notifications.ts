import * as admin from "firebase-admin";
import { createInAppNotificationIfAbsent } from "./notifications";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

type ReportNotificationStatus = "open" | "underReview";

// Report notification feature: safely reads trimmed string fields from report/admin documents.
function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

// Report notification feature: detects newly open/under-review reports that should alert admins.
function reportNeedsAdminNotification(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): after is DocumentData {
  if (!after) return false;
  const status = stringValue(after.status) as ReportNotificationStatus | "";
  if (status !== "open" && status !== "underReview") return false;
  if (!before) return true;
  return stringValue(before.status) !== status;
}

// Report notification feature: chooses the best title for the admin report notification.
function reportTitle(data: DocumentData): string {
  return stringValue(data.title) ||
    stringValue(data.reportCategory) ||
    stringValue(data.type) ||
    "Resident report";
}

// Report notification feature: chooses the reported resident name for the admin notification body.
function reportedResidentName(data: DocumentData): string {
  return stringValue(data.reportedUserName) || "a resident";
}

// Report notification feature: notifies scoped admins when a report enters open or under-review state.
export async function handleReportNotificationChanges(
  db: Firestore,
  reportId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): Promise<void> {
  if (!reportNeedsAdminNotification(before, after)) return;

  const communityId = stringValue(after.communityId);
  const communityName = stringValue(after.communityName);
  const status = stringValue(after.status) || "open";
  const admins = await db.collection("admins").get();
  const notified = new Set<string>();

  await Promise.all(admins.docs.map(async (doc) => {
    const adminData = doc.data();
    const uid = stringValue(adminData.uid) || doc.id;
    if (!uid || notified.has(uid)) return;
    if (adminData.isActive === false) return;

    const role = stringValue(adminData.role);
    const adminCommunityId = stringValue(adminData.communityId);
    const adminCommunityName = stringValue(adminData.communityName);
    const inScope = role === "systemAdmin" ||
      (communityId && adminCommunityId === communityId) ||
      (communityName && adminCommunityName === communityName);
    if (!inScope) return;

    notified.add(uid);
    await createInAppNotificationIfAbsent(
      db,
      `report_${status}_${reportId}_${uid}`,
      {
        userId: uid,
        actorId: stringValue(after.reporterId) || "system",
        type: "adminReport",
        title: status === "underReview" ? "Report needs review" : "New resident report",
        body: `${reportTitle(after)} was submitted about ${reportedResidentName(after)}.`,
        category: "reports",
        reportId,
        communityId,
      },
    );
  }));
}

export { reportNeedsAdminNotification };
