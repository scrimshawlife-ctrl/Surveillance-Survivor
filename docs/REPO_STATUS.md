# Repository status audit

**As of:** 2026-07-25  
**`main` tip:** `60603b3` — inventory-first optional multi-frame probe for guards (#86)  
**App version:** `0.1.0` build `1` (pre-alpha) — see [`VERSIONING.md`](VERSIONING.md) · [`versions.json`](../versions.json)

**Primary sequencing:** [`ROADMAP.md`](ROADMAP.md)  
**Operator packet:** [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md)  
**Continuation paste:** [`CONTINUATION_PROMPT.md`](CONTINUATION_PROMPT.md)  
**Device / ship:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**Art QA:** [`ART_QA_PERCEPTION_AUDIT.md`](ART_QA_PERCEPTION_AUDIT.md) · [`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json) · `make art-qa-check`  
**Store:** [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | Update after open PRs |

## Recently merged (high signal)

| PR | Title |
| ---: | --- |
| [#86](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/86) | inventory-first optional multi-frame probe for guards |
| [#85](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/85) | status shape ring + cool flood vs FOIA |
| [#84](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/84) | perception Art QA package |
| [#83](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/83) | launch-prep boards |
| [#82](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/82) | PresentationQualityTier density |
| [#81](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/81) | combat readability projectors |

## Phase snapshot

| Phase | Status |
| --- | --- |
| P0–P1 | Done |
| P2 device | **Operator** — use [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) |
| P3 ART | Repo package + remediations; **device open**; `ART_EVIDENCE_INSUFFICIENT` |
| P4 audio | Catalog only |
| P5 store | OWNER fields open |
| P6 TF | Blocked on P2–P5 |
| P7–P11 | Presentation + systems on main |

## Suggested next

1. **Operator:** [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md) step 2 on tip `60603b3`  
2. **Owner:** store URLs + screenshots + ElevenLabs  
3. **Agent:** exhausted for launch without device/art/audio input — board hygiene only  

## Art ship gate

| Field | Value |
| --- | --- |
| `ship_gate` | **`ART_EVIDENCE_INSUFFICIENT`** |
| Machine check | `make art-qa-check` |
| Audited code tip | `6a06fb1` (+ remediations through #86 on main) |
