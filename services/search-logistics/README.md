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

## Performance choices
- Fastify for high RPS and low serialization overhead
- Pre-validated query schema from `@omnipet/shared-contracts`
- Lightweight ranking function suitable for hot-path optimization later
