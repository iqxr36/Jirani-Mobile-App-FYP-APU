const assert = require("node:assert/strict");
const test = require("node:test");

const {
  extractNeighborIdsFromConnections,
  neighborActivityNotificationId,
  recipientWantsNeighborUpdates,
} = require("../lib/neighbor_activity_notifications");

test("extractNeighborIdsFromConnections returns only the other participant", () => {
  assert.deepEqual(
    extractNeighborIdsFromConnections("john", [
      { participants: ["john", "jason"] },
      { participants: ["john", "mary"] },
    ]),
    ["jason", "mary"],
  );
  assert.deepEqual(
    extractNeighborIdsFromConnections("john", [
      { participants: ["john"] },
      { participants: ["pending", "other"] },
    ]),
    ["pending", "other"],
  );
});

test("extractNeighborIdsFromConnections ignores invalid participant arrays", () => {
  assert.deepEqual(
    extractNeighborIdsFromConnections("john", [
      { participants: null },
      {},
      { participants: ["john", 42, "jason"] },
    ]),
    ["jason"],
  );
});

test("recipientWantsNeighborUpdates defaults to true when preference fields are absent", () => {
  assert.equal(recipientWantsNeighborUpdates({}), true);
  assert.equal(recipientWantsNeighborUpdates({ role: "resident" }), true);
});

test("recipientWantsNeighborUpdates respects notification and neighbor toggles", () => {
  assert.equal(
    recipientWantsNeighborUpdates({ notificationEnabled: false }),
    false,
  );
  assert.equal(
    recipientWantsNeighborUpdates({ neighborUpdatesEnabled: false }),
    false,
  );
  assert.equal(
    recipientWantsNeighborUpdates({
      notificationEnabled: true,
      neighborUpdatesEnabled: true,
    }),
    true,
  );
});

test("neighborActivityNotificationId is stable and slash-safe", () => {
  assert.equal(
    neighborActivityNotificationId("item/abc", "user/2"),
    "nb_item_abc_user_2",
  );
});
