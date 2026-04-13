# Mobile-First Screen Architecture

## Navigation Model

A floating 3-tab dock anchors the app:
- `Search`
- `Vault`
- `Activity`

Primary flow priority:
1. Discovery (entry)
2. Business profile + check-in action
3. Vault-assisted sharing
4. Activity confirmation

## Screen Breakdown

## 1) Discovery Hub (Hook)

### Components
- Category action cards: Vet, Daycare, Groomers, Boarding
- Natural-language search bar
- Map layer with pin taxonomy
  - **Gray:** scraped/non-partner listing
  - **Emerald:** partner listing with native booking
- Smart suggestions (`Expiring Soon?`)

### Responsibilities
- Resolve user intent to location + category filters.
- Rank search results by relevance, distance, and quality signals.
- Route to Business Profile with pinned context.

## 2) Vault (Retention)

### Components
- Pet Pass (photo, breed, vaccine badge)
- Document grid (Medical, Certificates, Identity, Diet)
- Share Sheet (`Send Records`)

### Responsibilities
- Store structured and unstructured pet documents.
- Support package generation:
  - Temporary secure web link
  - Professional PDF summary
- Enforce owner consent before send.

## 3) Smart Scanner (Data Entry)

### Components
- Camera with frame leveler
- OCR scan-line animation
- Auto-tagging confirmation toast
- Capture refusal logic for unreadable images

### Responsibilities
- Run quality gate before capture (light, blur, perspective).
- OCR + entity extraction (vaccine type, clinic, date).
- Suggest destination folder and metadata tags.

## 4) Business Profile (Conduit)

### Components
- Unified profile card (partner + non-partner)
- AI-enriched details for scraped businesses
- Primary CTA: `Check-In with Vault`
- Requirements checklist preview

### Responsibilities
- Present trustable business summary.
- Trigger Service Handshake flow.
- Provide fallback contact actions (call, directions, website).

## 5) Activity (Trust Layer)

### Components
- Recent share log with status timeline
- Opened/sent/action-needed labels

### Responsibilities
- Persist outbound share events.
- Show where and when data was sent.
- Surface resend / revoke actions (future iteration).

## Service Boundaries (High Level)

- `search-logistics`: search indexing, ranking, map pin shaping.
- `business-ingestion`: scrape + normalize non-partner profiles.
- `vault-share`: package assembly, secure links, PDF generation, email dispatch.
- `shared-contracts`: API schemas and event contracts.
