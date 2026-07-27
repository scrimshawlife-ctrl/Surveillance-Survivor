# Surveillance Survivor — Debug Hardening Receipt

```yaml
campaign: SURVEILLANCE_SURVIVOR_DEBUG_HARDENING_001
baseline_sha: 03708b0b1c8fca1e0520dcd5af23e7dfb39e8fc2
validated_sha: 3fdae0db12dd
device_suite_sha: bbd4b9f
published_sha: 9c21de7a4c0812215726e3aba758f7dfbb073838
integrated_pr_head: b04a925c7516da07491353dec9a70d3c3f5f5e2a
branch: codex/debug-hardening-validation
pull_request: 133
status: PARTIAL
execution_surface: local macOS/Xcode simulator checkout + GitHub-hosted Linux/macOS runners
physical_device_evidence: AUTOMATED_DEVICE_SUITE_PASS_ART_SIGNOFF_PENDING
```

## Objective

Close false-green CI paths and establish machine-enforced continuity before deeper SpriteKit presentation refactoring.

## Implemented

- Expanded pull-request workflow coverage to `Game/**`, `App/**`, `Resources/**`, `docs/**`, and all workflow files.
- Added Linux and Apple toolchain receipts containing the exact commit and available compiler/runtime versions.
- Added asset, sprite-chroma, animation, and weapon/VFX validators to the macOS simulator contract.
- Preserved `.xcresult`, unit-test logs, smoke logs, asset-validation logs, simulator selection, and toolchain output as workflow artifacts.
- Added a branch-aware repository-status baseline guard.
- Added `make repo-status-check` and `make repo-status-refresh`.
- Added parser-level unit coverage for canonical, full-length, malformed, missing, and too-short status SHAs.
- Added the status guard to `make validate` and to GitHub Actions.
- Corrected the PR checkout to `fetch-depth: 0` so ancestry validation runs against complete history rather than a depth-1 synthetic merge checkout.
- Enforced finite, positive, bounded simulation fixed steps, with deterministic unit coverage.
- Added SpriteKit regression coverage for upright camera bodies, LOS-cone heading, disabled-cone recovery, and typed node-pool reuse.
- Replaced texture-dimension full-plate inference with `VisualAssetMap` rendering semantics.
- Applied the selected player role's display metrics when animation frames swap.
- Strengthened the animation validator to enforce all presentation rules, runtime/scope consistency, normalized anchors, priorities, and actual player multi-frame atlas availability.

## Architectural decisions

1. Feature branches may reference an ancestor main baseline; main must exactly match the documented SHA.
2. Status refresh changes only the SHA field and explicitly requires human review of evidence and gate language.
3. Historical device evidence remains SHA-specific and does not prove later rendering revisions.
4. Repository history is part of the status-guard input contract; CI must not weaken the guard to accommodate shallow clones.
5. No launch, ART, device, TestFlight, or production gate was changed.

## GitHub validation evidence

Baseline validation completed against branch SHA `589bda3bd6f52fdfcd061b067e984aaca12ba168`.

- Automation Test Suite run **15**: PASS.
- CI run **824**: PASS.
- Deterministic core and contracts: PASS.
- Repository-status parser tests: PASS.
- Automation-focused deterministic suite: PASS.
- Repository baseline ancestry guard: PASS.
- Asset and presentation validators: PASS.
- XcodeGen project generation: PASS.
- Application unit tests on iPhone Simulator: PASS.
- Simulator launch smoke: PASS.
- Toolchain, logs, `.xcresult`, and smoke evidence uploaded by GitHub Actions.

Fresh validation completed against published PR #133 SHA `9c21de7a4c0812215726e3aba758f7dfbb073838`.

- Automation Test Suite run `30281070444`: core contract and iPhone simulator contract PASS.
- CI run `30281074535`: core tests and simulator contract PASS.

## Not completed in this execution slice

- Owner ART visual checklist and operator acceptance remain pending. The automated device suite does not establish readability, thermal behavior, haptics, audio-route behavior, or ART ship approval.

## Validation state

| Check | State | Evidence |
| --- | --- | --- |
| Repository mutations | PASS | Integrated local branch includes PR #133 head plus `f045552`, `7c9fcfe`, `3301e63`, `3fdae0d` |
| Published CI | PASS | PR #133 at `9c21de7`; Automation Test Suite `30281070444` and CI `30281074535` green |
| Animation gate | PASS | 27 clips; player multi-frame atlas claims verified |
| `make validate` | PASS | 220 Swift tests; 329 simulator tests; 4 simulator UI tests; gates remain honest |
| `make build` | PASS | iPhone Simulator build at `3301e63` |
| Simulator smoke | PASS | `CACB3927-A76E-43A5-9ACA-C389EB38C0C3`; `.simulator-smoke/receipt.txt` |
| Automated device suite | PASS | Physical iPhone `00008150-000A6C120CB8401C`; `bbd4b9f`; Xcode 26.5; signed install, dual-launch liveness, and 4 UI tests passed |
| Owner ART device acceptance | PENDING | Automated suite explicitly does not replace operator visual/thermal/haptics/audio-route sign-off |

## Remaining risks

- Device evidence is SHA-specific; automated UI/smoke results do not replace operator visual acceptance.
- Launch stays blocked by existing device acceptance, art evidence, store metadata, audio product, and TestFlight evidence gates.
- The draft PR must remain unmerged until owner-gated evidence is supplied.

## Publication state

- Changes committed: yes, on the local validation branch.
- Pushed: yes; `9c21de7` fast-forwarded PR #133's source branch.
- Pull request: draft #133 contains the integrated local commits and fresh green CI.
- Merge: not authorized and not performed.
