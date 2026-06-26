const assert = require("node:assert/strict");
const test = require("node:test");

const {
  postBecamePublished,
  notificationTypeForPostType,
} = require("../lib/community_post_notifications");
const { communityPostNotificationId } = require("../lib/notifications");

test("postBecamePublished only when status becomes published", () => {
  assert.equal(
    postBecamePublished({ status: "draft" }, { status: "published" }),
    true,
  );
  assert.equal(
    postBecamePublished({ status: "published" }, { status: "published" }),
    false,
  );
  assert.equal(postBecamePublished(undefined, { status: "published" }), true);
  assert.equal(postBecamePublished({ status: "draft" }, undefined), false);
});

test("notificationTypeForPostType maps admin post types", () => {
  assert.equal(notificationTypeForPostType("news"), "communityNews");
  assert.equal(
    notificationTypeForPostType("announcement"),
    "communityAnnouncement",
  );
  assert.equal(notificationTypeForPostType("warning"), "communityWarning");
  assert.equal(notificationTypeForPostType("event"), "communityEvent");
  assert.equal(
    notificationTypeForPostType("maintenance"),
    "maintenanceNotice",
  );
});

test("communityPostNotificationId is stable and slash-safe", () => {
  assert.equal(
    communityPostNotificationId("post/1", "user/2"),
    "cp_post_1_user_2",
  );
});
