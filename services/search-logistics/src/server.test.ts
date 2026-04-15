import assert from "node:assert/strict";
import test from "node:test";
import Fastify from "fastify";

import { buildSearchLogisticsApp } from "./server.js";

test("returns ranked sample listings for valid query", async (t) => {
  const app = buildSearchLogisticsApp();
  t.after(async () => {
    await app.close();
  });

  const response = await app.inject({
    method: "GET",
    url: "/v1/search?query=vet&limit=5"
  });

  assert.equal(response.statusCode, 200);
  const payload = response.json() as {
    results: Array<{ name: string; partnershipTier: string }>;
    mapPins: Array<{ pinColor: string }>;
  };
  assert.equal(payload.results.length, 1);
  assert.equal(payload.results[0]?.name, "Emerald Paws Vet");
  assert.equal(payload.results[0]?.partnershipTier, "verified_partner");
  assert.equal(payload.mapPins[0]?.pinColor, "emerald");
});

test("merges dynamic ingestion listings into search candidates", async (t) => {
  const ingestion = Fastify();
  ingestion.get("/v1/ingestion/business", async () => ({
    count: 1,
    items: [
      {
        source: "manual",
        externalId: "abc123",
        name: "Paws & Claws Daycare",
        category: "daycare",
        address: "200 King St, San Francisco, CA",
        lat: 37.778,
        lng: -122.39,
        rating: 4.7,
        reviewCount: 14,
        summary: "great"
      }
    ]
  }));
  await ingestion.listen({ host: "127.0.0.1", port: 0 });
  const address = ingestion.server.address();
  assert.ok(address && typeof address !== "string");

  const app = buildSearchLogisticsApp({ ingestionBaseUrl: `http://127.0.0.1:${address.port}` });

  t.after(async () => {
    await ingestion.close();
    await app.close();
  });

  const response = await app.inject({
    method: "GET",
    url: "/v1/search?query=paws"
  });

  assert.equal(response.statusCode, 200);
  const payload = response.json() as {
    results: Array<{ id: string; name: string; partnershipTier: string }>;
  };

  assert.ok(payload.results.some((result) => result.id === "ing_manual_abc123"));
  assert.ok(payload.results.some((result) => result.name === "Paws & Claws Daycare"));
  assert.ok(payload.results.some((result) => result.partnershipTier === "non_partner"));
});

test("returns 400 for invalid query payload", async (t) => {
  const app = buildSearchLogisticsApp();
  t.after(async () => {
    await app.close();
  });

  const response = await app.inject({
    method: "GET",
    url: "/v1/search?query="
  });

  assert.equal(response.statusCode, 400);
});
