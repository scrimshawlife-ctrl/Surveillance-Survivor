# Audio media trees

**Do not place audio binaries in `Sources/SurveillanceCore`.**  
Deterministic event definitions live in the package; masters and delivery media live here.

```text
Masters/     approved 48 kHz / 24-bit WAV sources
  Runtime/   11 runtime_required stems
  Shared/    shared ambience / system cues
  Cities/<city>/
Delivery/    CAF or AAC/M4A consumed by the app
  Runtime/
  Shared/
  Cities/<city>/
```

Authority:

- `docs/AUDIO_ASSET_PRODUCTION_BIBLE.md`
- `docs/AUDIO_ASSET_MANIFEST.json`
- `docs/AUDIO_AGENT_EXECUTION.md`
- Batch receipts: `docs/audio/`

Empty `.gitkeep` dirs are intentional until Batch 1 intake.
