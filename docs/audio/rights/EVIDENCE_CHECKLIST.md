# Audio Rights Evidence Checklist

Complete this checklist for each generation/acquisition batch and link the resulting evidence IDs to every affected asset.

## Provider or vendor evidence

- [ ] Provider/vendor legal name and product identified.
- [ ] Generation/acquisition date recorded.
- [ ] Account custodian or contracting party recorded privately.
- [ ] Plan tier, invoice, order, or executed license archived.
- [ ] Applicable terms/license captured with effective date and SHA-256.
- [ ] Product was not a Beta/preview service, or separate commercial authorization is archived.
- [ ] Intended media includes interactive games and required marketing uses.
- [ ] Commercial use, modification, distribution, and platform sublicensing are permitted.
- [ ] Territory and term cover the release plan.
- [ ] Attribution and credit obligations are recorded.
- [ ] Termination, revocation, takedown, or usage-cap conditions are recorded.

## Asset provenance

- [ ] Stable manifest `asset_id` recorded.
- [ ] Master file SHA-256 matches the technical manifest.
- [ ] Prompt, order ID, generation ID, export ID, session, or source URL is archived where available.
- [ ] No unlicensed reference audio, song, sample, lyric, script, voice, or performance was uploaded.
- [ ] No recognizable music quotation, branded sonic mark, celebrity imitation, or third-party recording is present.
- [ ] Derivatives and delivery conversions retain lineage to the cleared master.

## Human contribution

- [ ] Contributor identity and contact are recorded privately.
- [ ] Signed assignment/license is archived.
- [ ] Compensation and credit terms are documented.
- [ ] Performer/voice consent covers recording, editing, synthesis, marketing, reuse, and distribution as applicable.
- [ ] Contributor warrants originality and discloses third-party material.
- [ ] Minor contributors have valid guardian authorization.

## Review and approval

- [ ] Evidence document hashes recorded in `AUDIO_RIGHTS_LEDGER.json`.
- [ ] Evidence status is `verified`.
- [ ] Third-party IP review is `passed`.
- [ ] Restrictions are compatible with the release intent.
- [ ] Named reviewer and review date recorded.
- [ ] Rights status is `cleared`.

---

# Contributor Audio Release Template

**Project:** Surveillance Survivor  
**Contributor:** `[legal name]`  
**Contribution:** `[description and asset IDs]`  
**Date:** `[YYYY-MM-DD]`

The Contributor represents that the Contribution is original except for material disclosed in an attached schedule, and that the Contributor has authority to grant the rights below.

Choose and have counsel finalize one structure:

- **Assignment:** Contributor assigns to `[project owner entity]` all right, title, and interest in the Contribution, including copyright and neighboring/performance rights, to the fullest extent permitted by law.
- **Exclusive license:** Contributor grants an exclusive, irrevocable, worldwide, transferable, sublicensable license for the full term of rights.
- **Non-exclusive license:** Use only when deliberately approved; record all resulting limitations.

The grant should expressly cover reproduction, editing, adaptation, synchronization, interactive implementation, distribution, public performance, advertising, trailers, streams, ports, updates, DLC, archival use, and sublicensing to publishers, platforms, distributors, contractors, and service providers.

For voice or performance contributions, separately specify whether consent includes editing, transformation, synthetic reproduction, voice cloning, model training, localization, marketing, and future reuse. Unselected rights are **not** presumed granted.

**Compensation:** `[amount/royalty/none and consideration]`  
**Required credit:** `[exact text or none]`  
**Disclosed third-party material:** `[none/list]`  
**Restrictions:** `[none/list]`

Contributor signature: ____________________  Date: __________  
Project representative: __________________  Date: __________

> Obtain qualified legal review before execution. Do not treat this repository template as a substitute for jurisdiction-specific counsel.

---

# Third-Party Audio Record Template

- Record ID: `SS-AUD-LIC-YYYY-NNNN`
- Asset IDs:
- Provider/licensor:
- Product/library/title:
- Creator/performer:
- Acquisition date:
- Order/license/account reference:
- License name and version/effective date:
- Source URL or vendor locator:
- Commercial use: allowed / restricted / prohibited / unknown
- Interactive game use: allowed / restricted / prohibited / unknown
- Advertising/trailer use: allowed / restricted / prohibited / unknown
- Modification/looping/layering: allowed / restricted / prohibited / unknown
- Distribution in executable build: allowed / restricted / prohibited / unknown
- Platform/publisher sublicensing: allowed / restricted / prohibited / unknown
- Territory:
- Term:
- Attribution text:
- Prohibited uses:
- Revocation/termination conditions:
- Content-ID or automated-claim risk:
- Evidence IDs:
- Reviewer/date:
- Decision: cleared / restricted / blocked

---

# Audio Credits Template

## Required legal attribution

Populate only from verified ledger entries.

| Asset or group | Creator/provider | Required text | Placement | Evidence ID |
| --- | --- | --- | --- | --- |
| `[asset IDs]` | `[name]` | `[exact attribution]` | `[in-game/store/docs]` | `[ID]` |

## Courtesy credits

- Audio direction: `[name]`
- Sound design: `[name/provider]`
- Music: `[name/provider]`
- Audio implementation: `[name]`
- Additional recording/performance: `[names]`

## AI disclosure record

Where required by platform policy, contract, or project policy:

`Selected audio assets were created with generative tools and were reviewed, edited, integrated, and rights-cleared by the Surveillance Survivor production team.`
