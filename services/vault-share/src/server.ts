import Fastify from "fastify";
import cors from "@fastify/cors";
import { nanoid } from "nanoid";
import { activityEventSchema, sharePackRequestSchema, type ActivityEvent } from "@omnipet/shared-contracts";

export type VaultShareOptions = {
  initialActivityFeed?: ActivityEvent[];
};

export const buildVaultShareApp = (options: VaultShareOptions = {}) => {
  const activityFeed: ActivityEvent[] = [...(options.initialActivityFeed ?? [])];
  const app = Fastify({ logger: true });
  app.register(cors);

  app.get("/health", async () => ({ ok: true, service: "vault-share" }));

  app.post("/v1/share-pack", async (request, reply) => {
    const parsed = sharePackRequestSchema.safeParse(request.body);

    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }

    const data = parsed.data;
    const shareId = `share_${nanoid(10)}`;
    const expiresAt = new Date(Date.now() + data.consentTtlHours * 60 * 60 * 1000).toISOString();
    const secureUrl = `https://vault.omnipet.local/share/${shareId}`;

    const event = activityEventSchema.parse({
      id: `evt_${nanoid(10)}`,
      type: "share_sent",
      ownerId: data.ownerId,
      petId: data.petId,
      businessId: data.businessId,
      metadata: {
        shareId,
        delivery: data.delivery,
        documentCount: String(data.documentIds.length)
      },
      occurredAt: new Date().toISOString()
    });

    activityFeed.unshift(event);

    return reply.status(201).send({
      shareId,
      status: "queued",
      expiresAt,
      secureUrl: data.delivery === "secure_link" ? secureUrl : undefined,
      pdfJobId: data.delivery === "pdf_email" ? `pdf_${nanoid(8)}` : undefined,
      emittedEventId: event.id
    });
  });

  app.get("/v1/activity", async (request) => {
    const ownerId = (request.query as { ownerId?: string }).ownerId;
    return {
      count: ownerId ? activityFeed.filter((item) => item.ownerId === ownerId).length : activityFeed.length,
      items: ownerId ? activityFeed.filter((item) => item.ownerId === ownerId) : activityFeed
    };
  });

  return app;
};

if (import.meta.url === `file://${process.argv[1]}`) {
  const app = buildVaultShareApp();
  const port = Number(process.env.PORT ?? 4030);
  await app.listen({ host: "0.0.0.0", port });
}
