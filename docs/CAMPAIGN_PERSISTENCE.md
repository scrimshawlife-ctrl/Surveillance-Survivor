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
2. If `schemaVersion` is greater than current → **fail closed** to `CampaignProgress.initial` and set diagnostic `unsupported-future-schema-N`. The raw envelope in defaults is **preserved** and must not be overwritten by later `save` / `applyRunOutcome` calls (downgrade safety).
3. If bare legacy `CampaignProgress` JSON is found → load + sanitize; diagnostic `migrated-legacy-bare-progress`; next save rewrites the envelope.
4. Corrupt/truncated data → initial progress + diagnostic `corrupt-or-unreadable` (recovery writes are allowed).
5. `sanitized()` clamps levels and drops duplicate/unknown district IDs.

## Write rules

- Every successful `save` / `applyRunOutcome` writes a versioned envelope **unless** the load diagnostic is `unsupported-future-schema-*` or `unsupported-past-schema-*` (payload preserved).
- Defeat records `lastPlayedDistrict` only; it never raises unlock level.
- Completing a district is idempotent for `completedDistricts`.
- Extraction in a **locked** district (daily/weekly challenges may visit any city)
  updates `lastPlayedDistrict` only — it must not append `completedDistricts` or
  raise `highestUnlockedLevel`.
- Successful extraction advances unlock by **one step** only when the completed
  district is exactly the current frontier (`completedLevel == highestUnlockedLevel`).

`MasteryProgressStore` follows the same unsupported-schema preserve-on-write rule for `surveillance.masteryProgress`.

## Next-district picker and cold launch

Campaign unlocks alone do not choose the live session. App-layer selection uses a second key:

| Field | Meaning |
|---|---|
| Storage key | `surveillance.nextDistrict` via `@AppStorage` |
| Value | Raw `DistrictID` string (picker selection) |
| Clamp | Always through `CampaignProgress.resolveSelection` before use |

### Launch sequence (`RootView` → `GameScene`)

1. `CampaignProgressStore` loads unlocks from `surveillance.campaignProgress`.
2. `onAppear` clamps `nextDistrict` to an unlocked city.
3. `GameScene.bootstrapCampaignDistrictIfNeeded(choice)` rebuilds the live session for that district **without** advancing `runOrdinal`.
4. Bootstrap is a no-op when already on that district, or when a run has finished / a receipt exists (avoids wiping the post-run summary on a late `onAppear`).

### After a finished run

| Outcome | Picker update |
|---|---|
| Extraction win | `nextDistrict(after:)` — usually the newly unlocked city |
| Defeat | `resolveSelection(finishedDistrict)` — stay on a valid unlocked city |

“START NEXT RUN” calls `selectDistrict` + `startNextRun` (advances ordinal / seed). Daily/Weekly challenge entry uses `startChallengeRun` and writes the challenge district into `nextDistrict` for the next cold launch.

### Constraints

- Mid-run progress is **not** persisted; only unlocks + next-district preference survive relaunch.
- Simulation / `SurveillanceCore` never reads `UserDefaults`.
- Mastery / unlock cosmetics use a separate store (`MasteryProgressStore`) — see [`P11_REPLAYABILITY.md`](P11_REPLAYABILITY.md).

## Test isolation

App tests must use `UserDefaults(suiteName:)` unique per case and `removePersistentDomain` in `defer`.

Cold-launch district bootstrap is covered by `EmulatorCampaignUXTests.coldLaunchBootstrapsPersistedDistrictInsteadOfOpener`.
