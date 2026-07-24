# Surveillance Survivor — Remote Audio Agent Execution Packet

## Authority

This packet operationalizes [`AUDIO_ASSET_PRODUCTION_BIBLE.md`](AUDIO_ASSET_PRODUCTION_BIBLE.md). The production bible defines creative intent; [`AUDIO_ASSET_MANIFEST.json`](AUDIO_ASSET_MANIFEST.json) is the machine-readable work queue; `audio_events.json` remains runtime authority.

## Mission

Produce, intake, validate, and integrate the ElevenLabs audio bank without changing deterministic gameplay semantics or duplicating existing audio.

## Required opening audit

Before editing:

1. Run `git status --short` and preserve unrelated changes.
2. Read `AGENTS.md`, `docs/AUDIO_EVENT_MAP.md`, `docs/AUDIO_ASSET_PRODUCTION_BIBLE.md`, this file, and `docs/AUDIO_ASSET_MANIFEST.json`.
3. Inventory all audio binaries under `Resources/`, Xcode asset catalogs, bundles, and any delivery folders.
4. Hash every discovered binary with SHA-256.
5. Match files by exact stem, semantic role, duration, and perceptual similarity.
6. Record each manifest entry as one of:
   - `missing`
   - `generated_unreviewed`
   - `approved_master`
   - `derived_delivery`
   - `runtime_integrated`
   - `rejected_duplicate`
   - `deferred`
7. Never replace or regenerate an approved asset solely to obtain a different filename.

## Scope boundaries

### Runtime-ready now

Only the 11 stems already present in `Sources/SurveillanceCore/Resources/Content/audio_events.json` may be integrated without adding new deterministic event contracts.

### Reserved production assets

Ambience, music, city mechanics, enemy-specific cues, and boss phases may be produced and cataloged, but must not be represented as runtime-integrated until all of the following exist:

- deterministic source event or explicit scene-state projection;
- catalog definition and stable logical ID;
- app-layer playback mapping;
- cooldown and priority policy;
- automated tests;
- simulator evidence;
- physical-device audio evidence where required.

## Recommended work order

### Batch 0 — Audit and receipts

Deliver:

- `docs/audio/AUDIO_INVENTORY.json`
- `docs/audio/AUDIO_DEDUP_REPORT.md`
- `docs/audio/AUDIO_WORK_RECEIPT.md`

Do not generate audio until the inventory is complete.

### Batch 1 — Current runtime bank

Generate and integrate the 11 `runtime_required` entries first. Preserve the exact stems. Create three variants only where the manifest requests them; runtime may initially select the canonical approved render.

Acceptance:

- every catalog stem resolves;
- no silent missing-file fallback for these 11 cues;
- event priority and cooldown behavior remains unchanged;
- `AudioEventCatalogTests` pass;
- simulator build passes;
- rapid-fire and high-density combat do not clip.

### Batch 2 — Shared system bank

Produce shared movement, camera, enemy, combat, UI, ambience, and transition assets. Keep them unintegrated unless corresponding deterministic events already exist or are added in a focused code change.

### Batch 3 — Five reusable district beds

Produce modular ambience layers for:

- retail security zone;
- smart downtown;
- gated serenity;
- civic innovation campus;
- evidence warehouse.

These must be reusable foundations. City ambience should layer on top instead of replacing them.

### Batches 4–13 — Cities in campaign order

1. Wichita
2. Louisville
3. Tulsa
4. Dayton
5. Oakland
6. San Francisco
7. Columbus
8. New York City
9. Los Angeles
10. Atlanta

For each city:

1. audit all shared and prior-city assets;
2. reuse neutral layers;
3. generate only city-identity layers, city mechanic cues, music, and boss material;
4. produce a city receipt under `docs/audio/cities/<city>_audio_receipt.md`;
5. update manifest statuses and hashes;
6. perform iPhone-speaker translation checks.

### Batch 14 — Atlanta convergence and final boss

Atlanta callback sounds must reuse approved source assets from prior cities. Do not regenerate imitations. Build the convergence through layering, filtering, editing, and spatial treatment of the canonical source masters.

## ElevenLabs production protocol

For each manifest entry:

1. Copy the exact `prompt` and append the universal negative prompt from the production bible.
2. Generate at least three candidates for critical one-shots, music, boss phases, or loops.
3. Select based on gameplay readability, not cinematic impact.
4. Export the best candidate as 48 kHz / 24-bit WAV when supported.
5. Trim silence, remove DC offset, create clean fades, and verify loop seams.
6. Loudness-normalize by category according to the production bible.
7. Store the untouched ElevenLabs export and processed master separately.
8. Record ElevenLabs generation ID, generation date, model, prompt, and license/provenance.
9. Compute SHA-256 for the approved master and delivery derivative.
10. Do not commit lossy preview files when a production master is available.

## Directory contract

```text
Resources/Audio/
  Masters/                 # approved 48 kHz / 24-bit WAV sources
    Runtime/
    Shared/
    Cities/<city>/
  Delivery/                # CAF or AAC/M4A consumed by the app
    Runtime/
    Shared/
    Cities/<city>/

docs/audio/
  AUDIO_INVENTORY.json
  AUDIO_DEDUP_REPORT.md
  AUDIO_WORK_RECEIPT.md
  cities/<city>_audio_receipt.md
```

Do not add binary audio to `Sources/SurveillanceCore`; the deterministic package owns event definitions, not playback media.

## Integration constraints

- Playback belongs in the app/platform layer.
- Asset availability must never alter simulation state.
- Missing reserved assets must fail silently or use an explicitly approved fallback.
- Do not perform file or network I/O on the fixed-step path.
- Do not use intelligible speech for MVP.
- Do not use real police radio, dispatch, airport, transit, or public-address recordings.
- Do not use copyrighted music, sonic logos, celebrity voices, or voice clones.
- Preserve interruption safety, audio-session recovery, and user settings.

## Validation commands

Run the narrowest checks after each focused batch, then the full relevant gate:

```bash
make test
make build
make simulator-test
make validate
```

For binary intake, also add or run an audio validation command that checks:

- expected filename stems;
- allowed extensions;
- sample rate and channels;
- duration bounds;
- true peak;
- loop metadata or seam report;
- duplicate hashes;
- missing provenance;
- orphaned binaries;
- manifest/runtime catalog drift.

Physical-device evidence is required for final acceptance of:

- iPhone speaker intelligibility;
- headphone and Bluetooth balance;
- silent-mode policy;
- interruptions and route changes;
- music ducking;
- dense-combat clipping;
- accessibility settings.

## Required handoff

End every audio batch with:

- changed files;
- generated assets and manifest IDs;
- reused or rejected duplicates;
- ElevenLabs generation provenance;
- validation commands and results;
- simulator/device evidence;
- unresolved integration targets;
- commit or PR state.

Never state that an asset is implemented merely because it exists as a WAV file.