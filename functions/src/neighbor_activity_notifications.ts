// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : neighbor_activity_notifications.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,11-July-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import {
  createInAppNotificationIfAbsent,
  residentDisplayName,
} from "./notifications";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const CONNECTION_STATUS_ACCEPTED = "accepted";
const ITEM_STATUS_AVAILABLE = "available";
const SERVICE_STATUS_ACTIVE = "active";
const NOTIFICATION_TYPE_NEIGHBOR_NEW_ITEM = "neighborNewItem";
const NOTIFICATION_TYPE_NEIGHBOR_NEW_SERVICE = "neighborNewService";
const NOTIFICATION_TYPE_NEIGHBOR_TRUST_WARNING = "neighborTrustWarning";
const NOTIFICATION_TYPE_ADMIN_WARNING = "adminWarning";
const FAN_OUT_BATCH_SIZE = 100;

// Neighbor activity notification feature: safely reads string fields from Firestore documents.
function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

// Neighbor activity notification feature: builds deterministic IDs so fan-out retries do not duplicate notifications.
export function neighborActivityNotificationId(
  eventKey: string,
  userId: string,
): string {
  return `nb_${eventKey}_${userId}`.replace(/\//g, "_");
}

// Neighbor activity notification feature: checks whether a resident wants neighbor activity alerts.
export function recipientWantsNeighborUpdates(
  userData: DocumentData | undefined,
): boolean {
  if (!userData) return false;
  if (userData.notificationEnabled === false) return false;
  if (userData.neighborUpdatesEnabled === false) return false;
  return true;
}

// Neighbor activity notification feature: extracts connected neighbor ids from connection documents.
export function extractNeighborIdsFromConnections(
  userId: string,
  connections: Array<{ participants?: unknown }>,
): string[] {
  const neighborIds: string[] = [];
  for (const connection of connections) {
    const participants = connection.participants;
    if (!Array.isArray(participants)) continue;
    for (const participant of participants) {
      if (typeof participant === "string" && participant !== userId) {
        neighborIds.push(participant);
      }
    }
  }
  return neighborIds;
}

// Neighbor activity notification feature: loads accepted neighbor ids for a resident.
export async function getAcceptedNeighborIds(
  db: Firestore,
  userId: string,
): Promise<string[]> {
  const snap = await db
    .collection("connections")
    .where("participants", "array-contains", userId)
    .where("status", "==", CONNECTION_STATUS_ACCEPTED)
    .get();

  return extractNeighborIdsFromConnections(
    userId,
    snap.docs.map((doc) => doc.data()),
  );
}

type FanOutInput = {
  actorId: string;
  eventKey: string;
  type: string;
  title: string;
  body: string;
  category: string;
  itemId?: string;
  serviceId?: string;
  residentId?: string;
  connectionId?: string;
};

// Neighbor activity notification feature: keeps only recipients who opted into neighbor updates.
async function filterRecipientsWantingUpdates(
  db: Firestore,
  recipientIds: string[],
): Promise<string[]> {
  const eligible: string[] = [];
  for (let index = 0; index < recipientIds.length; index += FAN_OUT_BATCH_SIZE) {
    const batch = recipientIds.slice(index, index + FAN_OUT_BATCH_SIZE);
    const snaps = await Promise.all(
      batch.map((id) => db.collection("users").doc(id).get()),
    );
    for (let i = 0; i < batch.length; i++) {
      if (recipientWantsNeighborUpdates(snaps[i].data())) {
        eligible.push(batch[i]);
      }
    }
  }
  return eligible;
}

// Neighbor activity notification feature: fans out neighbor activity notifications in bounded batches.
async function fanOutNeighborActivity(
  db: Firestore,
  recipientIds: string[],
  input: FanOutInput,
): Promise<void> {
  const eligible = await filterRecipientsWantingUpdates(db, recipientIds);
  if (eligible.length === 0) return;

  for (let index = 0; index < eligible.length; index += FAN_OUT_BATCH_SIZE) {
    const batch = eligible.slice(index, index + FAN_OUT_BATCH_SIZE);
    await Promise.all(
      batch.map((userId) =>
        createInAppNotificationIfAbsent(
          db,
          neighborActivityNotificationId(input.eventKey, userId),
          {
            userId,
            actorId: input.actorId,
            type: input.type,
            title: input.title,
            body: input.body,
            category: input.category,
            itemId: input.itemId,
            serviceId: input.serviceId,
            residentId: input.residentId ?? input.actorId,
            connectionId: input.connectionId,
          },
        ),
      ),
    );
  }
}

// Neighbor activity notification feature: notifies connected neighbors when a marketplace item is published.
export async function handleNewItemNeighborNotifications(
  db: Firestore,
  itemId: string,
  data: DocumentData,
): Promise<void> {
  if (asString(data.status) !== ITEM_STATUS_AVAILABLE) return;

  const ownerId = asString(data.ownerId);
  if (!ownerId) return;

  const neighborIds = await getAcceptedNeighborIds(db, ownerId);
  if (neighborIds.length === 0) return;

  const actorName = await residentDisplayName(db, ownerId);
  const itemTitle = asString(data.title).trim() || "New item";
  const body = `${actorName} listed a new item: ${itemTitle}`;

  await fanOutNeighborActivity(db, neighborIds, {
    actorId: ownerId,
    eventKey: `item_${itemId}`,
    type: NOTIFICATION_TYPE_NEIGHBOR_NEW_ITEM,
    title: actorName,
    body,
    category: "Neighbors",
    itemId,
    residentId: ownerId,
  });
}

// Neighbor activity notification feature: notifies connected neighbors when a service listing is published.
export async function handleNewServiceNeighborNotifications(
  db: Firestore,
  serviceId: string,
  data: DocumentData,
): Promise<void> {
  if (asString(data.status) !== SERVICE_STATUS_ACTIVE) return;

  const providerId = asString(data.providerId);
  if (!providerId) return;

  const neighborIds = await getAcceptedNeighborIds(db, providerId);
  if (neighborIds.length === 0) return;

  const actorName = await residentDisplayName(db, providerId);
  const serviceTitle = asString(data.title).trim() || "New service";
  const body = `${actorName} added a new service: ${serviceTitle}`;

  await fanOutNeighborActivity(db, neighborIds, {
    actorId: providerId,
    eventKey: `service_${serviceId}`,
    type: NOTIFICATION_TYPE_NEIGHBOR_NEW_SERVICE,
    title: actorName,
    body,
    category: "Neighbors",
    serviceId,
    residentId: providerId,
  });
}

// Neighbor activity notification feature: notifies connected neighbors when a resident receives an admin warning.
export async function handleAdminWarningNeighborNotifications(
  db: Firestore,
  sourceNotificationId: string,
  data: DocumentData,
): Promise<void> {
  if (asString(data.type) !== NOTIFICATION_TYPE_ADMIN_WARNING) return;

  const warnedUserId = asString(data.userId);
  if (!warnedUserId) return;

  const neighborIds = await getAcceptedNeighborIds(db, warnedUserId);
  if (neighborIds.length === 0) return;

  const actorName = await residentDisplayName(db, warnedUserId);
  const body = `${actorName} received a community trust warning`;

  await fanOutNeighborActivity(db, neighborIds, {
    actorId: warnedUserId,
    eventKey: `warn_${sourceNotificationId}`,
    type: NOTIFICATION_TYPE_NEIGHBOR_TRUST_WARNING,
    title: actorName,
    body,
    category: "Neighbors",
    residentId: warnedUserId,
  });
}
