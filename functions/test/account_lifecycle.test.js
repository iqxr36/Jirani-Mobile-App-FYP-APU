const test = require("node:test");
const assert = require("node:assert/strict");
const {
  deletedResidentProfileFields,
  normalizeResidentEmail,
  residentEmailHash,
  normalizeResidentPhone,
  residentPhoneHash,
  validateResidentPhone,
  validateResidentRegistrationInput,
  assertPhoneAvailable,
} = require("../lib/account_lifecycle");
const {HttpsError} = require("firebase-functions/v2/https");

test("normalizes email case and whitespace before hashing", () => {
  assert.equal(normalizeResidentEmail("  User@Example.COM "), "user@example.com");
  assert.equal(
    residentEmailHash(" User@Example.COM "),
    residentEmailHash("user@example.com"),
  );
});

test("different normalized emails have different restriction ids", () => {
  assert.notEqual(
    residentEmailHash("one@example.com"),
    residentEmailHash("two@example.com"),
  );
});

test("deletedResidentProfileFields scrubs PII but keeps community scope", () => {
  const fields = deletedResidentProfileFields(
    {
      communityId: "community-1",
      communityName: "One South",
      unitNumber: "A-12-03",
      email: "resident@example.com",
      phoneNumber: "+60123456789",
    },
    false,
  );

  assert.equal(fields.firstName, "Deleted");
  assert.equal(fields.lastName, "Resident");
  assert.equal(fields.fullName, "Deleted Resident");
  assert.equal(fields.email, "");
  assert.equal(fields.phoneNumber, "");
  assert.equal(fields.profileImageUrl, "");
  assert.equal(fields.communityId, "community-1");
  assert.equal(fields.communityName, "One South");
  assert.equal(fields.unitNumber, "A-12-03");
  assert.equal(fields.accountStatus, "deleted");
  assert.equal(fields.accountFlagged, false);
  assert.equal(fields.notificationEnabled, false);
});

test("deletedResidentProfileFields keeps accountFlagged for suspended accounts", () => {
  const fields = deletedResidentProfileFields(
    {
      communityId: "community-1",
      communityName: "One South",
      unitNumber: "",
    },
    true,
  );

  assert.equal(fields.accountStatus, "deleted");
  assert.equal(fields.accountFlagged, true);
});

test("normalizes resident phone numbers like Dart Validators", () => {
  assert.equal(normalizeResidentPhone(" +60 12-345 6789 "), "+60123456789");
  assert.equal(
    residentPhoneHash(" +60 12-345 6789 "),
    residentPhoneHash("+60123456789"),
  );
});

test("validateResidentPhone accepts normalized E.164 numbers", () => {
  assert.equal(validateResidentPhone("+60123456789"), "+60123456789");
});

test("validateResidentPhone rejects numbers without country code", () => {
  assert.throws(
    () => validateResidentPhone("60123456789"),
    (error) => error instanceof HttpsError && error.code === "invalid-argument",
  );
});

test("resident registration accepts complete Google resident fields", () => {
  const fields = validateResidentRegistrationInput({
    firstName: "Google",
    lastName: "Resident",
    phoneNumber: "+60 12-345 6789",
    communityId: "community-1",
    communityName: "One South",
    profileImageUrl: "https://example.com/avatar.png",
    termsAccepted: true,
  });

  assert.equal(fields.phoneNumber, "+60123456789");
  assert.equal(fields.communityId, "community-1");
  assert.equal(fields.termsAccepted, true);
});

test("resident registration rejects missing phone, community, and terms", () => {
  const valid = {
    firstName: "Google",
    lastName: "Resident",
    phoneNumber: "+60123456789",
    communityId: "community-1",
    communityName: "One South",
    profileImageUrl: "",
    termsAccepted: true,
  };

  assert.throws(
    () => validateResidentRegistrationInput({...valid, phoneNumber: ""}),
    (error) => error instanceof HttpsError && error.code === "invalid-argument",
  );
  assert.throws(
    () => validateResidentRegistrationInput({...valid, communityId: ""}),
    (error) => error instanceof HttpsError && error.code === "invalid-argument",
  );
  assert.throws(
    () => validateResidentRegistrationInput({...valid, termsAccepted: false}),
    (error) => error instanceof HttpsError && error.code === "failed-precondition",
  );
});

test("different normalized phones have different registry ids", () => {
  assert.notEqual(
    residentPhoneHash("+60111111111"),
    residentPhoneHash("+60222222222"),
  );
});

function phoneAvailabilityDb({registryOwner = null, profileIds = []} = {}) {
  return {
    collection(name) {
      if (name === "residentPhoneNumbers") {
        return {
          doc() {
            return {
              async get() {
                return {
                  exists: registryOwner !== null,
                  data: () => ({uid: registryOwner}),
                };
              },
            };
          },
        };
      }
      if (name === "users") {
        return {
          where() {
            return {
              limit() {
                return {
                  async get() {
                    return {docs: profileIds.map((id) => ({id}))};
                  },
                };
              },
            };
          },
        };
      }
      throw new Error(`Unexpected collection: ${name}`);
    },
  };
}

test("phone availability rejects a number owned by another resident", async () => {
  const db = phoneAvailabilityDb({registryOwner: "resident-2"});

  await assert.rejects(
    assertPhoneAvailable(db, "+60123456789", "resident-1"),
    (error) => error instanceof HttpsError && error.code === "already-exists",
  );
});

test("phone availability permits the authenticated resident's current number", async () => {
  const db = phoneAvailabilityDb({
    registryOwner: "resident-1",
    profileIds: ["resident-1"],
  });

  assert.equal(
    await assertPhoneAvailable(db, "+60123456789", "resident-1"),
    "+60123456789",
  );
});
