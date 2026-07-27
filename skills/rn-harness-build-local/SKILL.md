---
name: rn-harness-build-local
description: Phase 8 (EAS-free alternative) — Build & deploy without EAS. For users whose EAS free-plan project slots are full. Local Gradle (Android AAB) + Xcode/fastlane (iOS IPA), self-hosted OTA, then submit via Google Play API + fastlane/Transporter.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

# rn-harness-build-local — Phase 8 (alt): EAS-free Build & Deploy

Build and ship **without EAS**. Use this instead of `rn-harness-build` + the EAS parts of `rn-harness-submit` when the user **cannot use EAS** — most commonly because the **EAS free plan is full** (3-project limit reached) or they simply don't want the dependency.

## When to use this instead of EAS

The orchestrator (or the user) picks the build method at the start of Phase 8:

| Situation | Path |
|-----------|------|
| EAS account has a free project slot, wants managed credentials/OTA | `rn-harness-build` (default) |
| EAS free plan full (3 projects) / declined EAS / wants full local control | **this skill** |

> EAS free plan allows a limited number of projects per account. Once full, `eas init` on a new app fails. This path needs **no EAS project** at all.

## Trigger

Called by the orchestrator as Phase 8 when build method = `local`.

## Input

- Project code (AdMob integration complete)
- `docs/harness/config.md`

## Prerequisites

- **Android:** JDK 17, Android SDK (`ANDROID_HOME` set), Gradle (bundled via wrapper)
- **iOS:** macOS + Xcode + CocoaPods, an Apple Developer account
- **fastlane** (`brew install fastlane` or `gem install fastlane`) — used for iOS signing + upload
- No EAS account required

---

## Process

### Step 1: Prebuild (generate native projects)

Expo managed projects have no `android/` / `ios/` folders until prebuilt. Generate them:

```bash
# Clean native projects from app.config.ts (idempotent)
npx expo prebuild --clean
```

This creates `android/` and `ios/` with the correct bundle id, icons, splash, and plugin config. Re-run after any `app.config.ts` change.

> **OTA note:** `expo-updates` in a non-EAS setup needs a self-hosted update endpoint (see Step 6). If OTA is not needed, remove `expo-updates` from plugins before prebuild to avoid a build-time `updates.url` requirement.

### Step 2: Android Signing Keystore (ASK FIRST)

Same rule as the EAS path — **never silently generate a keystore**. A local Gradle release build **requires** a keystore; there is no cloud fallback.

**AskUserQuestion** — "안드로이드 서명 keystore를 어떻게 할까요?":

| 선택지 | 동작 |
|--------|------|
| 기존 keystore 사용 | 보유한 `.jks` 사용. **이미 Play에 출시된 앱이면 필수.** |
| 새로 생성 (신규 앱) | `keytool`로 새 keystore 생성 (아래). 처음 출시하는 앱만. |
| 잘 모르겠음 | Play에 앱이 이미 있으면 기존 사용, 완전 신규면 새로 생성. |

**새로 생성 시:**
```bash
keytool -genkeypair -v \
  -keystore credentials/keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
# 비밀번호/이름 입력 → credentials/keystore.jks 생성
```
생성 직후 **안전한 곳에 백업** (이 키를 잃으면 앱 업데이트 영구 불가).

**공통 — Gradle에 keystore 연결:** create `android/gradle.properties` entries (or better, `~/.gradle/gradle.properties` so secrets stay out of the repo):
```properties
RN_UPLOAD_STORE_FILE=keystore.jks
RN_UPLOAD_KEY_ALIAS=upload
RN_UPLOAD_STORE_PASSWORD=********
RN_UPLOAD_KEY_PASSWORD=********
```
Place `keystore.jks` at `android/app/keystore.jks` and wire `android/app/build.gradle` `signingConfigs.release` to read those properties. Verify `credentials.json`, `*.jks`, `*.keystore` are gitignored.

> **HARD GATE:** app already on Play + new keystore = FAIL (Play rejects). Confirm before building.

### Step 3: Android Release Build (Gradle → AAB)

```bash
cd android
./gradlew bundleRelease
# → android/app/build/outputs/bundle/release/app-release.aab
```

APK for sideload testing (optional):
```bash
./gradlew assembleRelease
# → android/app/build/outputs/apk/release/app-release.apk
```

Common failures & fixes:

| Error | Fix |
|-------|-----|
| `OutOfMemoryError` / `Metaspace` | `org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g` in `android/gradle.properties` |
| `SDK location not found` | set `ANDROID_HOME`, or create `android/local.properties` with `sdk.dir=...` |
| `Keystore file not found` | keystore path in `build.gradle` is relative to `android/app/` |
| `Duplicate class` | `./gradlew clean` then rebuild |

### Step 4: iOS Release Build (fastlane gym → IPA)

Requires macOS + Xcode + an Apple Developer account. Use fastlane for signing so we don't hand-manage provisioning profiles.

```bash
cd ios && pod install && cd ..
```

Create `ios/fastlane/Fastfile` (or use `fastlane match` for team signing):
```ruby
default_platform(:ios)
platform :ios do
  lane :beta do
    build_app(
      scheme: "<APP_SCHEME>",           # usually the app slug
      export_method: "app-store",
      workspace: "ios/<APP>.xcworkspace"
    )
    upload_to_testflight(               # → TestFlight
      api_key_path: "credentials/asc-api-key.json"  # ASC API key (see submit skill)
    )
  end
end
```

```bash
cd ios && fastlane beta
```

Signing options:
- **Automatic (recommended):** `fastlane` + ASC API key handles certs/profiles.
- **`fastlane match`:** for teams sharing certs via a private git repo.
- **Manual:** `xcodebuild -workspace ... -scheme ... archive` then `-exportArchive` with an `exportOptions.plist`. Only if fastlane is unavailable.

If no macOS is available, iOS cannot be built locally — note this to the user and either use a Mac/CI runner or fall back to EAS **for iOS only**.

### Step 5: Verify Build Artifacts

```bash
ls -lh android/app/build/outputs/bundle/release/app-release.aab
ls -lh ios/build/*.ipa 2>/dev/null || echo "iOS built via fastlane → uploaded to TestFlight"
```

- AAB present → Android ready
- IPA present / uploaded to TestFlight → iOS ready
- Record paths in the build result (Output below)

### Step 6: OTA Without EAS Update (optional)

EAS Update is a hosted service. Without it, `expo-updates` needs a **self-hosted update server**. Options, easiest first:

1. **Skip OTA** — remove `expo-updates`; ship JS changes via normal store updates. Simplest; fine for low-frequency updates.
2. **Self-host the Expo Updates protocol** — `npx expo export` produces the update bundle in `dist/`; serve it from any static host (S3/CloudFront, Cloudflare, a small Express server implementing the [expo-updates protocol](https://docs.expo.dev/technical-specs/expo-updates-1/)). Set `updates.url` in `app.config.ts` to that endpoint. Most control, most setup.
3. **Third-party OTA** (e.g. self-hosted alternatives) — drop-in servers that speak the expo-updates protocol.

```bash
# Produce an update bundle to host yourself (option 2)
npx expo export --platform all
# → dist/  (upload to your static host; point updates.url at it)
```

> Record which OTA option was chosen. If "skip", state clearly that JS fixes now require a store re-submission.

### Step 7: Git Commit

```bash
git add android/ ios/ app.config.ts .gitignore
git commit -m "chore: local (EAS-free) build config for Android + iOS"
```
(Native folders `android/`/`ios/` are committed here because this is the bare-workflow build source. Never commit the keystore or `credentials.json`.)

---

## Submit (EAS-free)

The `rn-harness-submit` skill already submits **Android via the Google Play Developer API** (`scripts/publish.js`) — that path is **already EAS-free**, it just needs the local `app-release.aab`. Only the iOS binary upload differs.

### Android — reuse Google Play API path

Follow `rn-harness-submit` Part B unchanged. In the manual AAB-upload step, upload the **local** `android/app/build/outputs/bundle/release/app-release.aab` instead of an EAS build URL. `scripts/publish.js` handles metadata, images, and review submission via the API.

### iOS — upload without `eas submit`

Pick one (all use the ASC API key from `rn-harness-submit` A-1):

| Tool | Command | Notes |
|------|---------|-------|
| **fastlane** (recommended) | `fastlane pilot upload` (TestFlight) / `fastlane deliver` (App Store) | Same key as build step; scriptable |
| **Transporter app** | GUI drag-drop the `.ipa` | Manual, no CLI |
| **altool** | `xcrun altool --upload-app -f app.ipa --apiKey <KEY_ID> --apiIssuer <ISSUER>` | Built into Xcode CLI |

Then metadata + review submission via the **App Store Connect API** exactly as in `rn-harness-submit` A-3 (that part never used EAS).

> **If you upload screenshots with `fastlane deliver` instead of the ASC API** (some prefer it), it **appends by default** — running it more than once (or leaving stale files in the folder) stacks duplicate screenshots on the listing. This is a confirmed footgun. Guard it:
> - **Clear the folder first**, leave only the final images: `rm -rf fastlane/screenshots/* && cp <final PNGs> fastlane/screenshots/`
> - Pass **`--overwrite_screenshots true`** (replace instead of append), plus `--skip_binary_upload true --skip_metadata true` when uploading screenshots only.
> - Keep **one image per device-size slot** — a single PNG matching several size slots lands in each, showing the same picture multiple times.
> ```bash
> # fastlane/Deliverfile (screenshots only)
> api_key_path("./credentials/asc-api-key.json")
> app_identifier("com.company.app")
> screenshots_path("./fastlane/screenshots")
> overwrite_screenshots(true)
> skip_binary_upload(true)
> skip_metadata(true)
> run_precheck_before_submit(false)
> ```

---

## Output

`docs/harness/handoff/build-result.md`:

```markdown
# Build Result (EAS-free / local)

## Build Method
- EAS: NOT USED (reason: [free plan full / user choice])

## Android
- Method: local Gradle (`./gradlew bundleRelease`)
- Status: [SUCCESS/FAILED]
- Artifact: android/app/build/outputs/bundle/release/app-release.aab
- Keystore: [existing / newly generated — BACKED UP?]

## iOS
- Method: fastlane gym (Xcode)
- Status: [SUCCESS/FAILED/SKIPPED — no macOS]
- Artifact: [.ipa path / uploaded to TestFlight]

## OTA
- Strategy: [skipped / self-hosted expo-updates / third-party]
- updates.url: [endpoint or N/A]

## Build Config
- bundleIdentifier / package: com.xxx.xxx
- version: 1.0.0
- buildNumber / versionCode: 1
```

## State Update

```yaml
current_phase: screenshot
next_role: rn-harness-screenshot
```

## HARD GATES

- Android keystore choice confirmed with user BEFORE build (never silently generate for an app already on Play)
- Keystore backup confirmed if newly generated (loss = permanent inability to update)
- `credentials.json`, `*.jks`, `*.keystore` gitignored — secrets never committed
- Android AAB must exist and be signed with the correct (upload) key
- iOS: if no macOS, explicitly report iOS cannot be built locally (don't silently skip)
- OTA strategy recorded; if "skip", user told JS fixes need store re-submission
- Build failure blocks next Phase
