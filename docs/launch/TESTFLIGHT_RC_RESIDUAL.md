# TestFlight RC residual closeout

**Purpose:** Last human/agent steps from honest `LAUNCH_BLOCKED` to **RC cut allowed**.  
**Design:** [`docs/superpowers/specs/2026-08-02-testflight-rc-residual-design.md`](../superpowers/specs/2026-08-02-testflight-rc-residual-design.md)  
**Machine truth:** [`launch_gates.json`](launch_gates.json) · [`AGENT_LAUNCH_PLAYBOOK.md`](AGENT_LAUNCH_PLAYBOOK.md)  
**Does not mean:** App Store Connect upload, TF group assignment, or public submit.

## Success

When `device_acceptance`, `art_ship`, `store_metadata`, and `audio_product` are all `READY` at the frozen tip, agents may set `testflight_rc` to `READY`. Overall may become `LAUNCH_READY`. That only means humans **may cut** an RC — not that one was uploaded.

## 0. Freeze ship SHA (required first)

Record a **Ship freeze** block in [`DEVICE_TEST_LOG.md`](../DEVICE_TEST_LOG.md) using the template there:

- full SHA + short SHA
- UTC time
- app version / build
- intent label (e.g. `tf-rc-0.1.0-b1`)
- `git status --short` (prefer empty)

Rules:

- Every READY gate `tip_sha_short` must equal freeze short SHA and current `git rev-parse --short HEAD`.
- Any later commit breaks freeze — re-freeze before promoting again.
- Agents never invent a freeze block.

## Residual order

```text
Freeze
  ├─ Owner: store residual → store_metadata READY
  ├─ Owner: audio rights + listening → audio_product READY
  └─ Operator: device_acceptance READY → art_ship READY
Shared: testflight_rc READY only when all four priors READY
Human: cut RC (outside this doc)
```

Store and audio may run in parallel. `art_ship` waits on `device_acceptance`.

## A. Store residual (`store_metadata`)

Already done: live privacy/support URLs, SKU `SS-IOS-001`, Action subcategory, sim screenshot pack.

Still required:

1. Confirm copyright string in [`APP_STORE_METADATA.md`](../APP_STORE_METADATA.md) / [`STORE_OWNER_INTAKE.md`](../STORE_OWNER_INTAKE.md).
2. Accept sim candidates in [`store_screenshots/`](../store_screenshots/) **or** recapture physical/release stills at freeze tip and update manifest.

Does **not** block RC-allowed: age rating in Connect, ASC privacy questionnaire (public submit items).

Then agent may promote `store_metadata` READY with evidence paths to those docs + screenshot manifest.

## B. Audio residual (`audio_product`)

1. File private evidence per [`audio/rights/OWNER_EVIDENCE_PACKET.md`](../audio/rights/OWNER_EVIDENCE_PACKET.md) until `make audio-rights-check` **PASS**.
2. On freeze tip, complete **Listening (freeze tip)** in `DEVICE_TEST_LOG.md` (speaker, headphones/second route, silent mode, interruption, route change, dense mix).

Scaffold `pending_evidence` is **not** clearance. Agents never invent digests or `cleared`.

## C. Device tip-match (`device_acceptance`)

On freeze tip:

| Binary/presentation since last full suite + live extract | Required |
| --- | --- |
| Unchanged | Attest in log; run `device-smoke` + physical `launch-smoke`; cite prior extract |
| Changed | Full suite + one live extract on freeze tip |
| Docs-only | Smoke + physical launch-smoke; cite prior extract with freeze attestation |

Not READY from smoke or force-extract alone.

## D. ART tip-match (`art_ship`)

Requires `device_acceptance` READY.

- No visual/binary change since ART approval: re-attest ART still holds at freeze tip.
- Visual/binary change: re-run ART checklist eyes; update art_qa + log.

Nonblocking notes do not block READY if approved-with-notes and re-attested.

## E. RC allowed (`testflight_rc`)

All four priors READY at freeze tip. Reason: `RC cut allowed at <shortsha>; not uploaded`.

## Demotion

If HEAD short SHA moves after READY: demote all READY gates to `EVIDENCE_INSUFFICIENT`, reason tip moved / re-freeze.

## Validate

```bash
make launch-gate-check release-docs-check repo-status-check
make audio-rights-check   # PASS only after owner clearance
```
