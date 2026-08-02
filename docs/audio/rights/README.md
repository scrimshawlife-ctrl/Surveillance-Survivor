# Surveillance Survivor — Audio Rights Package

Status: **release-gating documentation** · ledger **scaffold pending evidence** (not cleared)  
Owner: repository operator / producer  
Scope: every music, ambience, sound-effect, voice, performance, field recording, stem, master, and derived delivery shipped with the game or used in marketing.

**Owner fill path:** [`OWNER_EVIDENCE_PACKET.md`](OWNER_EVIDENCE_PACKET.md) — replace five private slots, then clear assets.

> This package is an operational chain-of-title system, not legal advice. Final commercial release should receive qualified counsel review where material risk remains.

## Release rule

No audio asset may ship unless its entry in `docs/AUDIO_ASSET_MANIFEST.json` can be tied to evidence proving the project may reproduce, modify, synchronize, distribute, publicly perform, market, and commercially exploit that asset in all intended territories and platforms.

An asset is release-ready only when all of the following are true:

1. The asset has a stable `asset_id`, source, license statement, and cryptographic hash.
2. The generation/acquisition date and account or contributor are known.
3. The applicable subscription, license, release, or assignment is archived outside the public repository.
4. Any attribution, usage restriction, term, territory, media, revocation, model, voice, performer, or dataset condition is recorded.
5. The evidence status is `verified` and the rights status is `cleared`.
6. The asset has no unresolved third-party IP, impersonation, trademark, quotation, sample, or recognizable-performance concern.

## Package contents

| File | Purpose |
| --- | --- |
| `AUDIO_RIGHTS_POLICY.md` | Rights taxonomy, approval states, prohibited assumptions, and release gate |
| `AUDIO_RIGHTS_LEDGER.json` | Machine-readable chain-of-title ledger |
| `audio_rights.schema.json` | Ledger schema |
| `EVIDENCE_CHECKLIST.md` | Evidence collection procedure |
| `CONTRIBUTOR_AUDIO_RELEASE_TEMPLATE.md` | Assignment/license and consent template for human contributors |
| `THIRD_PARTY_AUDIO_RECORD_TEMPLATE.md` | Record for libraries, vendors, marketplaces, contractors, and licensors |
| `AUDIO_CREDITS_TEMPLATE.md` | Credits and attribution source of truth |
| `scripts/validate_audio_rights.py` | Deterministic release-gate validator |

## Evidence storage

Do **not** commit invoices, account identifiers, contracts, signatures, government IDs, private email, or subscription screenshots to this public repository.

Store evidence in a controlled archive and commit only:

- an opaque evidence ID;
- document type;
- issuer/provider;
- effective and capture dates;
- SHA-256 digest;
- internal storage locator or vault reference;
- reviewer and verification status;
- non-sensitive notes.

Recommended evidence ID format:

`SS-AUD-EV-YYYY-NNNN`

## ElevenLabs-specific gate

The current manifest identifies ElevenLabs Sound Effects and Music as the generator. Commercial clearance must be verified per generation batch, not inferred from the filename or provider name alone. At minimum, retain proof of:

- the account and plan active on the generation date;
- whether the feature was generally available or a Beta Service;
- the exact product used (Sound Effects, Music, Voice, or another surface);
- applicable terms/license version;
- prompt and generation/export identifiers where available;
- confirmation that the operator held all necessary input rights;
- any product-specific license required for game distribution, advertising, film/TV, or enterprise use.

Official ElevenLabs guidance states that paid-plan outputs can generally receive commercial rights, while free-plan and Beta-Service outputs may carry materially different restrictions. The ledger therefore defaults unknown plan and beta status to `blocked`.

## Workflow

1. Generate or acquire audio.
2. Run technical intake and hash the master.
3. Create or update a ledger asset record.
4. Archive evidence and attach its opaque evidence ID.
5. Review third-party IP and performer/voice issues.
6. Set `rights_status` to `cleared` only after evidence verification.
7. Run:

```bash
python3 scripts/validate_audio_rights.py
```

8. Resolve every blocker before release tagging or store submission.

## Status semantics

- `draft`: record incomplete; not eligible to ship.
- `pending_evidence`: rights theory exists but proof is absent or incomplete.
- `review_required`: evidence exists but legal/producer review remains.
- `cleared`: evidence verified and intended exploitation fits the grant.
- `restricted`: usable only within explicitly recorded limitations.
- `blocked`: must not ship.
- `retired`: asset removed from active distribution; record retained.
