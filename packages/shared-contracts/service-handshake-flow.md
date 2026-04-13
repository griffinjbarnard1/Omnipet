# Care Handshake Contract (Draft)

> File retained as `service-handshake-flow.md` for compatibility; canonical product name is **Care Handshake**.

## Workflow States
1. `discovery_result_selected`
2. `requirements_prepared`
3. `consent_confirmed`
4. `handoff_sent`
5. `delivery_observed`

## Minimum Event Fields
- `event_id`
- `owner_id`
- `pet_id`
- `business_id`
- `state`
- `timestamp_utc`
- `package_type` (`secure_link` | `pdf_summary`)
- `consent_scope` (document ids/types included)
- `consent_expires_at_utc` (nullable)
