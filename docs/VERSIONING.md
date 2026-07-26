# Versioning policy

```yaml
version: 1.1.0
status: approved
last_updated: 2026-07-26
supersedes: 1.0.0
superseded_by: null
authority_scope: product, build, schema, content, save-data, receipt, and documentation versioning
```

**Effective:** 2026-07-26  
**Authority:** this file defines product, build, schema, content, save-data, receipt, and documentation versioning for Surveillance Survivor.

## 1. Version domains

Versions are intentionally separated. A change in one domain does not automatically change every other domain.

| Domain | Format | Initial authority | Purpose |
| --- | --- | --- | --- |
| App release | SemVer `MAJOR.MINOR.PATCH` | `project.yml` + `versions.json` | User-visible release train |
| Apple build | Positive integer | `project.yml` + `versions.json` | App Store Connect build identity |
| Simulation protocol | Positive integer | `versions.json` | Deterministic state/event compatibility |
| Save data | Positive integer | `versions.json` | Persistence migration boundary |
| Run receipt compatibility | Positive integer | `versions.json` → `compatibility.run_receipt.compatibility_version` | Breaking receipt reader migration boundary |
| Run receipt schema | Positive integer | `versions.json` → `compatibility.run_receipt.schema_version` + `RunReceipt.schemaVersion` | Additive receipt payload growth |
| Content catalog generation | Positive integer | `versions.json` → `compatibility.content_catalog` | Loader-generation compatibility |
| Bundled content family schema | Positive integer | `versions.json` → `content_schemas.*` + Swift `currentSchemaVersion` | Per-family JSON contract |
| Persistence envelopes | Positive integer | `versions.json` → `persistence.*` | Campaign / mastery / receipt store envelopes |
| Design/engineering docs | SemVer | Document metadata header | Authority and supersession tracking |

## 2. App SemVer rules

Before `1.0.0`:

- **MINOR**: a coherent playable milestone or material system expansion.
- **PATCH**: fixes, tuning, assets, documentation, and compatible content additions.
- **MAJOR** remains `0` until the first production release contract is approved.

At and after `1.0.0`:

- **MAJOR**: incompatible player-facing, save-data, or platform contract change.
- **MINOR**: backward-compatible feature addition.
- **PATCH**: backward-compatible correction or tuning release.

Pre-release labels may be used in Git tags and release notes (`0.2.0-alpha.1`), but Xcode `MARKETING_VERSION` remains numeric (`0.2.0`).

## 3. Apple build rules

`CURRENT_PROJECT_VERSION` is a monotonically increasing positive integer.

- Increment for every archive uploaded to App Store Connect or TestFlight.
- Never reuse a build number for the same bundle identifier.
- Local simulator builds may share the checked-in build number; release automation must increment it before archive publication.
- Git tag format: `v<app-version>+<build>`, for example `v0.1.0+1`.

## 4. Compatibility integers

Increment the relevant integer when compatibility is broken:

- `simulation_protocol`: event ordering, RNG interpretation, fixed-step semantics, or canonical state meaning changes.
- `save_data`: persisted structures cannot be read without migration.
- `run_receipt.compatibility_version`: receipt fields are removed, renamed, or semantically redefined for readers.
- `content_catalog`: bundled content definitions require a new loader generation or incompatible interpretation.

Compatible additive fields do not require a compatibility integer bump when readers ignore unknown fields and defaults are deterministic. Additive receipt growth increments `run_receipt.schema_version` (and `RunReceipt.schemaVersion`) without bumping `compatibility_version`.

## 5. Bundled content schema rules (runtime)

**Canonical runtime convention** for SurveillanceCore JSON authorities is an integer `schemaVersion` validated by each catalog’s `currentSchemaVersion`:

```json
{
  "schemaVersion": 2,
  "districts": []
}
```

Optional identity metadata may appear alongside that integer (for example `schemaId`) but does not replace it.

Rules:

1. Each content family listed under `versions.json` → `content_schemas` must match the Swift `currentSchemaVersion` constant.
2. Loaders reject unsupported integers; migrations must be explicit, deterministic, fixture-tested, and idempotent.
3. Do not invent a parallel SemVer `schema_version` / `content_version` triple for runtime catalogs unless the loader and registry are migrated together in one change.
4. Future SemVer document-style metadata for authored tools remains allowed in non-runtime manifests (audio/weapon/animation queues) and must not be confused with runtime `schemaVersion`.

## 6. Documentation rules

Canonical design and engineering documents use a metadata block directly below the title:

```yaml
version: 1.0.0
status: approved
last_updated: 2026-07-26
supersedes: null
superseded_by: null
authority_scope: <bounded scope>
```

Rules:

1. Patch version for wording, examples, links, or clarification without changing obligations.
2. Minor version for additive requirements or new approved sections.
3. Major version when authority, required behavior, or acceptance gates change incompatibly.
4. A superseded document remains available but must identify its successor.
5. Filenames remain stable unless the document is intentionally archived; version truth lives in metadata and Git history.
6. Notion titles may use compact `v1.0`; the page body must carry full SemVer.

## 7. Source-of-truth order

1. `versions.json` — machine-readable version registry.
2. `project.yml` — Xcode marketing/build values; must match `versions.json`.
3. Runtime constants (`RunReceipt.schemaVersion`, catalog `currentSchemaVersion`, persistence schema constants).
4. JSON `schemaVersion` integers and migration fixtures.
5. Canonical documentation metadata.
6. README and release notes, which summarize but do not override authorities.

CI must fail when duplicated version values disagree. The Linux `core-tests` job runs `make version-check` before other validation.

## 8. Current baseline

| Domain | Version |
| --- | --- |
| App release | `0.1.0` |
| Apple build | `1` |
| Simulation protocol | `1` |
| Save data | `1` |
| Run-receipt compatibility | `1` |
| Run-receipt schema / envelope | `11` |
| Campaign persistence | `1` |
| Mastery persistence | `1` |
| Content catalog generation | `1` |
| Districts / waves family schema | `2` |
| Most other content families | `1` |
| Versioning policy | `1.1.0` |
| Roguelike assimilation program | `1.0.0` |

## 9. Receipt migration contract

`RunReceiptStore` persists a versioned `DeviceRunReceiptRecord` envelope.

- Unsupported future/past envelopes are preserved byte-intact.
- Legacy bare `DeviceRunReceipt` payloads decode as `compatible-legacy-bare-receipt`.
- Compatible older envelope versions that decode without a transform report `compatible-decode-from-<n>` (not `migrated-from-<n>`).
- Before any incompatible receipt change (schema 12+ or a compatibility bump), add an explicit `RunReceiptMigration.migrate(from:receipt:)` step with fixture archives for each supported historical boundary.

This baseline describes pre-alpha authority; it does not assert App Store readiness.
