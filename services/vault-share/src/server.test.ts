import assert from "node:assert/strict";
import test from "node:test";

import { buildVaultShareApp } from "./server.js";

test("creates share pack and emits activity", async (t) => {
  const app = buildVaultShareApp();
  t.after(async () => {
    await app.close();
  });

  const createResponse = await app.inject({
    method: "POST",
    url: "/v1/share-pack",
    payload: {
      ownerId: "owner_1",
      petId: "pet_1",
      businessId: "biz_1",
      delivery: "secure_link",
      consentTtlHours: 24,
      documentIds: ["doc_1", "doc_2"]
    }
  });

  assert.equal(createResponse.statusCode, 201);
  const created = createResponse.json() as { shareId: string; emittedEventId: string; secureUrl?: string };
  assert.ok(created.shareId.startsWith("share_"));
  assert.ok(created.emittedEventId.startsWith("evt_"));
  assert.ok(created.secureUrl?.includes(created.shareId));

  const activityResponse = await app.inject({
    method: "GET",
    url: "/v1/activity?ownerId=owner_1"
  });

  assert.equal(activityResponse.statusCode, 200);
  const activity = activityResponse.json() as { count: number; items: Array<{ ownerId: string; type: string }> };
  assert.equal(activity.count, 1);
  assert.equal(activity.items[0]?.ownerId, "owner_1");
  assert.equal(activity.items[0]?.type, "share_sent");
});

test("returns 400 for invalid share payload", async (t) => {
  const app = buildVaultShareApp();
  t.after(async () => {
    await app.close();
  });

  const response = await app.inject({
    method: "POST",
    url: "/v1/share-pack",
    payload: {
      ownerId: "owner_1"
    }
  });

  assert.equal(response.statusCode, 400);
});
