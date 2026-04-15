import Fastify from "fastify";
import cors from "@fastify/cors";
import { nanoid } from "nanoid";
import { ingestionPayloadSchema, type IngestionPayload } from "@omnipet/shared-contracts";

const normalizedStore: IngestionPayload[] = [];

const app = Fastify({ logger: true });
await app.register(cors);

app.get("/health", async () => ({ ok: true, service: "business-ingestion" }));

app.post("/v1/ingestion/business", async (request, reply) => {
  const parsed = ingestionPayloadSchema.safeParse(request.body);

  if (!parsed.success) {
    return reply.status(400).send({ error: parsed.error.flatten() });
  }

  const incoming = parsed.data;
  const normalized: IngestionPayload = {
    ...incoming,
    name: incoming.name.trim(),
    address: incoming.address.trim(),
    rating: incoming.rating ?? 4.0,
    reviewCount: incoming.reviewCount ?? 0,
    summary: incoming.summary ?? "No summary available"
  };

  normalizedStore.unshift(normalized);

  return reply.status(202).send({
    id: `ing_${nanoid(9)}`,
    acceptedAt: new Date().toISOString(),
    normalized
  });
});

app.get("/v1/ingestion/business", async () => ({
  count: normalizedStore.length,
  items: normalizedStore.slice(0, 50)
}));

const port = Number(process.env.PORT ?? 4020);
await app.listen({ host: "0.0.0.0", port });
