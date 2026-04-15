# vault-share

Secure packaging and delivery domain service.

## Responsibilities
- Build onboarding packages from selected documents.
- Output package as secure temporary link or professional PDF.
- Dispatch outbound handoff emails.
- Emit share events for Activity feed.

## API
- `GET /health`
- `POST /v1/share-pack`
- `GET /v1/activity?ownerId=owner_1`

## Performance choices
- Shared contract validation at ingress
- Low-allocation event creation for activity feed writes
- Simple queue-ready response model (`status: queued`) for async providers later
