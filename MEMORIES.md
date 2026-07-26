# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| `EntityProjector.applyDeployableAppearance` used `deployableState(..., tick: 0)`, so time-expired deployables never reached expended art/alpha | TBD | open | 2026-07-26 |
| `ContentCatalog` payload validation only checked field presence; negative damage / wrong WeaponID↔payload contracts passed | TBD | open | 2026-07-26 |
| Acoustic gunshot detectors counted spent (`health <= 0`) projectiles before death cleanup | TBD | open | 2026-07-26 |
| `MasteryProgress.sanitized` kept unknown `challengeCompletions` keys, inflating unlock eligibility | TBD | open | 2026-07-26 |
| `RunReceiptStore` silent `try?` decode with no envelope/diagnostic/future-schema preservation | TBD | open | 2026-07-26 |
