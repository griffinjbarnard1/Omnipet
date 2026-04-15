import { z } from "zod";

export const businessCategorySchema = z.enum([
  "vet",
  "daycare",
  "grooming",
  "boarding",
  "sitter"
]);

export const partnershipTierSchema = z.enum(["non_partner", "partner", "verified_partner"]);

export const businessListingSchema = z.object({
  id: z.string(),
  name: z.string(),
  category: businessCategorySchema,
  address: z.string(),
  lat: z.number(),
  lng: z.number(),
  rating: z.number().min(0).max(5),
  reviewCount: z.number().int().nonnegative(),
  partnershipTier: partnershipTierSchema,
  capabilities: z.array(z.string()).default([]),
  freshnessHours: z.number().nonnegative().default(0)
});

export const searchRequestSchema = z.object({
  query: z.string().min(1),
  category: businessCategorySchema.optional(),
  nearLat: z.number().optional(),
  nearLng: z.number().optional(),
  limit: z.number().int().min(1).max(50).default(20)
});

export const mapPinSchema = z.object({
  businessId: z.string(),
  lat: z.number(),
  lng: z.number(),
  pinColor: z.enum(["gray", "emerald"]),
  label: z.string()
});

export const searchResponseSchema = z.object({
  requestId: z.string(),
  results: z.array(businessListingSchema),
  mapPins: z.array(mapPinSchema),
  generatedAt: z.string().datetime()
});

export const ingestionPayloadSchema = z.object({
  source: z.enum(["google", "yelp", "manual"]),
  externalId: z.string(),
  name: z.string(),
  category: businessCategorySchema,
  address: z.string(),
  lat: z.number(),
  lng: z.number(),
  rating: z.number().min(0).max(5).optional(),
  reviewCount: z.number().int().nonnegative().optional(),
  summary: z.string().optional()
});

export const petDocumentSchema = z.object({
  id: z.string(),
  type: z.enum(["rabies", "distemper", "identity", "diet", "other"]),
  expiresAt: z.string().datetime().optional(),
  encryptedObjectRef: z.string()
});

export const sharePackRequestSchema = z.object({
  ownerId: z.string(),
  petId: z.string(),
  businessId: z.string(),
  delivery: z.enum(["secure_link", "pdf_email"]),
  consentTtlHours: z.number().int().min(1).max(168),
  documentIds: z.array(z.string()).min(1)
});

export const activityEventSchema = z.object({
  id: z.string(),
  type: z.enum(["share_sent", "share_opened", "share_expired", "action_required"]),
  ownerId: z.string(),
  petId: z.string(),
  businessId: z.string(),
  metadata: z.record(z.string(), z.string()),
  occurredAt: z.string().datetime()
});

export type BusinessListing = z.infer<typeof businessListingSchema>;
export type SearchRequest = z.infer<typeof searchRequestSchema>;
export type SearchResponse = z.infer<typeof searchResponseSchema>;
export type IngestionPayload = z.infer<typeof ingestionPayloadSchema>;
export type SharePackRequest = z.infer<typeof sharePackRequestSchema>;
export type ActivityEvent = z.infer<typeof activityEventSchema>;
