# OmniPet App Next Steps — Actionable One-Pass Execution

This plan breaks the current app scaffold into concrete chunks and marks what was completed in this pass.

## Chunk 1: Add a shared app state container

### Why
The scaffold had static sample values spread across screens. A single source of truth is required before wiring APIs.

### Actions
- Create `AppState` as a `@MainActor` `ObservableObject`.
- Centralize data for businesses, pet pass, vault documents, and activity events.
- Add simple intent methods for core flows:
  - `logCheckIn(for:)`
  - `sendVaultRecords()`

### Done in this pass
✅ Completed.

---

## Chunk 2: Wire state through the app shell

### Why
Views need the same shared state without manual prop-drilling for every screen.

### Actions
- Instantiate `@StateObject private var appState = AppState()` in `OmniPetApp`.
- Inject state once with `.environmentObject(appState)` on `RootTabView`.

### Done in this pass
✅ Completed.

---

## Chunk 3: Make Discovery interactive (search + category filtering)

### Why
The search tab is the acquisition hook and should support practical filtering behavior even before backend integration.

### Actions
- Bind query input to `appState.discoveryQuery`.
- Add selectable category chips backed by `AppState.DiscoveryCategory`.
- Compute and render `filteredBusinesses` from state.
- Add a no-results empty state.

### Done in this pass
✅ Completed.

---

## Chunk 4: Connect Vault actions to Activity output

### Why
Users should see immediate trust-layer feedback after sending records.

### Actions
- Bind Vault pet/document data to `AppState`.
- Hook “Send Records” button to `appState.sendVaultRecords()`.

### Done in this pass
✅ Completed.

---

## Chunk 5: Connect Business Profile handshake CTA

### Why
The signature flow depends on translating provider selection into a trackable event.

### Actions
- Hook “Check-In with Vault” CTA to `appState.logCheckIn(for:)`.
- Ensure Activity tab reflects new events at the top.

### Done in this pass
✅ Completed.

---

## Chunk 6: Improve Activity state handling

### Why
A resilient timeline surface should handle empty and non-empty states.

### Actions
- Render Activity list from `appState.events`.
- Add empty-state `ContentUnavailableView` fallback.

### Done in this pass
✅ Completed.

---

## Immediate follow-up chunks (next pass)

1. Replace relative `sentAtText` strings with timestamp-backed formatting.
2. Add lightweight persistence (local JSON/SwiftData) for app relaunch continuity.
3. Define protocol-based service interfaces for search, vault-share, and business ingestion.
4. Add async loading/error states per tab.
5. Add test coverage for `AppState.filteredBusinesses` and event insertion behavior.
