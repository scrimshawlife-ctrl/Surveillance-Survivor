# Audio Event Map (v2)

Current specification for mapping authoritative simulation events and run state to the bundled product audio bank.

**Status:** repository integration complete on `main`. The canonical catalog is
`Sources/SurveillanceCore/Resources/Content/audio_events.json` (schema 2), and
`docs/AUDIO_ASSET_MANIFEST.json` records all 68 assets as `runtime_integrated`.
Physical-device listening, rights confirmation, routing, interruption recovery,
and dense-combat mix acceptance remain release gates.

Related authorities:

- [`AUDIO_PLAN.md`](AUDIO_PLAN.md) for current status and work order
- [`AUDIO_ASSET_PRODUCTION_BIBLE.md`](AUDIO_ASSET_PRODUCTION_BIBLE.md) for production and acceptance standards
- [`audio/README.md`](audio/README.md) for receipts and provenance
- `Game/Feedback/AudioBank.swift` for bundle loading and AVFoundation playback
- `Game/Feedback/AudioCuePlayer.swift` for event and scene projection
- `Sources/SurveillanceCore/AudioEventCatalog.swift` and `AudioScene.swift` for deterministic resolution

## Principles

1. Simulation owns event and state truth. Audio only projects it.
2. Missing or unapproved assets fail silent. Product builds never substitute system sounds.
3. File and network I/O stay off the fixed-step simulation path.
4. Event cues use catalog priority and cooldown policy.
5. Persistent ambience, music, and extraction audio derive from `RunState` through `AudioSceneProjector`.
6. Boss-phase music uses authoritative `state.bossPhase`; presentation never infers phase identity from health.
7. District-scoped cues replace their generic event cue for that district, avoiding double playback.
8. Reusable shared beds are deterministic foundation layers beneath city identity ambience.

## Catalog coverage

| Mechanism | Assets | Authority |
| --- | ---: | --- |
| Event cues | 29 | `cues` in `audio_events.json` and `AudioCueResolver` |
| State-projected assets | 39 | `scenes` in `audio_events.json` and `AudioSceneProjector` |
| Total bundled bank | **68** | manifest, masters, CAF delivery files, bundle, and runtime tests |

The 29 event cues comprise 18 shared runtime/scan cues, ten district mechanic cues,
and Atlanta's final Blind Spot stinger. The 39 state-projected assignments comprise
five shared foundation beds plus district ambience, run/boss music, Atlanta's four
phase loops, and extraction overlay coverage. Assets may be referenced by more than
one district scene, but every manifest row has a deterministic runtime path.

## Event cue fields

| Field | Meaning |
| --- | --- |
| `id` | Stable cue identity (`AudioCueID`) |
| `assetName` | Bundled delivery filename stem |
| `category` | Combat, feedback, UI, ambience, music, or stinger role |
| `priority` | Higher-priority cue wins when competing cues fire together |
| `cooldownTicks` | Minimum deterministic ticks between repeats |
| `gain` | Linear playback gain |
| `bus` | Mix bus used by the runtime player |
| `triggers` | One or more authoritative `RunEvent.Kind` matchers |
| `districtId` | Optional district scope that replaces the generic cue |

## Scene projection

`AudioSceneProjector.scene(for:catalog:)` derives the persistent scene from
`RunState` without adding simulation state:

- foundation bed and city ambience follow `state.district`;
- run music changes to boss music while an authoritative boss is alive;
- Atlanta phase music follows `state.bossPhase`, defaulting to phase one only when phase identity is absent;
- the Blind Spot overlay follows `state.extractionOpen`;
- completed runs silence persistent loops so the completion stinger can carry the transition.

## Validation and release gate

```bash
make audio-check
make validate
```

`make audio-check` enforces manifest schema, master/delivery hashes, catalog parity,
bundle coverage, and runtime integration. Automated simulator evidence proves loading,
resolution, state projection, and silent missing-asset behavior. It does **not** prove:

- legal/rights approval;
- iPhone speaker and headphone balance;
- silent-mode policy;
- interruption and route-change recovery;
- Bluetooth behavior;
- dense-combat clipping or masking;
- subjective loop and mix quality on physical hardware.

Record those human/device results in [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) and
follow [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) before changing the
audio launch gate to ready.
