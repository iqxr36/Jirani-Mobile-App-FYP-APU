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
  assertMarketplaceDepositResolutionForStoredRequest,
  isInvalidMinorDamageSettlement,
  refundIsReadyForManualPayout,
  assertManualPayoutCanBeMarkedPaid,
  minorDamageCorrectionAmounts,
} = settlementTestExports;

test("manualPayoutStatusAfterDepositDecision waits for borrower refund", () => {
  assert.equal(manualPayoutStatusAfterDepositDecision(0, "not_required"), "pending_manual");
  assert.equal(manualPayoutStatusAfterDepositDecision(40, "succeeded"), "pending_manual");
  assert.equal(manualPayoutStatusAfterDepositDecision(40, "pending"), "blocked");
  assert.equal(manualPayoutStatusAfterDepositDecision(40, "failed"), "blocked");
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
      depositRefundAmount: 100,
      refundStatus: "succeeded",
      manualPayoutStatus: "blocked",
      lenderTotalEarning: 25,
    }),
    true,
  );
  assert.equal(
    isStuckMarketplaceSettlement({
      depositStatus: "held",
      depositRefundAmount: 100,
      refundStatus: "succeeded",
      manualPayoutStatus: "blocked",
      lenderTotalEarning: 25,
    }),
    false,
  );
  assert.equal(
    isStuckMarketplaceSettlement({
      depositStatus: "refunded",
      depositRefundAmount: 100,
      refundStatus: "succeeded",
      manualPayoutStatus: "pending_manual",
      lenderTotalEarning: 25,
    }),
    false,
  );
});

test("minor damage rejects full-deposit deduction from stale admin clients", () => {
  const request = {
    status: "completed",
    itemConditionAfter: "minorDamage",
    minorDeductionAmount: 60,
  };
  assert.throws(
    () => assertMarketplaceDepositResolutionForStoredRequest(
      request,
      "full_deduction",
      100,
      100,
    ),
    /Minor damage cannot take the full deposit/,
  );
});

test("minor damage allows a valid partial deduction not exceeding the claim", () => {
  const request = {
    itemConditionAfter: "minorDamage",
    minorDeductionAmount: 60,
  };
  assert.doesNotThrow(() =>
    assertMarketplaceDepositResolutionForStoredRequest(
      request,
      "partial_deduction",
      100,
      60,
    ),
  );
  assert.throws(
    () => assertMarketplaceDepositResolutionForStoredRequest(
      request,
      "partial_deduction",
      100,
      70,
    ),
    /cannot exceed the lender's requested amount/,
  );
});

test("major damage still allows a full deduction", () => {
  assert.doesNotThrow(() =>
    assertMarketplaceDepositResolutionForStoredRequest(
      {itemConditionAfter: "majorDamage"},
      "full_deduction",
      100,
      100,
    ),
  );
});

test("invalid minor settlement cannot be manually paid", () => {
  const request = {
    status: "completed",
    itemConditionAfter: "minorDamage",
    depositAmount: 100,
    depositStatus: "deducted",
    damageDeductionAmount: 100,
    depositRefundAmount: 0,
    refundStatus: "not_required",
  };
  assert.equal(isInvalidMinorDamageSettlement(request), true);
  assert.throws(
    () => assertManualPayoutCanBeMarkedPaid(request),
    /must be corrected/,
  );
});

test("manual payout waits until a positive refund succeeds", () => {
  const pending = {depositRefundAmount: 40, refundStatus: "pending"};
  assert.equal(refundIsReadyForManualPayout(pending), false);
  assert.throws(
    () => assertManualPayoutCanBeMarkedPaid(pending),
    /refund must succeed/,
  );
  assert.equal(
    refundIsReadyForManualPayout({...pending, refundStatus: "succeeded"}),
    true,
  );
});

test("minor correction refunds borrower and recalculates lender payout", () => {
  const result = minorDamageCorrectionAmounts({
    status: "completed",
    itemConditionAfter: "minorDamage",
    depositAmount: 100,
    depositStatus: "deducted",
    damageDeductionAmount: 100,
    depositRefundAmount: 0,
    minorDeductionAmount: 100,
    usageFeeAmount: 20,
    manualPayoutStatus: "pending_manual",
  }, 60);
  assert.equal(result.correctedDeductionAmount, 60);
  assert.equal(result.borrowerRefundAmount, 40);
  assert.equal(result.lenderTotalEarning, 80);
});

test("minor correction rejects a deduction equal to the deposit", () => {
  assert.throws(
    () => minorDamageCorrectionAmounts({
      status: "completed",
      itemConditionAfter: "minorDamage",
      depositAmount: 100,
      depositStatus: "deducted",
      damageDeductionAmount: 100,
      depositRefundAmount: 0,
      minorDeductionAmount: 100,
      manualPayoutStatus: "pending_manual",
    }, 100),
    /less than the deposit/,
  );
});

test("minor correction rejects an already-paid payout", () => {
  assert.throws(
    () => minorDamageCorrectionAmounts({
      status: "completed",
      itemConditionAfter: "minorDamage",
      depositAmount: 100,
      depositStatus: "deducted",
      damageDeductionAmount: 100,
      depositRefundAmount: 0,
      minorDeductionAmount: 100,
      manualPayoutStatus: "paid",
    }, 60),
    /already paid/,
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
