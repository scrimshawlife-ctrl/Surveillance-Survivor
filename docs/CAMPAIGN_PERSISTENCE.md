# Campaign persistence contract

Offline unlock storage for the ten-city campaign. The simulation never reads this store.

## Schema

| Field | Meaning |
|---|---|
| Storage key | `surveillance.campaignProgress` in `UserDefaults` |
| Envelope type | `CampaignProgressRecord` |
| `schemaVersion` | Currently `1` (`CampaignProgress.schemaVersion`) |
| `progress` | `CampaignProgress` value |

### `CampaignProgress`

| Field | Meaning |
|---|---|
| `highestUnlockedLevel` | 1…district count; cities with `level <=` this may be selected |
| `completedDistricts` | Ordered unique districts with successful Blind Spot extraction |
| `lastPlayedDistrict` | Last finished run (win or defeat) |

## Load rules

1. Prefer decoding `CampaignProgressRecord`.
2. If `schemaVersion` is greater than current → **fail closed** to `CampaignProgress.initial` and set diagnostic `unsupported-future-schema-N` (prior data left untouched in defaults until a supported write occurs).
3. If bare legacy `CampaignProgress` JSON is found → load + sanitize; diagnostic `migrated-legacy-bare-progress`; next save rewrites the envelope.
4. Corrupt/truncated data → initial progress + diagnostic `corrupt-or-unreadable`.
5. `sanitized()` clamps levels and drops duplicate/unknown district IDs.

## Write rules

- Every successful `save` / `applyRunOutcome` writes a versioned envelope.
- Defeat records `lastPlayedDistrict` only; it never raises unlock level.
- Completing a district is idempotent for `completedDistricts`.

## Test isolation

App tests must use `UserDefaults(suiteName:)` unique per case and `removePersistentDomain` in `defer`.
