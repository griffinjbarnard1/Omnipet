# business-ingestion

Non-partner profile enrichment domain service.

## Responsibilities
- Scrape and normalize public business metadata.
- Enrich with review snippets and summary fields.
- Feed discovery index and profile API.

## API
- `GET /health`
- `POST /v1/ingestion/business`
- `GET /v1/ingestion/business`

## Performance choices
- Fastify server with strict input validation
- In-memory append-only queue pattern for low-latency ingestion prototype
- Typed normalization pipeline to reduce downstream parsing costs
