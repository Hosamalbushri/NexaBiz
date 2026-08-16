# Device management

> Experimental — not production-ready.

## Identity

Flutter generates a stable per-install UUID (`SettingsKeys.syncDeviceId`)
and sends it at login / `POST /api/v1/devices/register`.

Statuses: `active` | `revoked` | `blocked`.

## APIs

- `GET /api/v1/devices` — list company devices with user name/email
  (needs `devices.view`)
- `POST /api/v1/devices/register`
- `POST /api/v1/devices/{id}/revoke` — needs `devices.revoke`; revokes bound sessions
- `POST /api/v1/devices/sync-disable-requests` — any company user requests sync
  disable on the current device (non-admins use this from Settings)
- `GET /api/v1/devices/sync-disable-requests` — pending requests for admins
- `POST /api/v1/devices/sync-disable-requests/{id}/approve` — revoke device and
  force the client back to local mode (`reason=sync_disable_approved`)
- `POST /api/v1/devices/sync-disable-requests/{id}/reject`

## Admin UI

Administration → Devices shows the registered devices list (revoke) and
pending sync-disable requests.

Revoked devices cannot authenticate or synchronize.
