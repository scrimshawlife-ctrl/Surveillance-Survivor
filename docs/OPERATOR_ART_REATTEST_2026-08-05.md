# Operator ART re-attest brief — 2026-08-05

**Why:** Partner secondhand report that the game “looks fucked up” after #156/#159/#160.  
Prior ART approval (`ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES`, tip lineage ~`0a2a627` / `d87be47`) is **stale** vs current presentation tip.

**Physical iPhone only for ship-facing sign-off.** Simulator is weaker.

## Tip to install

```bash
git fetch origin
git checkout main
git pull --ff-only origin main
git rev-parse --short HEAD   # record this as freeze tip for the session
```

Expect tip at or after **`fcde5fe`** (G-01/G-02/G-03 presentation fixes). Re-read short SHA after pull.

```bash
DEVELOPMENT_TEAM=X9M969D8M3 make device-smoke
# optional mechanical:
# DEVELOPMENT_TEAM=X9M969D8M3 make device-test
```

## What changed since last ART pass

| Change | Intent | What to watch |
| --- | --- | --- |
| #156 UrbanDress + camera 1.38 + 1.5× arenas | City streets / zoom | Scale, empty perimeter, street paint |
| #159 Prompted sprites + full terrain carpet | New art + floor | Contrast, busy floor |
| #160 Walks + event clips + FX layer | Motion / effects | Flicker, FX size, redaction field |
| **G-01** terrain parent fix | Sidewalks not buried | Streets/curbs visible under tiles |
| **G-02** carpet α 0.88→0.48 | Calmer floor | Still too busy? too flat? |
| **G-03** player feet normalize | Less hop on turn | Wardrobe/outfit may still shimmer |

## Dual checklist (fill pass / fail / n/a)

### Graphics

```text
tip_sha_short:
device / iOS:
reviewer / date:

sidewalks readable under terrain carpet (G-01): 
floor not wallpaper over entities (G-02): 
player feet stable when turning (G-03 feet): 
player outfit identity OK across walk frames (wardrobe residual): 
guards/boss walk readable (Batch 6): 
LPR scan loop readable: 
transient FX (telegraph/impact/blind-spot) not sealing combat: 
satellite zoom 1.38 combat OK: 
cities sampled (min 3): 
```

### Playability

```text
stick appears at press / usable in landscape: 
can survive first ~60s without softlock: 
scan cones / projectiles / threats readable: 
extract / Blind Spot path understandable if reached: 
pause / resume OK: 
unfair death / stuck in geometry notes:
```

### Ship call (do not invent)

```text
ART re-attest for THIS tip: yes / no / yes_with_notes
notes:
```

If **yes** (with or without notes): agent may update `art_qa` package **only** with operator language and tip SHA — never promote launch READY without residual playbook.

## Evidence to file

- This filled brief (paste into `docs/DEVICE_TEST_LOG.md` or new dated note)  
- Optional screenshots under operator-controlled storage  
- Live extract only if residual freeze path needs it  

## Related

- Field audit: [`CONTINUATION_REPORT_2026-08-05_graphics_playability_field_audit.md`](CONTINUATION_REPORT_2026-08-05_graphics_playability_field_audit.md)  
- Residual: [`launch/TESTFLIGHT_RC_RESIDUAL.md`](launch/TESTFLIGHT_RC_RESIDUAL.md)  
- Classic checklist: [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) (older tip — do not treat as current)  
