const assert = require("node:assert/strict");
const test = require("node:test");

const {serviceBecameCompleted} = require("../lib/service_completion");
const {buildPublicProfilePayload} = require("../lib/public_profile");

test("serviceBecameCompleted detects first transition into completed statuses", () => {
  assert.equal(
    serviceBecameCompleted({status: "inProgress"}, {status: "completedPayoutPending"}),
    true,
  );
  assert.equal(
    serviceBecameCompleted(
      {status: "completedPayoutPending"},
      {status: "completedPayoutSent"},
    ),
    false,
  );
  assert.equal(
    serviceBecameCompleted(undefined, {status: "completed"}),
    true,
  );
  assert.equal(
    serviceBecameCompleted({status: "disputed"}, {status: "refunded"}),
    false,
  );
});

test("buildPublicProfilePayload includes service counter fields", () => {
  const payload = buildPublicProfilePayload("resident-1", {
    role: "resident",
    firstName: "Aisha",
    lastName: "Rahman",
    verificationStatus: "verified",
    completedServices: 3,
    completedServicesProvided: 2,
    completedServicesRequested: 1,
  });

  assert.ok(payload);
  assert.equal(payload.completedServices, 3);
  assert.equal(payload.completedServicesProvided, 2);
  assert.equal(payload.completedServicesRequested, 1);
});
