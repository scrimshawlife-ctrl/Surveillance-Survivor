# Versioning policy

**Policy version:** 1.0.0  
**Effective:** 2026-07-24  
**Authority:** this file defines product, build, schema, content, save-data, receipt, and documentation versioning for Surveillance Survivor.

## 1. Version domains

Versions are intentionally separated. A change in one domain does not automatically change every other domain.

| Domain | Format | Initial authority | Purpose |
| --- | --- | --- | --- |
| App release | SemVer `MAJOR.MINOR.PATCH` | `project.yml` + `versions.json` | User-visible release train |
| Apple build | Positive integer | `project.yml` + `versions.json` | App Store Connect build identity |
| Simulation protocol | Positive integer | `versions.json` | Deterministic state/event compatibility |
| Save data | Positive integer | `versions.json` | Persistence migration boundary |
| Run receipt | Positive integer | `versions.json` | Replay and evidence compatibility |
| Content catalog | Positive integer | `versions.json` | Bundled JSON catalog compatibility |
| Individual JSON schema | SemVer | Schema `$id`/metadata | Contract evolution per file family |
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
- `run_receipt`: receipt fields are removed, renamed, or semantically redefined.
- `content_catalog`: bundled content definitions require a new loader or incompatible interpretation.

Compatible additive fields do not require an integer bump when readers ignore unknown fields and defaults are deterministic.

## 5. Schema rules

Every bundled JSON authority must carry or validate against:

```json
{
  "schema_id": "surveillance-survivor/<family>",
  "schema_version": "1.0.0",
  "content_version": 1
}
```

Schema SemVer:

- **MAJOR**: incompatible field or meaning change.
- **MINOR**: backward-compatible field, enum, or capability addition.
- **PATCH**: clarification or validation correction that does not alter valid runtime meaning.

Migrations must be explicit, deterministic, fixture-tested, and idempotent.

## 6. Documentation rules

Canonical design and engineering documents use a metadata block directly below the title:

```yaml
version: 1.0.0
status: approved
last_updated: 2026-07-24
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
3. Runtime constants generated or read from the registry.
4. JSON schema metadata and migration fixtures.
5. Canonical documentation metadata.
6. README and release notes, which summarize but do not override authorities.

CI must fail when duplicated version values disagree.

## 8. Current baseline

| Domain | Version |
| --- | --- |
| App release | `0.1.0` |
| Apple build | `1` |
| Simulation protocol | `1` |
| Save data | `1` |
| Run receipt | `1` |
| Content catalog | `1` |
| Versioning policy | `1.0.0` |
| Roguelike assimilation program | `1.0.0` |

This baseline describes pre-alpha authority; it does not assert App Store readiness.
