const assert = require("node:assert/strict");
const test = require("node:test");

const {
  reportNeedsAdminNotification,
} = require("../lib/report_notifications");

test("reportNeedsAdminNotification fires when a report is created open", () => {
  assert.equal(
    reportNeedsAdminNotification(undefined, {status: "open"}),
    true,
  );
});

test("reportNeedsAdminNotification fires when report moves to underReview", () => {
  assert.equal(
    reportNeedsAdminNotification(
      {status: "open"},
      {status: "underReview"},
    ),
    true,
  );
});

test("reportNeedsAdminNotification ignores unchanged review status", () => {
  assert.equal(
    reportNeedsAdminNotification(
      {status: "underReview"},
      {status: "underReview"},
    ),
    false,
  );
});

test("reportNeedsAdminNotification ignores completed reports", () => {
  assert.equal(
    reportNeedsAdminNotification(undefined, {status: "resolved"}),
    false,
  );
});
