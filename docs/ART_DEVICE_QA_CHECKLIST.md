# ART device QA checklist (operator)

**Authority:** physical iPhone only. Simulator / `make validate` green **does not** complete this list.  
**Tip span:** mechanical `7c400e7` · live extracts · dynamic stick `44a204f` · idle Batch 2B `d87be47`  
**Related:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) · [`device_evidence/`](device_evidence/) · [`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json)

## Before play

```text
date / local time: 2026-08-01
reviewer: operator
device model / iOS: iPhone 17 Pro / 26.3.1
commit SHA: 44a204f (play + extracts) … d87be47 (idle 2B art)
build: Debug signed DEVELOPMENT_TEAM=X9M969D8M3
mechanical suite: PASS on 7c400e7
live extracts filed: Louisville (7c400e7) + Tulsa (44a204f)
movement: stick appears at press point (full field)
```

## Combat hierarchy (required for art ship)

```text
player silhouette primary over guards / LPR clutter: pass
projectiles readable above bodies at combat density: pass
scan cones do not white-out at high LPR density: pass
boss readable vs processing tint (not same purple): pass
Blind Spot distinct from landmark zone rings: pass
Blind Spot off-screen cyan compass readable, clears on-screen: pass
boss integrity bar reads as progress (not bare number): pass
reduced-flash flood / cones calmer: pass
```

## City / floor (sample ≥3 cities)

```text
city A wichita identity without labels: pass
city B louisville identity without labels: pass
city C tulsa identity without labels: pass
floors not wallpaper over entities: pass
```

## Motion / density stress

```text
player walk multi-frame readable (not mushy): pass
4-weapon loadout exercised: n/a (not formal matrix this session)
max projectile clutter still readable: pass (operator bar for now)
frame p50 / p95 / max (ms): ~16.67 / ~16.67 / ~200 (receipt; max historically draft-inflated)
p95 ≤ 16.67 ms: pass
```

## Accessibility

```text
reduced motion usable: pass
reduced flash usable: pass
status (processing/disrupt) still understandable: pass
```

## Ship call (owner/operator)

```text
ART ship approval for this tip: yes (for now)
notes: Operator approval 2026-08-01 — ship bar accepted with nonblocking notes:
  walk cycles still under manifest target_frames; formal 4-weapon density matrix optional;
  animation video-first expansion deferred (ZDR). Machine gate:
  ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES.
```

Evidence paths cited in [`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json).
