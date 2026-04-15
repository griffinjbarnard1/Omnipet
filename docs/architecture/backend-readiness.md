# Backend readiness audit (April 15, 2026)

## What is now completed in this change

- Added real backend integration from `search-logistics` to `business-ingestion` via `INGESTION_BASE_URL`.
  - Search now fetches normalized businesses and merges them into ranking results.
  - Search health now exposes whether this downstream dependency is configured.
- Converted all backend services to exported app factories so they can be tested in-process and composed in integration environments.
- Replaced placeholder tests with service-level contract tests:
  - search request validation + ranking + ingestion integration
  - vault share-pack creation + activity emission
  - business-ingestion normalization defaults + listing retrieval

## Remaining blockers for **production**

The backend is **not 100% production-ready** yet. The following blockers are still present:

1. **No persistent storage**
   - All service state is in-memory, so restart loses events and ingested records.
2. **No authn/authz**
   - Endpoints accept unauthenticated requests and have no tenant isolation.
3. **No outbound provider integrations**
   - `vault-share` simulates queueing but does not integrate with actual email/PDF/link delivery infrastructure.
4. **No reliability controls**
   - Missing retry policies, dead-lettering, idempotency keys, and circuit-breaking around dependencies.
5. **No SLO/operability layer**
   - No metrics/tracing dashboards, alerting, or readiness probes beyond basic health.
6. **No compliance/security hardening**
   - No encryption key management, PHI/PII handling controls, audit immutability, or retention policies.

## Suggested next implementation order

1. Introduce Postgres (or equivalent) persistence for ingestion and activity.
2. Add service-to-service and client auth (JWT/OAuth + API scopes).
3. Integrate a durable job queue for `vault-share` delivery workflows.
4. Add OpenTelemetry traces + metrics + SLO alerts.
5. Add rate limits, idempotency keys, and structured failure/retry handling.
