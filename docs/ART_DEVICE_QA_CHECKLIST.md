# ART device QA checklist (operator)

**Authority:** physical iPhone only. Simulator / `make validate` green **does not** complete this list.  
**Tip at write:** use **current `main` SHA** (package written for `6a06fb1` — re-record if newer).  
**Related:** [`ART_QA_PERCEPTION_AUDIT.md`](ART_QA_PERCEPTION_AUDIT.md) · [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) · [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md)

## Before play

```text
date / local time:
reviewer:
device model / iOS:
commit SHA: __________   (must match binary)
build: Debug signed
seed (if noted):
```

## Combat hierarchy (required for art ship)

```text
player silhouette primary over guards / LPR clutter: pass / fail
projectiles readable above bodies at combat density: pass / fail
scan cones do not white-out at high LPR density: pass / fail
boss readable vs processing tint (not same purple): pass / fail
Blind Spot distinct from landmark zone rings: pass / fail
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
