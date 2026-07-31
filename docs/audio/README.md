# Audio documentation and receipts

**Plan entry point (agents):** [`../AUDIO_PLAN.md`](../AUDIO_PLAN.md)

## Release-critical authority

| Path | Purpose |
| --- | --- |
| [`rights/README.md`](rights/README.md) | Audio chain-of-title package and release gate |
| [`rights/AUDIO_RIGHTS_LEDGER.json`](rights/AUDIO_RIGHTS_LEDGER.json) | Machine-readable rights and evidence ledger |
| [`../../scripts/validate_audio_rights.py`](../../scripts/validate_audio_rights.py) | Fail-closed shipping-rights validator |

Technical integration or a generation receipt does **not** establish commercial clearance. Run the rights validator before release tagging, store submission, or public marketing distribution.

## Production receipts

| File | Purpose |
| --- | --- |
| [`AUDIO_INVENTORY.json`](AUDIO_INVENTORY.json) | Batch 0 machine inventory |
| [`AUDIO_DEDUP_REPORT.md`](AUDIO_DEDUP_REPORT.md) | Hash / semantic dedup report |
| [`AUDIO_WORK_RECEIPT.md`](AUDIO_WORK_RECEIPT.md) | Batch 0 handoff receipt |
| `cities/` | Per-city audio receipts |

Upstream technical authority:

- [`../AUDIO_AGENT_EXECUTION.md`](../AUDIO_AGENT_EXECUTION.md)
- [`../AUDIO_ASSET_MANIFEST.json`](../AUDIO_ASSET_MANIFEST.json)
- [`../AUDIO_ASSET_PRODUCTION_BIBLE.md`](../AUDIO_ASSET_PRODUCTION_BIBLE.md)
- [`../AUDIO_EVENT_MAP.md`](../AUDIO_EVENT_MAP.md)
