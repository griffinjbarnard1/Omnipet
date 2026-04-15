# shared-contracts

Cross-service schemas for OmniPet APIs and events.

## Package
- Name: `@omnipet/shared-contracts`
- Runtime validation: `zod`
- Build output: `dist/`

## Included contracts
- Search request/response + map pin payload
- Ingestion payload contract for non-partner business normalization
- Vault share pack request contract
- Activity feed event contract

## Why this matters
- Keeps iOS and backend services aligned on schema shape
- Enables safe service evolution via shared versioned package
- Pushes validation to service boundaries for better reliability under load
