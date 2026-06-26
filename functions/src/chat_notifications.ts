import * as admin from "firebase-admin";
import { createInAppNotification, residentDisplayName } from "./notifications";

type Firestore = admin.firestore.Firestore;
type DocumentData = admin.firestore.DocumentData;

const NOTIFICATION_TYPE_CHAT_MESSAGE = "chatMessage";

function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function messagePreview(data: DocumentData): string {
  const type = asString(data.type);
  if (type === "image") return "Photo";
  if (type === "file") return "Attachment";
  const text = asString(data.text).trim();
  return text.length > 0 ? text : "New message";
}

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
