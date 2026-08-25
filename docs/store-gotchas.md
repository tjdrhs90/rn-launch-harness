# Store gotchas — rejections and API traps already hit

Real App Store / Google Play rejections and API failures from shipping and maintaining
Expo/React Native apps. Each one cost a review cycle. Prevent them up front.

---

## Expo config plugins apply even when they are not in `plugins`

**This is the trap that catches everyone.** Expo auto-applies a package's config plugin when
the package is a dependency, whether or not you listed it in `app.json` → `plugins`.

So this rejection happens to an app whose `plugins` array never mentions `expo-image-picker`:

> Guideline 5.1.1 — the app's purpose string does not sufficiently explain the use of the
> `NSMicrophoneUsageDescription`: "Allow app to access your microphone"

The string is the plugin's own default:

```js
// node_modules/expo-image-picker/plugin/build/withImagePicker.js
const MICROPHONE_USAGE = 'Allow $(PRODUCT_NAME) to access your microphone';
```

`$(PRODUCT_NAME)` is substituted at build time and ships as a placeholder.
`expo-camera` has the same default.

**You cannot audit this by reading `app.json`.** The only reliable check is the generated plist:

```sh
npx expo prebuild -p ios --clean --no-install
plutil -p ios/*/Info.plist | grep -i usagedescription
# any "Allow $(PRODUCT_NAME) to ..." → will be rejected
```

**Fix** — if the app only picks photos (`mediaTypes: ['images']`), remove the key:

```json
["expo-image-picker", { "microphonePermission": false }]
["expo-camera",       { "microphonePermission": false }]
```

`createPermissionsPlugin` treats `false` as "delete this key" and does not overwrite the
`ios.infoPlist` strings you wrote yourself. Confirm with a prebuild.

If the app genuinely records audio, write a specific string in the app's language instead —
a concrete purpose string in Korean passes; the English placeholder does not.

## Never ship a permission for a feature the user cannot reach

A review note that reads "camera permission is included for a **future** receipt-scan
feature" is an invitation to be rejected. Worse: the screen existed, was registered in the
navigation stack, and had **no entry point in the UI** — so the app requested camera, photo
library, and microphone for something no user could open.

Add the permission in the release that ships the feature. Before submitting, for every
declared permission ask: which screen uses it, and how does a user get to that screen?

## Age rating — the declarations Apple added in 2026

App Store Connect's age-rating questionnaire gained new questions. An app whose record only
answered the old questionnaire has these unset, and **submission is blocked before human
review**:

```
userGeneratedContent · messagingAndChat · ageAssurance · gunsOrOtherWeapons
advertising · healthOrWellnessTopics · parentalControls
```

Two ways this bites:

- `409 STATE_ERROR.ENTITY_STATE_INVALID` on submit, naming a missing
  `ageRatingDeclarations` attribute.
- The submission goes through and is then bounced by Apple's automated analysis:

  > An automated analysis of the submission indicates the app may include advertising but
  > you did not select "Yes" for the "Advertising" content descriptor.

**Any app with AdMob must set `advertising` = Yes.** Banners count.

**`ageRatingDeclarations` is write-only over the API** — `GET` returns `403`. You cannot
audit which apps are configured; you have to look in the Connect web UI. Budget for that.

## App Store Connect API — submitting for review

`POST /v1/appStoreVersionSubmissions` is **deprecated**. It returns
`403 "Allowed operation is: DELETE"`. Submission is now three calls:

```
1. POST /v1/reviewSubmissions              { platform: IOS, app: <appId> }
   → reuse an existing submission in state READY_FOR_REVIEW if there is one
2. POST /v1/reviewSubmissionItems          { reviewSubmission: <id>, appStoreVersion: <id> }
3. PATCH /v1/reviewSubmissions/<id>        { submitted: true }
```

### Resubmitting a rejected version

A rejected version is **still attached to the submission that was rejected**. Adding it to a
new one fails with `STATE_ERROR.ITEM_PART_OF_ANOTHER_SUBMISSION`.

Detach the stale items first — for every submission in state `UNRESOLVED_ISSUES`:

```
PATCH /v1/reviewSubmissionItems/<itemId>   { removed: true }
```

Also: do **not** create a new version for a rejection. `REJECTED`,
`DEVELOPER_REJECTED`, `METADATA_REJECTED`, and `INVALID_BINARY` are editable — attach the new
build to the same version and resubmit. Creating a second version with the same version
string fails with `ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE`.

### When metadata locks

| Version state | `whatsNew`, URLs, review notes |
|---|---|
| `PREPARE_FOR_SUBMISSION` | editable |
| `WAITING_FOR_REVIEW` | **editable** |
| `IN_REVIEW` | editable |
| `READY_FOR_SALE` | **locked** — `PATCH` returns `409` |

Waiting for review is not too late. Once it is released, a wrong release note stays wrong
until the next version — so proofread before the build is approved, not after.

## Resolution Center has no API — use the review notes

There is no public endpoint for the rejection message or for replying to it:

| Path | Result |
|---|---|
| `/resolutionCenterThreads` | 404 |
| `/resolutionCenterMessages` | 404 |
| `/apps/{id}/resolutionCenterThreads` | 404 |

The API only exposes state: `appStoreState: REJECTED`,
`reviewSubmissions.state: UNRESOLVED_ISSUES`.

**`appStoreReviewDetail.notes` is readable and writable, and reviewers read it.** It is the
only channel you can automate. When fixing a rejection, **update the notes before
resubmitting** — say what was wrong, why, and what changed in this build. Stating facts works;
"we will add this later" does not.

## A released version string cannot take a new build

Uploading a build whose version string matches an already-released version fails:

> Invalid Pre-Release Train. The train version '1.2.0' is closed for new build submissions.

Bump the version name. On Flutter, change only the name in `pubspec.yaml` and leave the `+N`
build number alone — that number is the Android `versionCode` and must keep increasing
independently.

## Android adaptive icon safe zone

`android.adaptiveIcon.foregroundImage` is drawn on a **108dp** canvas, the launcher masks it
to **72dp**, and only the centre **~66dp circle** is guaranteed unclipped. Reusing the
full-bleed 1024×1024 `icon.png` as the foreground makes the icon look cropped and zoomed on
every Android launcher.

Keep the motif inside ~50% of the canvas width — roughly 25% padding on all four sides — on a
solid `backgroundColor`. Also ship a monochrome variant for Android 13+ themed icons.

## Play Console declarations come from the *merged* manifest

Play Console's **App content → 주의 필요 / Needs attention** flags permissions in the shipped
bundle, not the ones you wrote. A dependency's own `AndroidManifest.xml` is merged in, so a
permission you never typed becomes your declaration to file.

The one that bites: `FOREGROUND_SERVICE_*`. Google requires a declaration form for it that
includes a **mandatory demo video link** (unlisted YouTube works; private does not). Miss the
compliance deadline and **future updates are blocked** — the live listing stays up, so it is
easy not to notice until a release is stuck.

Check the merged result, not your source:

```sh
grep uses-permission \
  android/app/build/intermediates/merged_manifests/release/AndroidManifest.xml
```

`FOREGROUND_SERVICE_*`, `SCHEDULE_EXACT_ALARM`, `QUERY_ALL_PACKAGES`, and `READ_MEDIA_*` all
require separate Play Console declarations.

Removing your own `<uses-permission>` line does nothing if the dependency declares it.
Dropping the permission means dropping or replacing the dependency.

## Privacy policy URL — readable on iOS, not on Android

| Store | Field | API |
|---|---|---|
| App Store | `appInfoLocalizations.privacyPolicyUrl` (per locale, per app not per version) | read + write |
| Play | Policy → App content → Privacy policy | **neither** |

Play Developer API v3 has no endpoint for it: `edits().listings()` carries only title and
descriptions, `edits().details()` only contact fields, and `applications().dataSafety()` is
create-only. Auditing privacy policy URLs across a Play portfolio is a manual console job.

On iOS it is per-locale — a 30-language app has 30 of them, and they are easy to leave behind
when the URL changes.

## Build machine

- **iOS and Android release builds at the same time will OOM a 16 GB machine** and kill both.
  Run them sequentially.
- **Check free disk before an iOS build.** A full disk fails deep in the archive step with an
  unhelpful error. Gate on ~12 GB free.
- **Never edit a shell script while it is running.** `zsh` reads the file by byte offset as it
  executes; an edit shifts the offsets and the shell runs garbage from the middle of a line.
  Prepare the patch and apply it after the run finishes.
- **A build script that runs `git checkout` on a generated-but-tracked file will silently
  revert real source changes.** iOS build scripts often restore `project.pbxproj` after
  prebuild this way. Save a copy before prebuild and move it back instead — otherwise the repo
  and the shipped binary disagree and nobody notices.

## Auditing a portfolio: ask the store, not the filesystem

When sweeping many apps, do not derive the target list from directory layout. Detecting iOS
apps by the presence of an `<app>-ios/` folder misses every Expo-standalone and Flutter app,
which build iOS from the same directory. Enumerate from `GET /v1/apps` and reconcile against
what you have locally.
