import * as admin from "firebase-admin";
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import {
  applyBorrowCompletionSideEffects,
  borrowBecameCompleted,
} from "./borrow_completion";
import { handleBorrowRequestNotificationChanges } from "./borrow_notifications";
import { handleCommunityPostNotificationChanges } from "./community_post_notifications";
import { processCommunityPostLifecycle } from "./community_post_lifecycle";
import { handleConnectionNotificationChanges } from "./connection_notifications";
import { notifyChatMessageCreated } from "./chat_notifications";
import { sendFcmForNotification } from "./notifications";
import { handleServiceRequestNotificationChanges } from "./service_notifications";
import {
  applyServiceCompletionSideEffects,
  serviceBecameCompleted,
} from "./service_completion";
import { handleReportNotificationChanges } from "./report_notifications";
import { syncPublicProfileFromUser } from "./public_profile";
import {
  publishEligibleReviewsForBorrowRequest,
  publishGraceExpiredBorrowReviews,
  shouldAttemptPublishAfterBorrowUpdate,
} from "./review_publish";
export {createMarketplaceReview, createServiceReview} from "./reviews";
import {
  syncUserFromCancelledVerificationRequest,
  syncUserFromSubmittedVerificationRequest,
  verificationRequestBecameCancelled,
  verificationRequestBecameReady,
} from "./verification_sync";
import {
  createDamageReportIfNeeded,
  recalculateTrustScoreForUser,
  reviewBecamePublished,
} from "./trust_score";
import {markMarketplaceDepositDisputedIfNeeded} from "./payments";
export {processVerificationRequestOcr} from "./ocr/processVerificationOcr";
export {
  backfillServiceCommunityIds,
  repairOwnServiceCommunityIds,
} from "./service_visibility";
export {
  createXenditServicePayment,
  createXenditMarketplacePayment,
  disputeServiceRequest,
  forceServicePayout,
  generateServiceArrivalCode,
  generateServiceCompletionCode,
  getPaymentStatus,
  markManualPayoutPaid,
  refundServicePayment,
  repairStuckMarketplaceSettlement,
  resolveMarketplaceDeposit,
  saveTestPayoutAccount,
  submitServiceArrivalCode,
  submitServiceCompletionCode,
  submitServiceDisputeEvidence,
  xenditWebhook,
} from "./payments";

// Firebase Functions entrypoint: initializes Admin SDK once before all triggers and callables run.
admin.initializeApp();

// Public profile sync feature: mirrors safe resident fields from users/{uid} into publicProfiles/{uid}.
export const syncPublicResidentProfile = onDocumentWritten(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const after = event.data?.after;

    try {
      await syncPublicProfileFromUser(
        admin.firestore(),
        uid,
        after?.exists ? after.data() : undefined,
      );
      logger.info("Synced public resident profile", { uid });
    } catch (error) {
      logger.error("Failed to sync public resident profile", { uid, error });
      throw error;
    }
  },
);

// Push notification feature: sends an FCM push whenever an in-app notification document is created.
export const onNotificationCreatedSendPush = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const notificationId = event.params.notificationId;
    const data = event.data?.data();
    if (!data) return;

    try {
      await sendFcmForNotification(admin.firestore(), data);
      logger.info("Sent push for notification", { notificationId });
    } catch (error) {
      logger.error("Failed to send push for notification", {
        notificationId,
        error,
      });
      throw error;
    }
  },
);

// Marketplace borrow orchestration feature: sends borrow notifications, completion side effects, and deposit dispute flags.
export const onBorrowRequestOrchestration = onDocumentWritten(
  "borrowRequests/{requestId}",
  async (event) => {
    const requestId = event.params.requestId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const db = admin.firestore();

    try {
      await handleBorrowRequestNotificationChanges(
        db,
        requestId,
        before,
        after,
      );

      if (borrowBecameCompleted(before, after) && after) {
        await applyBorrowCompletionSideEffects(db, requestId, after);
        logger.info("Applied borrow completion side effects", { requestId });
      }

      await markMarketplaceDepositDisputedIfNeeded(db, requestId, before, after);
    } catch (error) {
      logger.error("Failed borrow request orchestration", {
        requestId,
        error,
      });
      throw error;
    }
  },
);

// Neighbor connection notification feature: reacts to connection request/acceptance changes.
export const onConnectionNotificationOrchestration = onDocumentWritten(
  "connections/{connectionId}",
  async (event) => {
    const connectionId = event.params.connectionId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const db = admin.firestore();

    try {
      await handleConnectionNotificationChanges(
        db,
        connectionId,
        before,
        after,
      );
    } catch (error) {
      logger.error("Failed connection notification orchestration", {
        connectionId,
        error,
      });
      throw error;
    }
  },
);

// Service notification feature: reacts to service request creation/acceptance/rejection.
export const onServiceRequestNotificationOrchestration = onDocumentWritten(
  "serviceRequests/{requestId}",
  async (event) => {
    const requestId = event.params.requestId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const db = admin.firestore();

    try {
      await handleServiceRequestNotificationChanges(
        db,
        requestId,
        before,
        after,
      );

      if (serviceBecameCompleted(before, after) && after) {
        logger.info("Service request became completed", {
          requestId,
          beforeStatus: typeof before?.status === "string" ? before.status : "",
          afterStatus: typeof after.status === "string" ? after.status : "",
          providerId: after.providerId,
          requesterId: after.requesterId,
        });
        await applyServiceCompletionSideEffects(db, requestId, after);
        logger.info("Applied service completion side effects", { requestId });
      }
    } catch (error) {
      logger.error("Failed service request notification orchestration", {
        requestId,
        error,
      });
      throw error;
    }
  },
);

// Community post notification feature: fans out notifications when community posts are published.
export const onCommunityPostNotificationOrchestration = onDocumentWritten(
  {
    document: "communityPosts/{postId}",
    timeoutSeconds: 300,
    memory: "256MiB",
  },
  async (event) => {
    const postId = event.params.postId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const db = admin.firestore();

    try {
      await handleCommunityPostNotificationChanges(
        db,
        postId,
        before,
        after,
      );
    } catch (error) {
      logger.error("Failed community post notification orchestration", {
        postId,
        error,
      });
      throw error;
    }
  },
);

// Community post lifecycle feature: publishes scheduled drafts and returns expired posts to drafts.
export const reconcileCommunityPostLifecycle = onSchedule(
  "every 5 minutes",
  async () => {
    const db = admin.firestore();
    try {
      await processCommunityPostLifecycle(db);
    } catch (error) {
      logger.error("Failed community post lifecycle reconciliation", {error});
      throw error;
    }
  },
);

// Admin report notification feature: alerts scoped admins when a report is opened or needs review.
export const onReportNotificationOrchestration = onDocumentWritten(
  "reports/{reportId}",
  async (event) => {
    const reportId = event.params.reportId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const db = admin.firestore();

    try {
      await handleReportNotificationChanges(db, reportId, before, after);
    } catch (error) {
      logger.error("Failed report notification orchestration", {
        reportId,
        error,
      });
      throw error;
    }
  },
);

// Chat notification feature: creates notifications for new chat messages.
export const onChatMessageNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;
    const data = event.data?.data();
    if (!data) return;

    try {
      await notifyChatMessageCreated(admin.firestore(), chatId, data);
      logger.info("Created chat message notification", { chatId, messageId });
    } catch (error) {
      logger.error("Failed chat message notification", {
        chatId,
        messageId,
        error,
      });
      throw error;
    }
  },
);

// Verification sync feature: mirrors submitted/cancelled verification request state back to users/{uid}.
export const onVerificationRequestUserSync = onDocumentWritten(
  "verificationRequests/{requestId}",
  async (event) => {
    const requestId = event.params.requestId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const db = admin.firestore();

    try {
      if (verificationRequestBecameReady(before, after) && after) {
        await syncUserFromSubmittedVerificationRequest(db, after);
        logger.info("Synced user verification status after request submit", {
          requestId,
          userId: after.userId,
        });
      }

      if (verificationRequestBecameCancelled(before, after) && after) {
        await syncUserFromCancelledVerificationRequest(db, after);
        logger.info("Reset user verification status after request cancel", {
          requestId,
          userId: after.userId,
        });
      }
    } catch (error) {
      logger.error("Failed to sync user from verification request", {
        requestId,
        error,
      });
      throw error;
    }
  },
);

// Review publish feature: publishes hidden reviews after both parties review a completed marketplace transaction.
export const onBorrowRequestReviewActivity = onDocumentUpdated(
  "borrowRequests/{requestId}",
  async (event) => {
    const requestId = event.params.requestId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!shouldAttemptPublishAfterBorrowUpdate(before, after)) {
      return;
    }

    const db = admin.firestore();
    try {
      await publishEligibleReviewsForBorrowRequest(db, requestId);
      logger.info("Processed borrow request review publish", { requestId });
    } catch (error) {
      logger.error("Failed to publish borrow request reviews", {
        requestId,
        error,
      });
      throw error;
    }
  },
);

// Review publish feature: scheduled fallback publishes reviews after the grace period expires.
export const publishExpiredBorrowReviews = onSchedule(
  "every 1 hours",
  async () => {
    const db = admin.firestore();
    try {
      const processed = await publishGraceExpiredBorrowReviews(db);
      if (processed > 0) {
        logger.info("Published grace-expired borrow reviews", { processed });
      }
    } catch (error) {
      logger.error("Failed to publish grace-expired borrow reviews", { error });
      throw error;
    }
  },
);

// Trust score feature: recalculates trust and creates damage/low-trust reports after a review becomes public.
export const onReviewPublished = onDocumentUpdated(
  "reviews/{reviewId}",
  async (event) => {
    const reviewId = event.params.reviewId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!reviewBecamePublished(before, after)) {
      return;
    }

    const revieweeId = after?.revieweeId;
    if (typeof revieweeId !== "string" || revieweeId.length === 0) {
      logger.warn("Published review missing revieweeId", { reviewId });
      return;
    }

    const db = admin.firestore();

    try {
      await recalculateTrustScoreForUser(db, revieweeId, reviewId);
      await createDamageReportIfNeeded(db, reviewId, after ?? {});
      logger.info("Trust score recalculated after review publish", {
        reviewId,
        revieweeId,
      });
    } catch (error) {
      logger.error("Failed to process published review", {
        reviewId,
        revieweeId,
        error,
      });
      throw error;
    }
  },
);
