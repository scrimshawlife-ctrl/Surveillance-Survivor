# Post-merge audit program

**Design:** [`docs/superpowers/specs/2026-08-05-post-merge-audit-program-design.md`](../superpowers/specs/2026-08-05-post-merge-audit-program-design.md)  
**Plan:** [`docs/superpowers/plans/2026-08-05-post-merge-audit-program.md`](../superpowers/plans/2026-08-05-post-merge-audit-program.md)  
**Order:** C hygiene → D architecture → B presentation/art → A ship residual  

## Shared rules

1. Tip-freeze before each audit; dirty tree explained or rejected as ship evidence.
2. Machine gate exit 0 means honest, not READY.
3. Never invent READY, store clearance, or audio rights clearance.
4. Core owns combat truth; presentation projects only.

## Shared machine pack

```bash
git fetch origin --prune
git rev-parse HEAD && git rev-parse --short HEAD
git status --short
make version-check repo-status-check launch-gate-check art-qa-check assets-check
```

## Reports

| Order | Audit | Report |
| ---: | --- | --- |
| 1 | C Hygiene | *(pending)* |
| 2 | D Architecture | *(pending)* |
| 3 | B Presentation/art | *(pending)* |
| 4 | A Ship residual | *(pending)* |

## Residual authority

- [`docs/launch/TESTFLIGHT_RC_RESIDUAL.md`](../launch/TESTFLIGHT_RC_RESIDUAL.md)
- [`docs/launch/launch_gates.json`](../launch/launch_gates.json)
- Board: [`docs/REPO_STATUS.md`](../REPO_STATUS.md)
