# Mobile-First Screen Architecture

## Naming System (Canonical)

To keep product language consistent across app, docs, and services:
- **Tab name:** `Discover` (not `Search` in user-facing copy)
- **Signature flow name:** `Care Handshake` (formerly “Service Handshake”)
- **Record bundle name:** `Vault Packet`
- **State log name:** `Activity`

## Navigation Model

A floating 3-tab dock anchors the app:
- `Discover`
- `Vault`
- `Activity`

Primary flow priority:
1. Discover (entry)
2. Business Profile + check-in action
3. Vault-assisted preparation
4. Consent confirmation
5. Activity visibility

## Screen Breakdown

## 1) Discover Hub (Hook)

### Components
- Category action cards: Vet, Daycare, Groomers, Boarding
- Natural-language search bar
- Map layer with pin taxonomy
  - **Gray:** scraped/non-partner listing
  - **Emerald:** partner listing with native booking
- Smart suggestions (`Expiring Soon?`)
- Flow-stage cards (`Find`, `Prepare`, `Share`) for first-time education

### Responsibilities
- Resolve user intent to location + category filters.
- Rank results by relevance, distance, listing quality, and partner capability.
- Route to Business Profile with selected context.

## 2) Vault (Retention)

### Components
- Pet Pass (photo, breed, vaccine badge)
- Document grid (Medical, Certificates, Identity, Diet)
- Share actions (`Send Records`, `Generate Packet`)

### Responsibilities
- Store structured and unstructured pet documents.
- Support package generation:
  - Temporary secure web link
  - Professional PDF summary
- Enforce owner consent before final send.

## 3) Smart Scanner (Data Entry)

### Components
- Camera with frame leveler
- OCR scan-line animation
- Auto-tagging confirmation
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
- Fallback actions: call, directions, website

### Responsibilities
- Present trustable business summary.
- Trigger Care Handshake flow.
- Provide clear blocker reasons and next action to unblock.

## 5) Activity (Trust Layer)

### Components
- Recent share log with status timeline
- Sent/opened/action-needed labels
- Future: resend, revoke, and receipt metadata

### Responsibilities
- Persist outbound share events.
- Show where and when data was sent.
- Surface lifecycle state changes in plain language.

## Service Boundaries (High Level)

- `search-logistics`: discovery indexing, ranking, map pin shaping.
- `business-ingestion`: scrape + normalize non-partner profiles.
- `vault-share`: packet assembly, secure links, PDF generation, dispatch.
- `shared-contracts`: API schemas and Care Handshake event contracts.
