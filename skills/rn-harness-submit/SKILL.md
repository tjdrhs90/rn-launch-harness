---
name: rn-harness-submit
description: Phase 10 — Submit to App Store Connect (iOS) and Google Play (Android). iOS fully automated, Android pauses for manual steps.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

# rn-harness-submit — Phase 10: Store Submission

Submit the app to App Store and Google Play. Uses App Store Connect API (iOS) and Google Play Developer API v3 (Android).

## Trigger

Called by the orchestrator as Phase 10.

## Input

- `docs/harness/config.md` (API keys, developer info)
- `docs/harness/handoff/build-result.md` (build URLs)
- `docs/harness/store-assets/` (screenshots + metadata)
- `.env` (credentials)

---

## Part 0: Pre-submission checks — run these before anything else

Every one of these has caused a real rejection. See `docs/store-gotchas.md` for the full
write-ups. Four checks, all cheap:

**1. No placeholder purpose strings in the generated `Info.plist`.**
Reading `app.json` is not enough — **Expo applies a package's config plugin whenever the
package is a dependency, whether or not it is listed in `plugins`.** `expo-image-picker` and
`expo-camera` inject `NSMicrophoneUsageDescription = "Allow $(PRODUCT_NAME) to access your
microphone"`, which Apple rejects under 5.1.1.

```bash
npx expo prebuild -p ios --clean --no-install
plutil -p ios/*/Info.plist | grep -i usagedescription
# any "Allow $(PRODUCT_NAME) to ..." → fix before submitting
```

Fix — if the app only picks photos, drop the key rather than writing a string for a capability
the app does not use:

```json
["expo-image-picker", { "microphonePermission": false }]
["expo-camera",       { "microphonePermission": false }]
```

**2. Every declared permission belongs to a feature a user can reach.** For each
`NS*UsageDescription` and each Android permission, name the screen that uses it and the path a
user takes to get there. A permission for an unreachable or not-yet-built feature is a
rejection, and "we will use it later" in the review notes makes it worse.

**3. Age rating declarations are complete** — especially `advertising` = Yes for any AdMob
build (step A-3.9). Cannot be verified over the API; check the Connect UI.

**4. Android: read the *merged* manifest, not yours.** Dependencies merge in their own
permissions, and Play Console will demand a declaration for them.

```bash
grep uses-permission \
  android/app/build/intermediates/merged_manifests/release/AndroidManifest.xml
```

`FOREGROUND_SERVICE_*` needs a Play Console declaration **with a mandatory demo video**;
`SCHEDULE_EXACT_ALARM`, `QUERY_ALL_PACKAGES`, and `READ_MEDIA_*` need declarations too. Past
the compliance deadline these block updates while the live listing stays up — easy to miss.

---

## Part A: iOS — App Store Submission (Fully Automated)

### A-1: Credential Check

Read from `.env`:
- `ASC_KEY_ID` — API Key ID (10 chars)
- `ASC_ISSUER_ID` — Issuer ID (UUID)
- `ASC_PRIVATE_KEY_PATH` — .p8 file path (default: `./credentials/asc-api-key.p8`)

If missing or .p8 file not found → AskUserQuestion:
```
App Store Connect API Key is required.

1. App Store Connect → Users and Access → Integrations → API Keys
2. Generate new key (Admin role)
3. Save .p8 file to credentials/asc-api-key.p8
4. Add to .env:

   ASC_KEY_ID=XXXXXXXXXX
   ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ASC_PRIVATE_KEY_PATH=./credentials/asc-api-key.p8

Press Enter when done. (Type "eas" if already configured in EAS)
```

### A-2: Binary Upload

**If `config.md → build.method` is `eas`:**
```bash
eas submit --platform ios --profile production --non-interactive
```
Or with a specific build URL:
```bash
eas submit --platform ios --url [BUILD_URL] --non-interactive
```

**If `build.method` is `local` (EAS-free — see `rn-harness-build-local`):** upload the local `.ipa` without EAS, using the same ASC API key:
```bash
# fastlane (recommended)
fastlane pilot upload            # → TestFlight
# or
xcrun altool --upload-app -f app.ipa --type ios \
  --apiKey $ASC_KEY_ID --apiIssuer $ASC_ISSUER_ID
```
Android is unaffected — Part B already uploads the AAB via the Google Play API, EAS or not.

### A-3: App Store Connect API — Metadata

EAS Submit handles the binary upload. Additional metadata via ASC API:

1. **Check/Create App Record**
   - Check if Bundle ID exists → if not, register via `POST /v1/bundleIds`
   - Create app record via `POST /v1/apps`

2. **Create App Store Version**
   - `POST /v1/appStoreVersions` (version: "1.0.0", platform: IOS)

3. **App Info**
   - Primary locale: `ko` (Korean)
   - Primary category from PRD
   - Privacy policy URL: `config.md → developer.privacy_url`

4. **Localization** (ko locale)
   - App name (from title.txt), description (from full_description.txt), subtitle (from subtitle.txt)
   - **Keywords** (from keywords.txt) — MUST be 95-100 chars including commas.
     - Verify `keywords.txt` length before upload
     - If < 95 chars: return to screenshot phase to regenerate (don't waste ASO budget)
     - If > 100 chars: reject (API will fail)
   - Marketing URL: `config.md → developer.homepage_url`
   - Support URL: `config.md → developer.email` (or privacy URL)

5. **Copyright**
   - `config.md → developer.copyright`

6. **Screenshot Upload** (idempotent — DELETE existing before upload)
   - iPhone 6.7" (`APP_IPHONE_67`) screenshots only (supportsTablet: false → no iPad)
   - **CRITICAL — clear existing first, or re-runs pile up duplicates.** The ASC API *appends* to a screenshot set; uploading again without clearing stacks a second (third…) copy of every shot. This is the #1 cause of "each screenshot appears twice." Mirror the Android path, which already deletes before upload (`templates/publish.js` → `images.deleteall`).
   - Order per locale:
     1. `GET` the version's `appStoreVersionLocalizations` → `appScreenshotSets` for `screenshotDisplayType = APP_IPHONE_67`
     2. **`DELETE` every existing `appScreenshots` in that set** (or delete the set and recreate)
     3. Create the set if missing → reserve → upload binary → commit
   - **One display type only.** Upload each PNG to exactly one `screenshotDisplayType`. Do NOT reuse the same image across multiple size slots (6.7"/6.5"/…) — that makes "the same picture appears several times" on the listing.

7. **Build Assignment**
   - Wait for build processing (`processingState: VALID`)
   - Link build to version

8. **Review Information**
   - Contact: `config.md → ios_review` (first_name, last_name, phone)
   - Demo account (if needed — AskUserQuestion)
   - Encryption: No (ITSAppUsesNonExemptEncryption: false)
   - **Notes** (`appStoreReviewDetail.notes`) — readable and writable, and reviewers read it.
     This is the only reviewer-facing channel the API can touch (Resolution Center has none).
     Write what the app does that a reviewer might otherwise misread. State facts only — a note
     saying a permission is there "for a future feature" gets the build rejected.
     **When resubmitting after a rejection, update the notes BEFORE submitting**, not after.

9. **Age Rating Declarations** — required, and easy to miss

   `PATCH /v1/apps/{id}/relationships/ageRatingDeclaration` (or the version's
   `ageRatingDeclaration`). Apple added questions in 2026; an app that only answered the old
   questionnaire has them unset and **cannot enter review**:

   ```
   userGeneratedContent · messagingAndChat · ageAssurance · gunsOrOtherWeapons
   advertising · healthOrWellnessTopics · parentalControls
   ```

   - **If AdMob is enabled, `advertising` MUST be Yes.** Banners count. Getting this wrong
     gets the build bounced by Apple's automated analysis before a human sees it.
   - Unset attributes surface as `409 STATE_ERROR.ENTITY_STATE_INVALID` at submit time.
   - **`GET` on `ageRatingDeclarations` returns `403`** — write-only. You cannot verify over
     the API; check the Connect web UI if you need to confirm.

10. **Submit for Review** — three calls, not one

    `POST /v1/appStoreVersionSubmissions` is **deprecated** and returns
    `403 "Allowed operation is: DELETE"`. Use `reviewSubmissions`:

    ```
    a. POST  /v1/reviewSubmissions        { platform: IOS, app: <appId> }
             → reuse an existing submission in state READY_FOR_REVIEW if one exists
    b. POST  /v1/reviewSubmissionItems    { reviewSubmission: <id>, appStoreVersion: <id> }
    c. PATCH /v1/reviewSubmissions/<id>   { submitted: true }
    ```

    **Resubmitting after a rejection** — the rejected version is still attached to the
    submission that was rejected, so step (b) fails with
    `STATE_ERROR.ITEM_PART_OF_ANOTHER_SUBMISSION`. Detach first: for every submission in
    state `UNRESOLVED_ISSUES`, `PATCH /v1/reviewSubmissionItems/<itemId> { removed: true }`.

    Also do **not** create a new version for a rejection. `REJECTED`, `DEVELOPER_REJECTED`,
    `METADATA_REJECTED`, and `INVALID_BINARY` are all editable — attach the new build to the
    same version. Creating a second version with the same version string fails with
    `ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE`.

    **Metadata stays editable through `WAITING_FOR_REVIEW` and `IN_REVIEW`.** It locks at
    `READY_FOR_SALE`, where `PATCH` returns `409`. A wrong release note is fixable right up
    until release — and unfixable one minute after.

### A-4: iOS Result

```
iOS submission complete!
- App: [name]
- Version: 1.0.0
- Status: Waiting for Review
- App Store Connect: https://appstoreconnect.apple.com
```

---

## Part B: Android — Google Play Submission

### B-1: Manual Steps (API Limitations)

AskUserQuestion — PAUSE and guide user through mandatory manual steps:

```
Google Play requires some manual setup that the API cannot do.

Please complete these in Play Console (https://play.google.com/console):

1. CREATE APP:
   - App name: [name from PRD]
   - Default language: Korean
   - App (not game) / Free
   - Accept declarations

2. AAB UPLOAD (first time only):
   - Production → Create new release
   - Upload the .aab file from EAS Build
   - (Download link: [build URL from build-result.md])

3. CONTENT RATING (IARC):
   - App content → Content rating → Start questionnaire
   - Complete the survey

4. DATA SAFETY:
   - App content → Data safety
   - Fill out the privacy form
   - Note: If using AdMob, declare "Advertising" data collection

5. TARGET AUDIENCE & ADS:
   - Set target age group
   - Select "Yes, contains ads" (if AdMob enabled)

6. APP CATEGORY:
   - Store settings → App category
   - Select appropriate category

7. COUNTRIES/REGIONS:
   - Production → Countries/regions
   - Select distribution countries

Press Enter when all steps are complete.
```

### B-2: Service Account Check

Read from `.env`:
- `GOOGLE_PLAY_SA_JSON` — path to service account JSON

If missing → AskUserQuestion:
```
Google Play Service Account JSON is required.

1. Play Console → Settings → API access
2. Create or link a service account
3. Grant "Release Manager" role
4. Download JSON key
5. Save to credentials/google-play-sa.json
6. Add to .env:

   GOOGLE_PLAY_SA_JSON=./credentials/google-play-sa.json

Enter the path, or press Enter if already set.
```

### B-3: Generate publish.js Script

Create `scripts/publish.js` in the project based on the proven pattern:

```javascript
#!/usr/bin/env node

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

const PACKAGE_NAME = '[from config.md bundle_id]';
const KEY_FILE = path.resolve(__dirname, '..', process.env.GOOGLE_PLAY_SA_JSON || './credentials/google-play-sa.json');
const METADATA_DIR = path.resolve(__dirname, '..', 'docs/harness/store-assets/metadata');
const SCREENSHOTS_DIR = path.resolve(__dirname, '..', 'docs/harness/store-assets');

const APP_CONFIG = {
  contactEmail: '[from config.md developer.email]',
  contactWebsite: '[from config.md developer.homepage_url]',
  contactPhone: '',
  defaultLanguage: 'ko-KR',
};

// ... (full publish.js implementation)
```

Install dependency:
```bash
npm install googleapis
```

### B-4: Prepare Metadata Files

Create metadata directory structure from store-assets:
```
docs/harness/store-assets/
├── metadata/
│   └── ko-KR/
│       ├── title.txt              # App name (from PRD)
│       ├── short_description.txt  # 80 chars max
│       ├── full_description.txt   # 4000 chars max
│       └── release_notes.txt      # What's new
├── icon.png                       # 512x512
├── feature_graphic.png            # 1024x500
└── android/
    └── phone/
        ├── phone_01.png
        ├── phone_02.png
        └── phone_03.png
```

### B-5: Run Publish Script

Execute in stages:

```bash
# Step 1: Metadata + images only (no submission)
node scripts/publish.js --images

# Step 2: Verify in Play Console that everything looks correct
```

AskUserQuestion:
```
Metadata and images have been uploaded to Play Console.
Please verify in the Play Console that everything looks correct.

Press Enter to proceed with review submission, or type "skip" to submit manually.
```

```bash
# Step 3: Submit for review
node scripts/publish.js --submit-only --track production
```

### B-6: Handle Draft Status

If the app is still in draft (first submission, manual steps incomplete):
- Script detects draft status automatically
- Updates release notes only (cannot submit draft via API)
- Prints warning with remaining manual steps:

```
⚠ App is still in draft status.
Complete these in Play Console before review submission:
  □ Content rating (IARC questionnaire)
  □ App category
  □ Countries/regions
  □ Data safety section
```

AskUserQuestion:
```
The app is in draft status — some Play Console steps are still incomplete.
Complete the items listed above, then press Enter to retry submission.
(Or type "done" to finish — you can submit manually from Play Console.)
```

### B-7: Android Result

```
Android submission complete!
- App: [name]
- Track: production
- Version: [versionCode]
- Status: [completed/draft]
- Play Console: https://play.google.com/console
```

---

## Part C: Final Wrap-up

### C-1: Submission Report

`docs/harness/handoff/submit-result.md`:

```markdown
# Store Submission Report

## iOS — App Store
- Status: [Submitted/Skipped/Failed]
- Version: 1.0.0
- Build: [buildNumber]
- Submitted: [date]

## Android — Google Play
- Status: [Submitted/Draft/Skipped/Failed]
- Track: [production/internal]
- Version Code: [versionCode]
- Submitted: [date]
- Script: scripts/publish.js

## AdMob
- iOS Ad Units: [real/test]
- Android Ad Units: [real/test]
- Note: [Replace test IDs before release if using test IDs]

## EAS Update
- Channel: production
- OTA ready: [yes/no]

## Pending Manual Actions
- [ ] [remaining items]

## Re-submission Commands
# Update metadata + images
node scripts/publish.js --images

# Submit for review
node scripts/publish.js --submit-only

# Full automation
node scripts/publish.js --images --submit

# Internal test track
node scripts/publish.js --images --submit --track internal
```

### C-2: Git Tag

```bash
git tag -a v1.0.0 -m "Release 1.0.0 — Store submission"
```

AskUserQuestion before pushing tag:
```
Ready to create git tag v1.0.0. Push to remote? (yes/no)
```

## State Update

```yaml
status: completed
current_phase: done
```

## HARD GATES

- iOS: EAS build must succeed before submission
- Android: Manual Play Console steps must be confirmed before API calls
- Screenshots and metadata must exist before submission
- iOS screenshots: DELETE existing shots in the set before uploading (idempotent re-runs; matches Android `publish.js` deleteall) — never append
- iOS: upload each image to exactly one `screenshotDisplayType` (no reusing one PNG across size slots)
- Privacy policy URL required for both stores
- Service Account JSON must exist and be valid for Android API calls
- Draft app detection: gracefully degrade to release notes update only
- Submission failure: analyze error, report to user, do NOT retry blindly
- publish.js must be generated with correct package name and config values
- Part 0 checks pass: no placeholder purpose strings, no permission without a reachable feature, age rating declarations set (`advertising` = Yes when AdMob is on), merged Android manifest reviewed
- iOS submit uses the `reviewSubmissions` 3-call flow — `appStoreVersionSubmissions` CREATE is deprecated (403)
- Resubmission after rejection: reuse the rejected version, detach stale `reviewSubmissionItems` (`removed: true`), update review notes BEFORE submitting
