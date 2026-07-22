# App Store Metadata Scaffold

This is a release-preparation worksheet, not an App Store Connect submission. Values marked **owner action** need a real legal or support destination before review.

## App information

| Field | Proposed value / action |
|---|---|
| Name | Surveillance Survivor |
| Bundle ID | `life.zerostate.surveillancesurvivor` |
| SKU | **Owner action:** choose an immutable internal SKU |
| Primary language | English (U.S.) |
| Primary category | Games |
| Game subcategory | **Owner action:** select in App Store Connect |
| Age rating | **Owner action:** complete Apple questionnaire from shipped content |
| Copyright | **Owner action:** supply rights-holder and year |
| Privacy policy URL | **Owner action:** publish a real policy URL; Apple requires one for iOS distribution |
| Support URL | **Owner action:** publish a support/contact URL |

## Version localization draft

| Field | Draft |
|---|---|
| Subtitle | Break the surveillance grid |
| Promotional text | Stay untrackable, dismantle the grid, and extract through the Blind Spot. |
| Keywords | survivor,roguelite,action,arcade,stealth,offline,satire |
| Description | Surveillance Survivor is an iPhone-first satirical survivor roguelite. Move through a fluorescent parking expanse, disrupt automated surveillance, build anti-surveillance countermeasures, defeat the Shift Manager, and extract through a Blind Spot. The current release candidate is offline and does not use accounts, ads, live location, or real surveillance feeds. |
| Screenshots | **Owner action:** capture truthful iPhone screenshots from the release build; do not use concept art as gameplay evidence. |
| App Review notes | No login or account is required. Describe any non-obvious gesture, accessibility setting, or test flow in the submitted build. |

## Privacy declaration basis

The bundled `App/PrivacyInfo.xcprivacy` declares no tracking, no collected data, and the app-private UserDefaults reason `CA92.1` for local settings and receipt storage. Re-review the manifest and App Store Connect privacy answers whenever networking, analytics, advertising, third-party SDKs, app groups, cloud sync, or new required-reason APIs are added.

Apple requires the App Store Connect privacy answers to cover both the app and all integrated third-party partners; the repository manifest alone does not complete this submission requirement.

## Submission blockers

- Physical-device acceptance receipt and performance evidence.
- Owner-provided privacy policy and support URLs.
- Age-rating questionnaire, rights confirmation, SKU, and copyright.
- Truthful release-build screenshots and any required app-review notes.
- Final App Store Connect privacy questionnaire review against the shipped binary.
