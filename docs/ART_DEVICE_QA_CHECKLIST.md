# ART device QA checklist (operator)

**Authority:** physical iPhone only. Simulator / `make validate` green **does not** complete this list.  
**Tip at write:** device evidence tip **`44a204f`** (dynamic stick + Tulsa extract) — re-record if you install a newer build.  
**Related:** [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) · [`ART_QA_PERCEPTION_AUDIT.md`](ART_QA_PERCEPTION_AUDIT.md) · [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) · [`device_evidence/`](device_evidence/)

## Before play

```text
date / local time: 2026-08-01 (operator fill local time)
reviewer:
device model / iOS: iPhone 17 Pro / 26.3.1
commit SHA: 44a204f   (must match binary — dynamic stick tip; re-pin if newer)
build: Debug signed DEVELOPMENT_TEAM=X9M969D8M3
seed (if noted):
mechanical suite: PASS on 7c400e7
live extracts filed: Louisville (7c400e7) + Tulsa (44a204f) — does not complete this ART list
movement: stick appears at press point (full field)
```

## Combat hierarchy (required for art ship)

```text
player silhouette primary over guards / LPR clutter: pass / fail
projectiles readable above bodies at combat density: pass / fail
scan cones do not white-out at high LPR density: pass / fail
boss readable vs processing tint (not same purple): pass / fail
Blind Spot distinct from landmark zone rings: pass / fail
Blind Spot off-screen cyan compass readable, clears on-screen: pass / fail / n/a
boss integrity bar reads as progress (not bare number): pass / fail / n/a
reduced-flash flood / cones calmer: pass / fail / n/a
```

## City / floor (sample ≥3 cities)

```text
city A ________ identity without labels: pass / fail
city B ________ identity without labels: pass / fail
city C ________ identity without labels: pass / fail
floors not wallpaper over entities: pass / fail
```

## Motion / density stress

```text
player walk multi-frame readable (not mushy): pass / fail
4-weapon loadout exercised: pass / fail / n/a
max projectile clutter still readable: pass / fail
frame p50 / p95 / max (ms):
p95 ≤ 16.67 ms: pass / fail / not measured
```

## Accessibility

```text
reduced motion usable: pass / fail
reduced flash usable: pass / fail
status (processing/disrupt) still understandable: pass / fail
```

## Ship call (owner)

```text
ART ship approval for this tip: yes / no
notes:
```

Paste results into [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) or GitHub #3.  
Until a **yes** with tip-matched SHA exists, machine gate remains **`ART_EVIDENCE_INSUFFICIENT`**.
