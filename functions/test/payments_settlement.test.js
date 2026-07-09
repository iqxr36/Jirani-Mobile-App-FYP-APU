const assert = require("node:assert/strict");
const test = require("node:test");

const {
  settlementTestExports,
} = require("../lib/payments");

const {
  manualPayoutStatusAfterDepositDecision,
  xenditRefundStatusToAppStatus,
  isStuckMarketplaceSettlement,
  assertServiceDisputeInput,
  serviceDisputeNotificationBody,
  moneyToMinorUnits,
  expectedHourlyServiceAmountMinor,
} = settlementTestExports;

test("manualPayoutStatusAfterDepositDecision unblocks lender unless refund failed", () => {
  assert.equal(manualPayoutStatusAfterDepositDecision(false), "pending_manual");
  assert.equal(manualPayoutStatusAfterDepositDecision(true), "blocked");
});

test("xenditRefundStatusToAppStatus maps provider statuses", () => {
  assert.equal(xenditRefundStatusToAppStatus("SUCCEEDED"), "succeeded");
  assert.equal(xenditRefundStatusToAppStatus("PENDING"), "pending");
  assert.equal(xenditRefundStatusToAppStatus("FAILED"), "failed");
});

test("isStuckMarketplaceSettlement detects resolved deposits blocked on payout", () => {
  assert.equal(
    isStuckMarketplaceSettlement({
      depositStatus: "refunded",
      manualPayoutStatus: "blocked",
      lenderTotalEarning: 25,
    }),
    true,
  );
  assert.equal(
    isStuckMarketplaceSettlement({
      depositStatus: "held",
      manualPayoutStatus: "blocked",
      lenderTotalEarning: 25,
    }),
    false,
  );
  assert.equal(
    isStuckMarketplaceSettlement({
      depositStatus: "refunded",
      manualPayoutStatus: "pending_manual",
      lenderTotalEarning: 25,
    }),
    false,
  );
});

test("assertServiceDisputeInput rejects invalid dispute types", () => {
  assert.throws(
    () => assertServiceDisputeInput("badType", "details"),
    /valid dispute type/,
  );
});

test("assertServiceDisputeInput requires details when type is other", () => {
  assert.throws(
    () => assertServiceDisputeInput("other", ""),
    /describe the issue/,
  );
  assert.doesNotThrow(() =>
    assertServiceDisputeInput("other", "Provider left early"),
  );
});

test("serviceDisputeNotificationBody includes type label and details", () => {
  const body = serviceDisputeNotificationBody("poorQuality", "Work was rushed");
  assert.match(body, /Poor quality/);
  assert.match(body, /Work was rushed/);
});

test("expectedHourlyServiceAmountMinor uses payment minor units", () => {
  assert.equal(expectedHourlyServiceAmountMinor(25, 2), 5000);
  assert.equal(expectedHourlyServiceAmountMinor(25, 1), 2500);
  assert.equal(moneyToMinorUnits(42.75), 4275);
});
