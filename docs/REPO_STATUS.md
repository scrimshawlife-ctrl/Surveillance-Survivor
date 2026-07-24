# Repository status audit

**As of:** 2026-07-24  
**`main` tip (pre-push docs):** roadmap + production-readiness refresh  
**Merged art/docs:** #37 final trilogy · #38 README hero  

**Primary sequencing:** [`ROADMAP.md`](ROADMAP.md)  
**Device / ship gates:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)  
**Store worksheet:** [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md)

---

## Open pull requests

| PR | Notes |
| ---: | --- |
| — | **None** |

## Recently merged

| PR | Title |
| ---: | --- |
| [#38](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/38) | README hero + atlas badges |
| [#37](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/37) | NYC + LA + Atlanta foundation packs |
| [#36](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/36)–[#28](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/28) | Columbus → Wichita city packs + audits |

## Open issues

| Issue | Title | Close criterion |
| ---: | --- | --- |
| [#2](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/2) | WP1 playable iPhone foundation | Device acceptance protocol complete |
| [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) | ART production exports | Device ART QA + reserved-art decision + owner ship note |

Closed: #4, #6.

---

## Task board

### Operator / owner

| Task | Doc |
| --- | --- |
| Physical-device acceptance | RELEASE_READINESS · DEVICE_TEST_LOG · #2 |
| ART device QA + ship note | ART_PRODUCTION_READINESS · #3 |
| Privacy + support URLs, SKU, copyright, age rating | APP_STORE_METADATA |
| Store screenshots from release build | APP_STORE_METADATA |
| ElevenLabs license before audio generation | AUDIO_* |

### Autonomous / offline

| Task | Status |
| --- | --- |
| 10-city foundation art | **Done** |
| README / atlas docs | **Done** |
| Roadmap + readiness docs | **This change** |
| Audio Batch 0 inventory | Open |
| Audio Batch 1 (11 stems) | Open (after owner) |
| Projectile/deployable art | Open (after owner decision) |

---

## City foundation packs

All **10** cities on `main`, 13 textures each · **160** runtime PNGs · `make assets-check` green.

## Gates

| Gate | Status |
| --- | --- |
| CI core + simulator | Green on recent merges |
| assets-check | 160 PNGs |
| audio-check | Manifest valid; **62 assets missing** binaries |
| Device acceptance | Pending |
| Store listing | Owner fields pending |

## Suggested next

1. Device acceptance (#2) if hardware available  
2. Else Audio Batch 0 per AUDIO_AGENT_EXECUTION  
3. Owner: publish privacy/support URLs; decide projectile shapes  
4. No city 11  
