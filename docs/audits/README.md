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
| 1 | C Hygiene | [`docs/CONTINUATION_REPORT_2026-08-05_hygiene_audit.md`](../CONTINUATION_REPORT_2026-08-05_hygiene_audit.md) |
| 2 | D Architecture | [`docs/CONTINUATION_REPORT_2026-08-05_architecture_isolation_audit.md`](../CONTINUATION_REPORT_2026-08-05_architecture_isolation_audit.md) |
| 3 | B Presentation/art | [`docs/CONTINUATION_REPORT_2026-08-05_presentation_art_audit.md`](../CONTINUATION_REPORT_2026-08-05_presentation_art_audit.md) |
| 4 | A Ship residual | [`docs/CONTINUATION_REPORT_2026-08-05_ship_residual_audit.md`](../CONTINUATION_REPORT_2026-08-05_ship_residual_audit.md) |

## Residual authority

- [`docs/launch/TESTFLIGHT_RC_RESIDUAL.md`](../launch/TESTFLIGHT_RC_RESIDUAL.md)
- [`docs/launch/launch_gates.json`](../launch/launch_gates.json)
- Board: [`docs/REPO_STATUS.md`](../REPO_STATUS.md)
