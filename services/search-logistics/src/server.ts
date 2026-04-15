import Fastify from "fastify";
import cors from "@fastify/cors";
import { nanoid } from "nanoid";
import {
  type BusinessListing,
  type IngestionPayload,
  searchRequestSchema,
  searchResponseSchema
} from "@omnipet/shared-contracts";

const sampleListings: BusinessListing[] = [
  {
    id: "biz_1",
    name: "Emerald Paws Vet",
    category: "vet",
    address: "100 Market St, San Francisco, CA",
    lat: 37.7936,
    lng: -122.3965,
    rating: 4.8,
    reviewCount: 932,
    partnershipTier: "verified_partner",
    capabilities: ["vault_checkin", "same_day"],
    freshnessHours: 2
  },
  {
    id: "biz_2",
    name: "Sunday Suds Grooming",
    category: "grooming",
    address: "500 Valencia St, San Francisco, CA",
    lat: 37.7649,
    lng: -122.4218,
    rating: 4.4,
    reviewCount: 121,
    partnershipTier: "non_partner",
    capabilities: ["call_only"],
    freshnessHours: 14
  }
];

const kmDistance = (lat1: number, lng1: number, lat2: number, lng2: number): number => {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const r = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return 2 * r * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

const mapIngestionToListing = (record: IngestionPayload): BusinessListing => ({
  id: `ing_${record.source}_${record.externalId}`,
  name: record.name,
  category: record.category,
  address: record.address,
  lat: record.lat,
  lng: record.lng,
  rating: record.rating ?? 4,
  reviewCount: record.reviewCount ?? 0,
  partnershipTier: "non_partner",
  capabilities: ["call_only"],
  freshnessHours: 24
});

export type SearchLogisticsOptions = {
  ingestionBaseUrl?: string;
};

export const buildSearchLogisticsApp = (options: SearchLogisticsOptions = {}) => {
  const app = Fastify({ logger: true });
  const ingestionBaseUrl = options.ingestionBaseUrl ?? process.env.INGESTION_BASE_URL;

  app.register(cors);

  app.get("/health", async () => ({
    ok: true,
    service: "search-logistics",
    dependencies: {
      businessIngestion: ingestionBaseUrl ? "configured" : "not_configured"
    }
  });

  app.get("/v1/search", async (request, reply) => {
    const parsed = searchRequestSchema.safeParse(request.query);

    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }

    let candidateListings = [...sampleListings];

    if (ingestionBaseUrl) {
      try {
        const response = await fetch(`${ingestionBaseUrl}/v1/ingestion/business`);
        if (response.ok) {
          const payload = (await response.json()) as { items?: IngestionPayload[] };
          const normalized = (payload.items ?? []).map(mapIngestionToListing);
          candidateListings = [...candidateListings, ...normalized];
        } else {
          request.log.warn({ statusCode: response.status }, "business-ingestion returned a non-200 response");
        }
      } catch (error) {
        request.log.warn({ err: error }, "failed to fetch business-ingestion listings");
      }
    }

    const q = parsed.data.query.toLowerCase();
    let ranked = candidateListings.filter((biz) => {
      const categoryOk = parsed.data.category ? biz.category === parsed.data.category : true;
      return categoryOk && (biz.name.toLowerCase().includes(q) || biz.address.toLowerCase().includes(q));
    });

    ranked = ranked
      .map((biz) => {
        const partnerBoost = biz.partnershipTier === "verified_partner" ? 0.6 : biz.partnershipTier === "partner" ? 0.35 : 0;
        const qualityScore = biz.rating / 5;
        const freshnessPenalty = Math.min(biz.freshnessHours / 72, 0.25);
        const distancePenalty =
          parsed.data.nearLat !== undefined && parsed.data.nearLng !== undefined
            ? Math.min(kmDistance(parsed.data.nearLat, parsed.data.nearLng, biz.lat, biz.lng) / 40, 0.4)
            : 0;

        return {
          biz,
          score: qualityScore + partnerBoost - freshnessPenalty - distancePenalty
        };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, parsed.data.limit)
      .map((entry) => entry.biz);

    const payload = {
      requestId: `search_${nanoid(8)}`,
      results: ranked,
      mapPins: ranked.map((result) => ({
        businessId: result.id,
        lat: result.lat,
        lng: result.lng,
        pinColor: result.partnershipTier === "non_partner" ? "gray" : "emerald",
        label: result.name
      })),
      generatedAt: new Date().toISOString()
    };

    return searchResponseSchema.parse(payload);
  });

  return app;
};

if (import.meta.url === `file://${process.argv[1]}`) {
  const app = buildSearchLogisticsApp();
  const port = Number(process.env.PORT ?? 4010);
  await app.listen({ host: "0.0.0.0", port });
}
