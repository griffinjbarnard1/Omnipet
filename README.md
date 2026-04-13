# OmniPet

OmniPet is a **Search + Logistics engine with a premium pet-data vault**.

- **Hook:** discovery of vets, groomers, daycares, and boarders.
- **Retention:** the Vault, where pet records are stored and reused for one-tap check-ins.
- **Core job:** remove first-time friction by automating the owner ↔ business record handshake.

## Repository Scaffolding

```text
apps/
  ios/                      # Mobile-first client (SwiftUI scaffold)
docs/
  architecture/             # UX and technical architecture docs
  product/                  # Product intent and flows
services/
  search-logistics/         # Discovery, ranking, map pins, partner routing
  vault-share/              # Data-pack assembly + sharing workflow
  business-ingestion/       # Non-partner profile scraping/enrichment
packages/
  shared-contracts/         # Shared API/event contracts
```

## Product Surfaces

1. **Discovery Hub** (default home)
2. **Vault** (pet pass + documents + sharing)
3. **Smart Scanner** (OCR + quality gate + auto-tagging)
4. **Business Profile** (partner + non-partner conduit)
5. **Activity** (audit trail of data-sharing events)

See:
- `docs/product/universal-pet-passport.md`
- `docs/architecture/mobile-first-screen-architecture.md`
- `apps/ios/README.md`

## Next Implementation Milestones

1. Generate an Xcode project and wire the SwiftUI feature modules.
2. Implement Mapbox-backed Discovery with gray/emerald pin taxonomy.
3. Add OCR pipeline + refusal logic for low-light/blur captures.
4. Build secure temporary link + PDF summary generation in `vault-share`.
5. Implement Service Handshake state machine and activity auditing.
