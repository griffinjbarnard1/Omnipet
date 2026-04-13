# Discover Flow: End-to-End Status and Gaps

This document tracks what currently works for the iOS Discover path, where the flow breaks, and what should be built next.

## Canonical Flow Stages

1. **Find** — user searches and filters businesses in Discover.
2. **Inspect** — user opens Business Profile and reviews fit + trust signals.
3. **Prepare** — app checks requirements against Vault records.
4. **Consent** — user confirms what to share.
5. **Handoff** — vault packet is sent and logged.
6. **Observe** — Activity reflects delivery lifecycle.

## Working End-to-End (Current Scaffold)

1. User opens **Discover** tab and searches/filter by category.
2. User opens a **Business Profile** from discovery results.
3. App checks business requirements against Vault documents.
4. App shows readiness + missing requirement gaps inline.
5. User taps **Check-In with Vault** (when ready).
6. A new event is written to **Activity**.

## What Is Well Thought Out Today

- Discover-to-profile routing is simple and quick.
- Requirement checks are visible before users attempt sharing.
- Blocked check-ins have a direct `Fix in Vault` reroute.
- Check-in attempts create explicit Activity timeline entries.

## Gaps and Required Changes

### 1) Discovery Data Quality
- Live results currently come from `MKLocalSearch`; this is good for breadth but lacks source confidence and partner metadata depth.
- Boarding host detection is heuristic (string match on “pet sitter”, “in-home”).
- No confidence score exists for category inference.

**Needed next:**
- Add `listingConfidence` and `source` to discovery models.
- Add explicit “individual host” source flag from ingestion pipeline (not UI heuristics).

### 2) Discover UX Clarity
- No map canvas/pin interaction yet (list-only UI).
- Users don’t see flow progress (Find → Prepare → Share) on first use.
- Missing empty-state education around why Vault readiness matters.

**Needed next:**
- Add map + pin taxonomy (gray/emerald) in Discover.
- Add stage cards describing handshake steps.
- Add contextual copy for missing-record consequences.

### 3) Consent and Compliance
- No explicit consent gate appears before packet send.
- No selectable scope (which docs, for how long).
- Activity does not capture policy metadata.

**Needed next:**
- Add consent sheet before `Check-In with Vault` final action.
- Store share policy snapshot with each activity event.
- Show consent summary in Activity detail.

### 4) Platform and Reliability
- No durable persistence (state resets on app restart).
- No retry queue for offline handoff attempts.
- No analytics around stage drop-off.

**Needed next:**
- Add local store for discovery history + activity events.
- Add outbound queue and retry policy.
- Track stage events: query, profile_open, prepare_pass/fail, consent_complete, handoff_sent.

## Definition of Done for Discover v1

Discover v1 should be considered complete when all are true:
- Users can browse with list + map surfaces.
- Category and listing-type confidence are visible and explainable.
- Users can complete consent-based handoff in < 3 taps from a ready profile.
- Every send attempt is durable, auditable, and time-stamped.
- Activity shows lifecycle updates beyond static text (sent/opened/action-needed with real timestamps).
