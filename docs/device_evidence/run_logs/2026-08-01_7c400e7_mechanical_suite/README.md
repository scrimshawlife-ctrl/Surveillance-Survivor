# Device mechanical suite run logs — 2026-08-01

Archived from repo-root transient logs after local/main reconcile so the suite
evidence is versioned (not abandoned) and root clutter can be gitignored.

| Field | Value |
| --- | --- |
| Date (UTC window) | 2026-08-01 ~23:18–23:25 |
| Device | iPhone 17 Pro `00008150-000A6C120CB8401C` |
| Binary / suite tip | `7c400e7` (later residual re-pin `f2406fc` for live extract + idle fix) |
| Team | `X9M969D8M3` |

## Outcomes (from logs)

| Log | Result |
| --- | --- |
| `device-smoke-preflight.log` | launch-gate / art-qa / repo-status honest PASS (overall LAUNCH_BLOCKED) |
| `device-smoke-run.log` | device-smoke **pass** (deploy + dual-launch liveness) |
| `device-test-run.log` | 14 UI tests **TEST SUCCEEDED** (0 failures) |
| `device-accept-run.log` | DeviceAcceptance force-extract UI **TEST SUCCEEDED** |
| `launch-smoke-run.log` | launch-shell smoke **pass** (real splash + start menu) |

These logs are raw xcodebuild / script transcripts. Authoritative live-extract
JSON remains under `docs/device_evidence/live_extract_*`.
