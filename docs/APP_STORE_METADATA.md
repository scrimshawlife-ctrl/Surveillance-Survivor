# App Store metadata worksheet

This is a **release-preparation worksheet**, not a completed App Store Connect submission.  
Values marked **OWNER** need legal, business, or live-URL input.  
Values marked **DRAFT** are filled from repository product docs and may be edited before submit.

**Related:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md) · [`ROADMAP.md`](ROADMAP.md) · [`REPO_STATUS.md`](REPO_STATUS.md) · [`App/PrivacyInfo.xcprivacy`](../App/PrivacyInfo.xcprivacy)

**Worksheet tip alignment:** `de0f632` (#82) · app `0.1.0` build `1` · not App Store ready until OWNER rows + device acceptance.

---

## Status summary

| Area | Status |
| --- | --- |
| Product identity (name, bundle, offline MVP story) | **DRAFT complete** from repo |
| Localization copy (subtitle, description, keywords) | **DRAFT complete** — owner may polish |
| Privacy manifest in binary | **Done** (`PrivacyInfo.xcprivacy`) |
| ASC privacy answers | **OWNER** must enter in Connect (basis below) |
| Privacy policy + support URLs | **OWNER** — must be live HTTPS |
| SKU, copyright, age rating, subcategory | **OWNER** |
| Screenshots / preview | **OWNER** + device release build (landscape iPhone) |
| Device acceptance evidence | **Pending** ([`RELEASE_READINESS.md`](RELEASE_READINESS.md) · tip `de0f632`) |
| Product audio in binary | **Blocked** — catalog only; need ElevenLabs license |

---

## App information

| Field | Value | Status |
| --- | --- | --- |
| Name | Surveillance Survivor | Draft / fixed product name |
| Bundle ID | `life.zerostate.surveillancesurvivor` | From `project.yml` |
| Core framework ID | `life.zerostate.surveillancesurvivor.core` | Internal |
| SKU | *immutable internal string, e.g. `SS-IOS-001`* | **OWNER** — choose once |
| Primary language | English (U.S.) | Draft |
| Primary category | Games | Draft |
| Game subcategory | Action *or* Adventure (pick one in Connect) | **OWNER** |
| Content rights | *Zero State / rights-holder legal name* | **OWNER** |
| Copyright | `© {YEAR} {RIGHTS_HOLDER}` | **OWNER** |
| Age rating | Complete Apple questionnaire from shipped content | **OWNER** (guidance below) |
| Privacy policy URL | `https://…` | **OWNER** — required for iOS distribution |
| Support URL | `https://…` | **OWNER** — required |

### Age-rating questionnaire guidance (not a substitute for ASC)

Base answers on **shipped** fiction only:

| Topic | Guidance from product scope |
| --- | --- |
| Violence | Cartoon / non-graphic combat vs hardware and satirical enemies; no gore |
| Horror | Mild tension / satire, not horror |
| Profanity | None required by design; verify final strings |
| Contests / gambling | None |
| Unrestricted web | None (offline MVP) |
| User-generated content | None |
| Location / tracking | None — no live location, no advertising ID |
| Real-world surveillance feeds | **None** — satirical fiction only |

Owner must still complete the official questionnaire against the **binary submitted**.

---

## Version localization draft

| Field | Draft |
| --- | --- |
| Subtitle (≤30 chars ideal) | Break the surveillance grid |
| Promotional text | Stay untrackable, dismantle the grid, and extract through the Blind Spot. |
| Keywords | survivor,roguelite,action,arcade,stealth,offline,satire,camera,pixel |
| Description | See full draft below |
| What’s New (1.0) | Initial release: ten-city campaign, anti-surveillance builds, Blind Spot extraction. Offline. No accounts. |
| Screenshots | **OWNER** — capture from **release** iPhone build; not concept art or README hero |
| App Preview video | Optional |
| App Review notes | See draft below |

### Description draft

```text
Surveillance Survivor is an iPhone-first satirical survivor roguelite.

Move through fluorescent districts, disrupt automated cameras, assemble
anti-surveillance countermeasures, defeat district authorities, and extract
through a temporary Blind Spot.

• Landscape action built for iPhone
• Ten-city campaign from local cameras to national networks
• Suspicion tiers, upgrades, and destructible LPR poles
• Fully offline — no accounts, ads, or live location
• Deterministic runs you can reproduce with a seed

This game is fiction. It satirizes surveillance theater and privatized
authority. It does not use real surveillance feeds or track real people.
```

### App Review notes draft

```text
No login or account is required. No networking is used in the MVP.

Gameplay: virtual stick movement (Settings: handedness / scale / opacity).
Destroy LPR camera poles, pick upgrades, defeat the district boss, enter
the cyan Blind Spot to extract.

Accessibility: reduced camera motion / flash toggles in Settings.
To verify pause: use on-screen pause; separately background the app ≥10s
and resume — entities must not duplicate.

Test account: N/A
```

---

## Screenshot plan (device)

Capture on the **same SHA** that will ship (or note deltas). Prefer 6.7" and 6.1" iPhone sizes Apple currently requires.

| # | Shot | Setup |
| ---: | --- | --- |
| 1 | Title / city select | Unlocked cities visible if possible |
| 2 | Mid-run combat | Player + LPR + suspicion readable |
| 3 | Upgrade draft | Three-choice offer on screen |
| 4 | Distinct city look | e.g. NYC or Atlanta foundation art |
| 5 | Boss pressure | Shift Manager or district boss |
| 6 | Extraction | Blind Spot + completion summary |

**Do not** submit README hero, identity boards, or Notion concept art as gameplay screenshots.

Checklist:

```text
commit SHA:
devices / displays captured:
screenshots folder (local, not necessarily git):
reviewer:
```

---

## Privacy

### In-app privacy manifest (shipped)

`App/PrivacyInfo.xcprivacy`:

| Key | Value |
| --- | --- |
| Tracking | `false` |
| Collected data types | empty |
| Required reason API | UserDefaults `CA92.1` (app-private settings / receipts) |

Re-review whenever adding networking, analytics, ads, cloud, app groups, or third-party SDKs.

### App Store Connect privacy answers (OWNER basis)

Draft answers for an offline MVP with **no** third-party analytics/ads:

| Question theme | Suggested answer basis |
| --- | --- |
| Data used to track you | No |
| Data linked to you | No (local only; no account) |
| Data not linked to you | None collected off-device |
| Product interaction / diagnostics | Only if you later add them — currently local receipts stay on device |
| Third-party partners | None for MVP |

Connect answers must cover the **app + every integrated SDK**. Manifest alone is not the Connect form.

---

## Pricing and availability (OWNER)

| Field | Suggestion |
| --- | --- |
| Business model | Premium one-time purchase (product law) |
| Price tier | Owner choice |
| Availability | Owner choice of territories |
| Release type | Manual or automatic after review |

---

## Submission blockers checklist

### Engineering / evidence

- [ ] Physical-device acceptance receipt for release SHA ([`RELEASE_READINESS.md`](RELEASE_READINESS.md))
- [ ] `make validate` green on release SHA
- [ ] Privacy manifest still accurate for shipped code

### Owner / legal

- [ ] Live privacy policy URL  
- [ ] Live support URL  
- [ ] SKU chosen  
- [ ] Copyright string  
- [ ] Age rating questionnaire complete  
- [ ] Game subcategory selected  
- [ ] Rights confirmation  
- [ ] ASC privacy questionnaire submitted  

### Listing assets

- [ ] Truthful iPhone screenshots from release build  
- [ ] Optional preview video  
- [ ] Final description / keywords review  

---

## Versioning suggestion

| Field | Repo practice |
| --- | --- |
| Marketing version | Set in XcodeGen / target when cutting RC (e.g. `1.0.0`) |
| Build number | Monotonic integer per upload |
| Git tag | `ios-1.0.0-bN` matching build |

Record the tag in the device acceptance log.

---

## Explicit non-claims

- This worksheet is **not** an App Store submission.  
- Drafts are **not** legal advice.  
- Offline MVP claims must remain true in the binary (no silent network).  
- Satire about surveillance is **not** endorsement of real tracking.  
