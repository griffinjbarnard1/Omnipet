# Discovery Path: End-to-End Status and Gaps

This document tracks what currently works for the iOS discovery path and what is still missing to make it production-ready.

## Working End-to-End (Scaffold)

1. User opens **Discovery** tab and searches/filter by category.
2. User opens a **Business Profile** from discovery results.
3. App checks business requirements against Vault documents.
4. App shows readiness + missing requirement gaps inline.
5. User taps **Check-In with Vault** (when ready).
6. A new event is written to **Activity**.

## Gaps Identified

### Data and APIs
- Discovery now queries Apple Maps (`MKLocalSearch`) for live internet listings across vet/daycare/grooming/boarding plus pet-sitter terms.
- Boarding "individual host" detection is currently heuristic (name/query text match like "pet sitter" / "in-home"), not a dedicated marketplace integration.
- Requirement matching is string-based and not backed by canonical medical codes.
- Activity status timestamps are static text (not true time/event objects).

### UX and Flows
- No explicit map/pin surface yet in Discovery.
- No explicit "Fix in Vault" deep link for missing requirements.
- Check-in success/failure has no confirmation sheet or toast feedback.

### Platform/Architecture
- No persistence layer (state resets on app restart).
- No analytics events for search, profile open, and handshake attempts.
- No async networking/error handling path for discovery/check-in.

### Reliability and Compliance
- No consent capture before packet sharing.
- No outbound audit payload beyond local activity row.
- No retry/queue behavior for offline mode.
