# OmniPet

> **OmniPet is a discovery-to-check-in platform for pet care, powered by a portable Pet Passport.**

OmniPet is built around a simple product truth:
- **Why people open it (Hook):** to discover the right Vet, Daycare, Groomer, Boarding provider, or in-home sitter.
- **Why people keep it (Retention):** their pet’s verified records live in the Vault, so every future check-in is faster and safer.

This repo contains the product vision, mobile UX architecture, iOS scaffold, and service-level contracts for the **Universal Pet Passport** experience.

---

## Table of Contents

1. [Product Thesis](#product-thesis)
2. [Core Experience](#core-experience)
3. [The Care Handshake (Signature Flow)](#the-care-handshake-signature-flow)
4. [Mobile-First UX Architecture](#mobile-first-ux-architecture)
5. [System Overview](#system-overview)
6. [Repository Structure](#repository-structure)
7. [Current Implementation Status](#current-implementation-status)
8. [Getting Started](#getting-started)
9. [Roadmap](#roadmap)
10. [Design Principles](#design-principles)

---

## Product Thesis

OmniPet’s mission is to eliminate **first-time friction** in pet care.

Today, owners repeatedly:
- Search for a provider.
- Re-enter pet details.
- Hunt for vaccine certificates.
- Email or upload documents manually.

OmniPet turns that fragmented process into one orchestrated workflow:
1. **Discover** the business.
2. **Prepare** required records automatically.
3. **Confirm** owner consent and sharing scope.
4. **Send** a professional onboarding pack (secure link or PDF).
5. **Track** data sharing in an activity log.

Think: **“Travel wallet + trusted handoff rail for pets.”**

---

## Core Experience

### 1) Discover Hub (The Hook)
Default entry surface designed like a premium travel app.

- Category action cards: Vet, Daycare, Grooming, Boarding
- Natural-language search (`"Groomers open on Sunday"`)
- Map-first discovery with pin taxonomy:
  - **Gray pins:** scraped / non-partner listings
  - **Emerald pins:** partner listings with richer in-app actions
- Smart prompts like **Expiring Soon?** when vault records are near lapse
- Ranking signals: relevance, distance, profile quality, and partner capability

### 2) Vault (The Retention Engine)
The owner-controlled source of truth for pet records.

- Pet Pass card (photo, breed, vaccine status)
- Document folders (Medical, Certificates, Identity, Diet)
- One-tap sharing via:
  - Temporary secure web link
  - Professional PDF summary

### 3) Smart Scanner (The Data Entry Layer)
Transforms uploads into structured, reusable records.

- Camera + gallery/file input
- OCR extraction and auto-tagging (clinic, vaccine, expiration)
- Quality/refusal logic for unreadable captures
- Guided recovery prompts for blurry or low-light scans

### 4) Business Profile (The Conduit)
Unified provider profile for partner and non-partner businesses.

- AI-enriched details for scraped listings
- Primary CTA: **Check-In with Vault** / **Send Intro Pack**
- Requirement pre-check before sharing records
- Contact fallback actions (call, site, directions) when check-in is not yet possible

### 5) Activity (Trust Layer)
Auditable history of where pet data was shared.

- Sent/opened/action-needed states
- Timeline for each outbound packet
- Foundation for future resend/revoke controls

---

## The Care Handshake (Signature Flow)

The Care Handshake is OmniPet’s core UX and business engine:

1. **Search** — owner finds a business.
2. **Select** — owner chooses Book / Check-In.
3. **Prepare** — OmniPet validates required records against Vault.
4. **Consent** — owner confirms what is being shared and for how long.
5. **Execute** — app sends a professional intro with attachments/link.
6. **Status** — event is logged in Activity.

This flow is what converts discovery traffic into repeat behavior.

---

## Mobile-First UX Architecture

### Navigation
A floating dock with 3 primary tabs:
- **Discover**
- **Vault**
- **Activity**

### Interaction Style (2026 target)
- Tactile, spatial UI over form-heavy screens
- High-contrast utility moments (e.g., check-in QR)
- Fast haptic/audio feedback on key actions
- Progressive disclosure: lightweight browse first, detailed handoff only when user commits

### Quick-Pass Recommendation
For best front-desk throughput, the **Quick-Pass (QR)** should be accessible from the lock screen via widget, while requiring app authentication before revealing full record details.

---

## System Overview

OmniPet is structured as cooperating services:

- **search-logistics**
  - Discovery indexing and ranking
  - Map pin shaping and partner routing
- **business-ingestion**
  - Scraping and normalization for non-partner businesses
- **vault-share**
  - Data-pack assembly
  - Secure-link creation
  - PDF summary generation
  - Outbound delivery
- **shared-contracts**
  - Common schemas/events used across services and clients
  - Canonical state definitions for the Care Handshake lifecycle

---

## Repository Structure

```text
apps/
  ios/                      # Mobile-first SwiftUI client scaffold

docs/
  architecture/             # UX and service boundary documentation
  product/                  # Product intent and journey framing

services/
  search-logistics/         # Discovery and ranking layer
  vault-share/              # Share-pack generation + delivery
  business-ingestion/       # Non-partner profile ingestion

packages/
  shared-contracts/         # Cross-service/API contract docs

figma/
  ...                       # Design brief and screen copy references
```

---

## Current Implementation Status

### ✅ Built and working in iOS prototype

- **Discovery tab**
  - Live Apple Maps search (`MKLocalSearch`)
  - Category filtering (Vet, Daycare, Grooming, Boarding)
  - List/map toggle, pull-to-refresh, favorites
  - Smart suggestion banners for expiring docs
  - Color-coded map pins
- **Vault tab**
  - VisionKit scan entry flow
  - Manual create/edit/delete of documents
  - Grouping by type (Medical, Certificates, Identity, Diet)
  - Expiration state tracking (expired / expiring soon / valid)
  - Pet pass card UI and local JSON persistence
  - Quick Pass QR surface for front-desk check-in
  - Multi-pet controls with active-pet remove flow
- **Activity tab**
  - Local check-in event history with statuses (Sent, Opened, Action Needed)
  - Detail views, relative timestamps, swipe-to-delete
- **Business Profile flow**
  - Category-specific intent capture
  - Requirement checklist with ready/missing/expired state
  - Local handshake history + call/website actions
- **Settings & onboarding**
  - Onboarding flow and single-pet setup
  - Local data stats and reset/replay controls
  - Account email editing + simulated cloud-sync toggle
- **Persistence layer**
  - Local JSON files for pet pass, documents, activity, and favorites
  - `UserDefaults` for onboarding/search state

### ⚠️ Partially implemented

- Document scanning captures images, but only metadata is currently persisted.
- Consent + activity creation are implemented, but share execution is local-only and simulated.
- Partnership state is static for live search results (`.nonPartner`), with richer partner states only in sample/local data.

### 🚫 Missing (known gaps)

- No production backend/API wiring (now replaced with an in-app backend simulator and contract-ready activity metadata)
- Cloud sync and account management are scaffolded locally with persistence hooks; production identity is still pending
- Multi-pet support now ships in Vault/Activity with active-pet switching
- Business inbox handoff is now simulated via a local business inbox actor; production portal is still pending
- Notification pipeline now includes local reminders for expiring records and local status pushes
- Search history/recent queries are now persisted and surfaced in Discover
- Reviews/ratings plus basic scheduling/messaging actions now exist in Business Profile

### Backend blocker (current highest-priority constraint)

The core value proposition—**securely sharing pet records with businesses and tracking real delivery/open states**—is blocked until backend services are available and integrated.

Current iOS flows are intentionally local-first and prove UX, but they cannot complete true handshake delivery without:

1. Auth + account system
2. Vault packet upload/storage service
3. Business-side retrieval endpoint/portal
4. Delivery + open/review event webhooks back into Activity

Until those services exist, check-in/sharing remains a prototype simulation.

---

## Getting Started

### Prerequisites
- Xcode 16+ (recommended for modern SwiftUI workflows)
- Swift 6 toolchain

### Read first
1. `docs/product/universal-pet-passport.md`
2. `docs/architecture/mobile-first-screen-architecture.md`
3. `apps/ios/README.md`
4. `packages/shared-contracts/service-handshake-flow.md`
5. `docs/architecture/discovery-party-e2e-gaps.md`

### Suggested build sequence
1. Generate/create the iOS project structure from the existing scaffold.
2. Implement Discovery map + search pipeline integration.
3. Implement Vault ingestion and document metadata model.
4. Implement share-pack generation (`vault-share`) and activity event logging.
5. Wire full Care Handshake end-to-end.

---

## Roadmap

### Near-term
- Wire SwiftUI screens to real view models and routes
- Add map provider integration and category filtering
- Add OCR pipeline with quality confidence scoring
- Generate secure temporary links + PDF exports

### Mid-term
- Partner business onboarding APIs
- Requirement prediction per provider type
- Consent and data-sharing policy controls

### Long-term
- Universal check-in interoperability
- Cross-city travel mode with expiring access codes
- Rich business dashboard for inbound OmniPet packets

---

## Design Principles

- Lead with discovery, but close the loop with trusted check-in.
- Make consent explicit and revocation understandable.
- Keep status legible: what was shared, with whom, and when.
- Reward complete Vault records with materially faster onboarding.
