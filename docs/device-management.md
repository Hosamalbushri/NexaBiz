# Device management

> Experimental — not production-ready.

## Identity

Flutter generates a stable per-install UUID (`SettingsKeys.syncDeviceId`)
and sends it at login / `POST /api/v1/devices/register`.

Statuses: `active` | `revoked` | `blocked`.

## APIs

- `GET /api/v1/devices` — list (needs `devices.view`)
- `POST /api/v1/devices/register`
- `POST /api/v1/devices/{id}/revoke` — needs `devices.revoke`; revokes bound sessions

Revoked devices cannot authenticate or synchronize.
