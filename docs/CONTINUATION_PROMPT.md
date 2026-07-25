# Continuation prompt — Surveillance Survivor

```yaml
version: 1.0.0
status: active
last_updated: 2026-07-25
tip_at_write: 6ba3273
```

Copy the block below into a new agent session (or run it in-place).

---

## Prompt (paste)

```text
You are continuing Surveillance Survivor at repo:
  /Users/appliedalchemylabs/Documents/Surveillance-Survivor

## Authority (read first)
1. AGENTS.md
2. docs/CONTINUATION_PLAN.md
3. docs/REPO_STATUS.md
4. docs/ROADMAP.md
5. docs/ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md

## Tip reality
- main tip includes P8 contract stack A (#53–#58) + Hallmark HUD tokens (#57)
- Receipt schema v7 with director / city-state / build / coordination / story
- 179 runtime PNGs; 10 city foundation packs
- App 0.1.0+1 pre-alpha
- Open issue #3: ART device QA + owner ship note (operator)
- #2 closed on GH; device evidence matrix may still lag

## Dual lanes
### Launch (operator — do not fake)
- Device ART QA → close #3
- DEVICE_TEST_LOG for current tip SHA
- Store privacy/support URLs + ASC fields
- ElevenLabs license → Audio Batch 1 (never system-sound placeholders)

### Systemic (agent — prefer emulator-first)
P8 contract A is done. Next is **P9 Big-Box Parking Expanse systems proof** (Wichita).

P9 minimum package (ROADMAP):
1. ≥3 infrastructure node families — already on Wichita graph
2. **6 deterministic environmental interactables** — NEXT if not landed
3. Coordination chain with ≥2 counterplay — done (lot_capture_cascade)
4. Landmark-scale set piece (authored encounter hook)
5. 12 upgrades + 4 evolutions — content exists
6. Suspicion Director budgets — done
7. Adaptive audio hooks (catalog-level, no fake stems)
8. Authoritative run story summary — done
9. Three strategically distinct clearing builds (prove via build tags/synergies + tests)
10. Physical-device performance receipt — operator

## Constraints (non-negotiable)
- SurveillanceCore owns combat truth; SpriteKit projection only
- Deterministic seed reproducibility
- No hidden damage/health scaling
- Receipts never invent narrative events
- No city 11
- Emulator ≠ device; do not close #2/#3 from sim green
- merge-when-green squash; no force-push to main
- Inventory-first REUSE for art; no mock residents/LPR baked terrain; no system-sound audio

## Required gates before PR
make version-check
make audio-check weapon-vfx-check animation-check
make director-check city-state-check build-engine-check coordination-check story-check
# plus any new make *-check added this session
make test
make emulator-test   # when presentation/app touched
# full: make validate

## Recommended first commit this session
If interactables not on main: implement P9 slice A —
  interactables.json (exactly 6 Wichita) + catalog + pure activate +
  player utility/proximity hook + receipt samples + make interactables-check +
  docs/P9_BIG_BOX_PROOF.md progress checklist + tests.

Then: commit branch, open PR, merge when green, refresh boards to tip.

## Stop conditions
- Do not regenerate audio without owner license
- Do not claim device acceptance from emulator
- Do not expand to ten-city systemic projection before P9 proof package is mostly green
```

---

## Execution notes

| Field | Value |
| --- | --- |
| Written for tip | `6ba3273` |
| First executable step | P9 environmental interactables (6 Wichita) |
| Operator blockers | #3, device log, store, ElevenLabs |
