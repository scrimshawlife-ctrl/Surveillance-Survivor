# Audio Rights Policy

## 1. Governing principle

Technical acceptance is not rights clearance. A valid WAV/CAF file, successful runtime integration, receipt, prompt, or hash does not by itself establish permission to commercialize the underlying audio.

## 2. Rights that must be covered

The project must possess sufficient rights for the intended use, including as applicable:

- reproduction and storage;
- editing, adaptation, looping, layering, compression, and format conversion;
- synchronization with interactive gameplay, trailers, streams, and advertising;
- distribution in executable builds, patches, DLC, storefront media, and archival copies;
- public performance and communication to the public;
- commercial exploitation worldwide for the required term;
- sublicensing to platform operators, distributors, publishers, contractors, and service providers;
- use of performer identity, voice, likeness, and approved credit where human performance exists.

## 3. Source classes

Every asset must declare exactly one source class:

- `original_human`: created and owned by the project or assigned by a contributor.
- `commissioned`: created by a contractor under a signed agreement.
- `ai_generated`: generated using a service or local model.
- `licensed_library`: obtained under a stock/library license.
- `field_recording`: captured by the project or a contributor.
- `public_domain`: supported by a jurisdictionally appropriate determination.
- `open_license`: governed by a named open license and attribution/compatibility review.
- `third_party_custom`: separately negotiated license.

## 4. Mandatory metadata

Each active asset record must include:

- manifest `asset_id` and immutable master SHA-256;
- title/filename and source class;
- creator, provider, or account custodian;
- creation/acquisition date;
- license or agreement name/version;
- allowed media, territory, term, commercial-use status, modification status, and sublicensing status;
- attribution requirement;
- evidence IDs;
- third-party IP review result;
- rights status, reviewer, and review date.

## 5. AI-generated audio controls

For AI-generated assets, record:

- provider and exact product/model when available;
- generation date and plan tier;
- beta/preview status;
- prompt and generation/export ID where available;
- whether any uploaded reference audio, voice, melody, lyrics, or copyrighted input was used;
- whether the result contains recognizable speech, music quotation, branded sonic identity, celebrity imitation, or other third-party signal;
- the provider terms/license version captured for that generation batch.

Unknown paid-plan status, unknown beta status, missing terms evidence, or unreviewed reference inputs are blockers.

## 6. Human voice and performance controls

No human or synthetic voice intended to identify or imitate a real person may ship without documented authorization covering the exact use. Consent to record is not automatically consent to train, clone, synthesize, alter, advertise, or reuse a voice.

## 7. Music and sample controls

Do not assume that a generated or purchased track is free of composition, master, sample, lyric, melody, or performance claims. Reject or escalate assets containing recognizable quotations, uncleared samples, artist-style imitation likely to identify a living artist, or prompts requesting protected songs or branded sonic marks.

## 8. Attribution

All mandatory attribution must be generated from the rights ledger and copied into game credits, store metadata, documentation, and marketing where the license requires it. Optional courtesy credits must not be represented as legal requirements.

## 9. Evidence integrity

Evidence records must use SHA-256 digests. Private source documents remain outside the public repository. A changed document receives a new evidence ID or versioned record; prior evidence is retained.

## 10. Approval authority

Only the project owner or a named rights reviewer may set `rights_status: cleared`. Agents may populate metadata and identify gaps but must not infer clearance from provider reputation, prior usage, a paid receipt alone, or absence of a complaint.

## 11. Release gate

A production release fails when any shipping manifest asset:

- lacks a ledger entry;
- lacks a matching master hash;
- has no verified evidence;
- is not `cleared`;
- has unresolved restrictions incompatible with the intended release;
- has unresolved third-party IP, voice, performer, sample, or attribution issues.

## 12. Takedown and dispute procedure

When a credible claim arises:

1. freeze the affected asset and derivatives;
2. set status to `blocked`;
3. preserve the asset, prompts, hashes, evidence, build references, and communications;
4. identify every distributed build and marketing use;
5. replace or mute the asset where appropriate;
6. obtain legal review before admitting liability or destroying evidence;
7. record resolution and replacement lineage in the ledger.
