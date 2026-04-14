---
name: rn-harness-screenshot
description: Phase 9 — Automated store screenshots via Maestro on real simulator/emulator. Hides ads during capture.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

# rn-harness-screenshot — Phase 9: Store Screenshots

Capture store screenshots by running the app on a real simulator/emulator with Maestro. Ads are hidden during capture via environment variable.

## How It Works

**This is NOT image generation.** Maestro physically controls the simulator:
1. Launches the app on a real iOS Simulator or Android Emulator
2. Taps buttons, scrolls, navigates between screens
3. Takes PNG screenshots at each screen
4. You can watch it happen live on the simulator

## Trigger

Called by the orchestrator as Phase 9.

## Input

- `docs/harness/plans/YYYY-MM-DD-prd.md` (screen structure)
- Actual project code
- Development build installed on simulator/emulator

## Prerequisites

- Maestro CLI (`curl -Ls "https://get.maestro.mobile.dev" | bash`)
- iOS Simulator or Android Emulator running
- Development build installed (from Phase 8)

## Process

### Step 0: Hide Ads for Screenshots

**Store screenshots must NOT show ads.** Before capturing, ensure the ad-hiding mechanism is in place.

#### 0a. Verify AdBanner has EXPO_PUBLIC_HIDE_ADS support

Check `src/features/ads/ui/AdBanner.tsx`:
```typescript
export function AdBanner({ size = BannerAdSize.ANCHORED_ADAPTIVE_BANNER }: IAdBannerProps) {
  // Hide ads during screenshot capture
  if (process.env.EXPO_PUBLIC_HIDE_ADS === 'true') return null;
  
  return (
    <BannerAd
      unitId={getAdUnitId('BANNER')}
      size={size}
      requestOptions={{ requestNonPersonalizedAdsOnly: true }}
    />
  );
}
```

If not present, add the `EXPO_PUBLIC_HIDE_ADS` check to:
- `AdBanner.tsx` — banner component
- `use-interstitial.ts` — interstitial hook (skip `show()`)
- `use-rewarded.ts` — rewarded hook (skip `show()`)
- `use-app-open-ad.ts` — app open ad hook (skip)

#### 0b. Start app with ads hidden

```bash
EXPO_PUBLIC_HIDE_ADS=true npx expo start --dev-client
```

Or if using `expo run:*`:
```bash
EXPO_PUBLIC_HIDE_ADS=true npx expo run:ios
EXPO_PUBLIC_HIDE_ADS=true npx expo run:android
```

### Step 1: Choose Screenshot Screens

Select 5-8 key screens from PRD for store listing:
1. Onboarding / Login (or splash)
2. Main home screen
3. Core feature 1
4. Core feature 2
5. Search / explore
6. Profile / settings
7. (Optional) Dark mode
8. (Optional) Unique/differentiating feature

### Step 2: Environment Detection

```bash
# Check Maestro
which maestro && echo "MAESTRO=yes" || echo "MAESTRO=no"

# Check running simulators
xcrun simctl list devices 2>/dev/null | grep "Booted" || true
adb devices 2>/dev/null | grep -v "List" | grep "device" || true
```

**If Maestro is NOT available:**
→ Skip to Step 6 (Manual Fallback)

### Step 3: Write Maestro Flow

`maestro/screenshots.yaml`:
```yaml
appId: com.company.app
---
# Wait for app to fully load
- waitForAnimationToEnd

# 1. First screen (login/onboarding/home)
- takeScreenshot: docs/harness/store-assets/ios/01-first

# 2. Navigate to home (if login needed, use test account)
- tapOn: "Home"
- waitForAnimationToEnd
- takeScreenshot: docs/harness/store-assets/ios/02-home

# 3. Core feature
- tapOn: "[Feature Button]"
- waitForAnimationToEnd
- takeScreenshot: docs/harness/store-assets/ios/03-feature

# 4. Detail screen
- tapOn:
    index: 0
- waitForAnimationToEnd
- takeScreenshot: docs/harness/store-assets/ios/04-detail

# 5. Profile
- tapOn: "Profile"
- waitForAnimationToEnd
- takeScreenshot: docs/harness/store-assets/ios/05-profile
```

**Customize the flow** based on actual app screens and navigation. Use `assertVisible` to verify correct screen before capturing.

### Step 4: Capture Screenshots

#### iOS (App Store requirements)

```bash
# iPhone 6.7" (Required — iPhone 15 Pro Max / iPhone 16 Pro Max)
maestro --device "iPhone 15 Pro Max" test maestro/screenshots.yaml

# iPhone 6.5" (Required — iPhone 11 Pro Max)
# Reuse 6.7" screenshots if similar resolution
```

**iPad screenshots NOT needed** (supportsTablet: false in app.config.ts).

#### Android (Google Play requirements)

```bash
# Phone (Required)
maestro test maestro/screenshots.yaml
```

### Step 5: Organize Screenshots

```
docs/harness/store-assets/
├── ios/
│   ├── 01-first.png
│   ├── 02-home.png
│   ├── 03-feature.png
│   ├── 04-detail.png
│   └── 05-profile.png
├── android/
│   └── phone/
│       ├── 01-first.png
│       ├── 02-home.png
│       └── ...
├── icon.png              # 512x512 (for Google Play)
├── feature_graphic.png   # 1024x500 (for Google Play)
└── metadata/
    └── ko-KR/
        ├── title.txt
        ├── short_description.txt
        ├── full_description.txt
        └── release_notes.txt
```

### Step 6: Manual Fallback (No Maestro)

If Maestro is not installed:

AskUserQuestion:
```
Maestro is not installed, so automatic screenshot capture is unavailable.

Please capture screenshots manually:
1. Run the app: EXPO_PUBLIC_HIDE_ADS=true npx expo start --dev-client
2. Navigate to each key screen
3. Take screenshots (Cmd+S in iOS Simulator, or device screenshot)
4. Save to docs/harness/store-assets/ios/ and android/phone/

Screens to capture:
  1. [screen 1]
  2. [screen 2]
  ...

Or install Maestro to automate:
  curl -Ls "https://get.maestro.mobile.dev" | bash

Press Enter when screenshots are ready, or type "install" to install Maestro.
```

### Step 7: Generate Store Metadata

Create metadata files from PRD:

`docs/harness/store-assets/metadata/ko-KR/title.txt`:
```
[앱 이름] (30 chars max)
```

`docs/harness/store-assets/metadata/ko-KR/short_description.txt`:
```
[짧은 설명] (80 chars max)
```

`docs/harness/store-assets/metadata/ko-KR/full_description.txt`:
```
[전체 설명] (4000 chars max, includes key features, value proposition)
```

`docs/harness/store-assets/metadata/ko-KR/release_notes.txt`:
```
[출시 노트]
```

### Step 8: User Review

AskUserQuestion:
```
Screenshots and metadata are ready. Please review:

Screenshots: docs/harness/store-assets/
Metadata: docs/harness/store-assets/metadata/ko-KR/

Checklist:
- [ ] Screenshots look clean (no ads visible)
- [ ] App name correct
- [ ] Description accurate
- [ ] Privacy policy URL: [URL from config]

Any changes needed? (Press Enter to proceed, or describe what to change)
```

## Output

- `docs/harness/store-assets/` — screenshots + metadata
- `maestro/screenshots.yaml` — Maestro flow

## State Update

```yaml
current_phase: submit
next_role: rn-harness-submit
```

## HARD GATES

- Minimum 5 screenshots
- iOS 6.7" screenshots required (if on macOS)
- Metadata files (title, descriptions) required
- Privacy policy URL required (from config.md)
- **Ads MUST be hidden** during screenshot capture (EXPO_PUBLIC_HIDE_ADS=true)
- If Maestro unavailable → manual fallback with clear instructions
- Screenshots must be reviewed by user before proceeding to submission
