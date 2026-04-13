# Service Handshake Contract (Draft)

## Workflow States
1. `search_result_selected`
2. `requirements_prepared`
3. `share_confirmed`
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
