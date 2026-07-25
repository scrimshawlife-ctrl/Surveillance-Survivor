# P8 — Run Story Compiler contract (slice A)

```yaml
version: 1.0.0
status: in_progress
last_updated: 2026-07-25
authority_scope: Receipt-grounded story facts only
```

**Roadmap:** P8 systemic runtime architecture  
**Design authority:** [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) E6  
**Content:** `Sources/SurveillanceCore/Resources/Content/story_fact_rules.json`  
**Runtime:** `RunStoryCatalog` · `RunStoryCompiler` · `RunReceipt.storyFacts` / `storySummary`  
**Gate:** `make story-check`

---

## Objective

Compress authoritative run evidence into shareable story facts.  
**The compiler may describe only events present in the run receipt.**

## Slice A scope

| Piece | Role |
| --- | --- |
| Fact rules | Priority-ordered templates with evidence predicates |
| Placeholders | `{district}`, `{count}`, `{peak}`, `{synergyList}`, `{seed}` only |
| Compiler | Pure function over `StoryEvidenceSnapshot` |
| Receipt | schema v7 `storyFacts` + `storySummary` |
| HUD | Run summary overlay shows summary when non-empty |

## Acceptance

- [x] `forbidInventedNarrative: true`  
- [x] No facts without evidence  
- [x] Deterministic compilation  
- [x] Receipt auto-compiles on construct  
- [x] CI `story-check`  
- [ ] Shareable export format polish  
- [ ] Narrative callbacks mid-run (later)

## Non-goals

- Invented metrics or flavor text without evidence  
- Closing #3 / device acceptance  
