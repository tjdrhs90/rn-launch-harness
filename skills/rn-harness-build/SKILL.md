---
name: rn-harness-build
description: Phase 8 — EAS Build for iOS and Android, plus EAS Update (OTA) configuration.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

# rn-harness-build — Phase 8: EAS Build

Build iOS/Android binaries via EAS Build and configure EAS Update for OTA.

> **EAS 무료 플랜이 꽉 찼거나(3-프로젝트 제한) EAS를 쓰지 않으려면** → `rn-harness-build-local` (로컬 Gradle + Xcode/fastlane, 자체 호스팅 OTA)을 대신 사용하세요.

## Trigger

Called by the orchestrator as Phase 8.

## Input

- Project code (AdMob integration complete)
- `docs/harness/config.md`

## Prerequisites

- `eas-cli` installed (`npm install -g eas-cli`)
- Expo account logged in (`eas login`)

## Process

### Step 1: EAS Init

```bash
# Initialize EAS if not already done
eas init
```

### Step 2: eas.json Setup

Check if `eas.json` exists. If not, create with all required config:

```json
{
  "cli": {
    "version": ">= 15.0.0",
    "appVersionSource": "remote"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "channel": "development"
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview"
    },
    "production": {
      "autoIncrement": true,
      "channel": "production",
      "env": {
        "GRADLE_OPTS": "-Dorg.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g"
      }
    }
  },
  "submit": {
    "production": {
      "ios": {
        "ascAppId": "",
        "appleTeamId": ""
      },
      "android": {
        "serviceAccountKeyPath": "",
        "track": "internal"
      }
    }
  }
}
```

**CRITICAL: Android GRADLE_OPTS**

The `production.env.GRADLE_OPTS` setting is **mandatory**. Without it, Android local builds frequently fail with `OutOfMemoryError` or `Metaspace` errors during Gradle compilation:

```json
"env": {
  "GRADLE_OPTS": "-Dorg.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g"
}
```

This allocates 4GB heap + 1GB metaspace for the Gradle JVM. Adjust if your machine has less RAM (minimum `-Xmx2g`).

**CRITICAL: Build profile `channel` binding**

Each build profile **must** declare a `channel`. A build only receives OTA updates from the channel it was built with — a build with no `channel` is subscribed to nothing, so `eas update` will never reach it no matter how many channels you create later. This binding (in `eas.json`), not `eas channel:create` alone, is what actually wires OTA to the app.

Channel strategy:

| Profile | Channel | Purpose |
|---------|---------|---------|
| `development` | `development` | Dev client / internal iteration |
| `preview` | `preview` | Internal QA / TestFlight / internal track |
| `production` | `production` | Store releases (live OTA to users) |

Keeping `preview` and `production` on separate channels means QA updates never leak to live users, and you can promote a tested update from `preview` → `production` (`eas update:republish`) instead of rebuilding.

### Step 3: EAS Update Setup (OTA)

Configure EAS Update for over-the-air JS bundle updates (no store re-submission needed):

```bash
# Initialize EAS Update
eas update:configure
```

This adds to `app.config.ts`:
```typescript
updates: {
  url: "https://u.expo.dev/[PROJECT_ID]",
},
runtimeVersion: {
  policy: "appVersion",
},
```

And adds `expo-updates` to plugins:
```typescript
plugins: [
  "expo-router",
  "expo-updates",  // ← added
  // ...
],
```

Install the dependency:
```bash
npx expo install expo-updates
```

**Why OTA matters:**
- Fix bugs without store review (JS-only changes)
- A/B test features
- Instant rollback on bad releases
- Store review only needed for native code changes

### Step 4: app.config.ts Verification

Verify all required settings:
- `name`, `slug`, `version`
- `ios.bundleIdentifier` (from config.md)
- `android.package` (same as iOS)
- `android.versionCode`
- AdMob plugin config
- EAS Update config (`updates.url`, `runtimeVersion`)

### Step 4.5: Android Signing Keystore (ASK FIRST — never auto-generate silently)

By default `eas build` **auto-generates a brand-new Android keystore** on the first build. NEVER let this happen silently: if the app is **already live on Google Play**, a new keystore produces an AAB that Play **rejects** (`signed with the wrong key`), and the original key cannot be recovered. Always ask the user first.

**AskUserQuestion** — "안드로이드 앱 서명 keystore를 어떻게 할까요?":

| 선택지 | 의미 |
|--------|------|
| 새로 생성 (신규 앱) | EAS가 keystore 자동 생성. **처음 출시하는 앱**일 때만. |
| 기존 keystore 사용 | 보유한 `.jks`를 EAS에 업로드. **이미 Play에 출시된 앱**이면 필수. |
| 잘 모르겠음 | Play Console에 이 앱이 이미 있으면 → 기존 사용. 완전 신규면 → 새로 생성. |

**"기존 keystore 사용" 선택 시:**

1. 파일과 자격증명을 받는다 (`.jks`를 `credentials/keystore.jks`에 배치):
   - keystore 파일 경로 · keystore 비밀번호 · key alias · key 비밀번호
2. 프로젝트 루트에 `credentials.json` 생성:
   ```json
   {
     "android": {
       "keystore": {
         "keystorePath": "credentials/keystore.jks",
         "keystorePassword": "...",
         "keyAlias": "...",
         "keyPassword": "..."
       }
     }
   }
   ```
3. `.gitignore`에 `credentials.json`, `*.jks`, `*.keystore`가 포함됐는지 확인 (비밀키는 절대 커밋 금지).
4. EAS 서버에 업로드:
   ```bash
   eas credentials --platform android
   # → Keystore → "Set up a new keystore" → "I want to upload my own file"
   #   → credentials.json 경로 지정 (대화형 — 사용자 안내)
   ```
   (또는 `credentials.json`이 있으면 `eas build`가 로컬 파일을 그대로 사용 — 서버 업로드 없이도 동작.)

**"새로 생성" 선택 시:** 별도 작업 없음. 첫 빌드에서 EAS가 생성한다. 생성 후 **반드시 백업**하도록 안내 (`eas credentials` → download). 이 키를 잃으면 향후 업데이트 불가.

> **HARD GATE:** 이미 Play에 출시된 앱에 새 keystore를 쓰면 = FAIL (Play가 업로드 거부). 첫 빌드 전 사용자 확인 필수.

### Step 5: Local Build Test (Recommended)

Local build catches errors faster than cloud build:

```bash
# Android local build first (catches Gradle/dependency issues)
eas build --local --platform android --profile production
```

Common Android local build failures and fixes:

| Error | Fix |
|-------|-----|
| `OutOfMemoryError` / `Metaspace` | Increase `GRADLE_OPTS` in eas.json |
| `SDK location not found` | Set `ANDROID_HOME` env var |
| `NDK not found` | Install NDK via Android Studio SDK Manager |
| `minSdkVersion` conflict | Check `expo-build-properties` plugin |
| `Duplicate class` | Run `cd android && ./gradlew clean` |

```bash
# iOS local build (requires Xcode + macOS)
eas build --local --platform ios --profile production
```

Common iOS local build failures:

| Error | Fix |
|-------|-----|
| `No signing certificate` | EAS manages this automatically in cloud build |
| `Pod install failed` | `cd ios && pod install --repo-update` |
| `Xcode version mismatch` | Update Xcode or set `image` in eas.json |

If local build fails with signing issues, skip to cloud build (EAS handles provisioning automatically).

### Step 6: Cloud Build

```bash
# iOS production build
eas build --platform ios --profile production --non-interactive

# Android production build
eas build --platform android --profile production --non-interactive
```

Wait for build completion. Record build URLs.

### Step 7: Build Result Check

```bash
eas build:list --limit 2
```

- Success → proceed
- Failure → analyze error → fix → rebuild

### Step 8: EAS Update Channel Setup & Verify

Channels are targeted by builds (via the `channel` in eas.json); branches hold the actual update commits. A channel points at a branch — by default a channel maps to a branch of the same name, which is the convention we use here.

```bash
# Create update channels (idempotent — skip any that already exist)
eas channel:create preview
eas channel:create production

# Confirm each channel is mapped to its branch
eas channel:list

# Push the first update to the production branch (→ served on the production channel)
eas update --branch production --message "Initial release" --non-interactive

# Sanity-check the build↔channel wiring: the production build must report channel "production"
eas build:list --limit 1 --platform ios --json --non-interactive | grep -i channel
```

If `eas build:list` shows a build with `channel: null`, the build was created before the `channel` field was added to eas.json — rebuild so the binding takes effect, otherwise OTA will never reach it.

## Output

`docs/harness/handoff/build-result.md`:

```markdown
# EAS Build Result

## iOS
- Profile: production
- Status: [SUCCESS/FAILED]
- Build URL: https://expo.dev/...
- Binary: .ipa

## Android
- Profile: production
- Status: [SUCCESS/FAILED]
- Build URL: https://expo.dev/...
- Binary: .aab

## EAS Update
- Channels: preview, production
- Build channel binding: [production build → production / null]
- Runtime Version: [version]
- Status: [CONFIGURED/FAILED]

## Build Config
- bundleIdentifier: com.xxx.xxx
- package: com.xxx.xxx
- version: 1.0.0
- buildNumber/versionCode: 1
- GRADLE_OPTS: -Xmx4g -XX:MaxMetaspaceSize=1g
```

Git commit:
```bash
git add eas.json app.config.ts
git commit -m "chore: configure EAS build + update profiles"
```

## State Update

```yaml
current_phase: screenshot
next_role: rn-harness-screenshot
```

## HARD GATES

- `eas.json` must exist with all profiles
- `GRADLE_OPTS` must be set in production build env
- `app.config.ts` must have bundleIdentifier/package
- Android keystore choice must be confirmed with the user BEFORE first build (never silently auto-generate for an app already on Play)
- EAS Update must be configured (`expo-updates` installed, `updates.url` set)
- Every `eas.json` build profile must declare a `channel` (build↔OTA binding)
- `production` build must report `channel: "production"` (`eas build:list`) — `null` blocks OTA delivery
- Build failure blocks next Phase
- Build URL must be recorded on success
