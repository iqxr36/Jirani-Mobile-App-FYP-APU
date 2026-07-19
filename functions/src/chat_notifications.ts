// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_notifications.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import { createInAppNotification, residentDisplayName } from "./notifications";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const NOTIFICATION_TYPE_CHAT_MESSAGE = "chatMessage";

// Chat notification feature: safely reads string fields from chat message documents.
function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

// Chat notification feature: converts text/image/file messages into the push notification preview line.
function messagePreview(data: DocumentData): string {
  const type = asString(data.type);
  if (type === "image") return "Photo";
  if (type === "file") return "Attachment";
  const text = asString(data.text).trim();
  return text.length > 0 ? text : "New message";
}

// Chat notification feature: finds the other chat participant who should receive the message notification.
function chatRecipientId(
  participants: unknown,
  senderId: string,
): string | null {
  if (!Array.isArray(participants)) return null;
  for (const participant of participants) {
    if (typeof participant === "string" && participant !== senderId) {
      return participant;
    }
  }
  return null;
}

// Chat notification feature: creates an in-app notification for the recipient when a new message is written.
export async function notifyChatMessageCreated(
  db: Firestore,
  chatId: string,
  message: DocumentData,
): Promise<void> {
  const senderId = asString(message.senderId);
  if (!senderId) return;

  const chatSnap = await db.collection("chats").doc(chatId).get();
  if (!chatSnap.exists) return;

  const chatData = chatSnap.data() ?? {};
  const participants = chatData.participantIds ?? chatData.participants;
  const recipientId = chatRecipientId(participants, senderId);
  if (!recipientId) return;

  const senderName = await residentDisplayName(db, senderId);
  await createInAppNotification(db, {
    userId: recipientId,
    actorId: senderId,
    type: NOTIFICATION_TYPE_CHAT_MESSAGE,
    title: senderName,
    body: messagePreview(message),
    category: "Messages",
    chatId,
    senderId,
  });
}
