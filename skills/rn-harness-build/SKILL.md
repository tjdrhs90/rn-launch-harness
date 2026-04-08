# rn-harness-build — Phase 8: EAS Build

Build iOS/Android binaries via EAS Build and configure EAS Update for OTA.

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
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "autoIncrement": true,
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

### Step 8: Verify EAS Update Channel

```bash
# Create production update channel (if not exists)
eas channel:create production

# Verify update config
eas update --branch production --message "Initial release" --non-interactive
```

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
- Channel: production
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
- EAS Update must be configured (`expo-updates` installed, `updates.url` set)
- Build failure blocks next Phase
- Build URL must be recorded on success
