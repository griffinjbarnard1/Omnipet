# search-logistics

Discovery and routing domain service.

## Responsibilities
- Index businesses and categories.
- Resolve natural-language queries.
- Compute map pin payloads (`gray` scraped / `emerald` partner).
- Provide ranking + filter responses for mobile clients.

## API
- `GET /health`
- `GET /v1/search?query=vet&category=vet&nearLat=...&nearLng=...&limit=20`

## Integration
- Optional downstream dependency: `business-ingestion`
- Configure with `INGESTION_BASE_URL=http://localhost:4020`
- When configured, `GET /v1/search` merges ingested businesses into the ranked candidate set.

## Performance choices
- Fastify for high RPS and low serialization overhead
- Pre-validated query schema from `@omnipet/shared-contracts`
- Lightweight ranking function suitable for hot-path optimization later
