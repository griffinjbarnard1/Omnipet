import assert from "node:assert/strict";
import test from "node:test";

import { buildBusinessIngestionApp } from "./server.js";

test("normalizes incoming business payload", async (t) => {
  const app = buildBusinessIngestionApp();
  t.after(async () => {
    await app.close();
  });

  const response = await app.inject({
    method: "POST",
    url: "/v1/ingestion/business",
    payload: {
      source: "manual",
      externalId: "raw_99",
      name: "  Sunset Pet Lodge  ",
      category: "boarding",
      address: "  99 Ocean Ave, SF  ",
      lat: 37.75,
      lng: -122.45
    }
  });

  assert.equal(response.statusCode, 202);
  const body = response.json() as { normalized: { name: string; address: string; rating: number; reviewCount: number; summary: string } };
  assert.equal(body.normalized.name, "Sunset Pet Lodge");
  assert.equal(body.normalized.address, "99 Ocean Ave, SF");
  assert.equal(body.normalized.rating, 4);
  assert.equal(body.normalized.reviewCount, 0);
  assert.equal(body.normalized.summary, "No summary available");

  const listResponse = await app.inject({ method: "GET", url: "/v1/ingestion/business" });
  const listing = listResponse.json() as { count: number };
  assert.equal(listing.count, 1);
});
