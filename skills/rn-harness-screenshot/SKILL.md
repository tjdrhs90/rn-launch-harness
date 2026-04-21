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

`docs/harness/store-assets/metadata/ko-KR/subtitle.txt` (iOS only):
```
[부제] (30 chars max)
```

`docs/harness/store-assets/metadata/ko-KR/short_description.txt` (Android):
```
[짧은 설명] (80 chars max)
```

`docs/harness/store-assets/metadata/ko-KR/full_description.txt`:
```
[전체 설명] (4000 chars max, includes key features, value proposition)
```

`docs/harness/store-assets/metadata/ko-KR/keywords.txt` (iOS only):

**CRITICAL**: iOS App Store keywords field has a **100-character limit INCLUDING commas**. This field is one of the most important ASO (App Store Optimization) factors. **Fill it to the MAXIMUM — generate keywords until the total exceeds 100 characters, then trim down.**

Rules:
- Comma-separated, NO spaces after commas (to save characters)
- Do NOT include the app name (already indexed)
- Do NOT include the app category name (already indexed)
- Do NOT duplicate words from the title/subtitle
- Each word counts individually — "커피,구독,가계부" searches for each separately
- Mix Korean + English keywords for broader reach
- Prefer single words over phrases (unless phrase is a common search term)

Process:
1. Generate 20-30 candidate keywords from app features/target users/synonyms
2. Join with commas (no spaces): `k1,k2,k3,...`
3. Count total characters
4. If < 100: add MORE keywords (synonyms, English variants, related concepts)
5. If > 100: trim least relevant keywords
6. **Target: 95-100 characters** (use the full budget, leave 0-5 char safety margin)

Example (coffee subscription tracker app):
```
구독관리,커피,정기배송,지출관리,가계부,알림,통계,지출분석,예산,subscription,coffee,tracker,monthly,bill,reminder,budget,spending
```
Count: 97 characters ✓ (uses full budget)

Bad example (too short):
```
커피,구독,관리
```
Count: 9 characters ✗ (wastes 91 characters of search opportunity)

`docs/harness/store-assets/metadata/ko-KR/release_notes.txt`:
```
[출시 노트]
```

`docs/harness/store-assets/metadata/ko-KR/screenshot_captions.md`:

**Screenshot caption copy** for store listings. These are the short marketing headlines overlaid on each screenshot. Written based on what each screenshot actually shows. 5-8 captions, matched 1:1 with the captured screenshot order.

Rules:
- **Headline**: 1 line, 15-25 characters (mobile-readable at small thumbnail size)
- **Subheadline**: 1 line, 25-40 characters (supporting detail)
- First caption = brand/value proposition (splash/logo context)
- Middle captions = one feature per screenshot, benefit-focused not feature-focused
- Last caption = aspirational / call to action
- Korean uses shorter phrases (15-20 chars); English 20-30
- Use emoji sparingly (0-1 per caption) for scannability
- Match the screenshot order from Step 1

Format template:

```markdown
# Screenshot Captions — [App Name]

## 01 — First screen (splash / login / onboarding)
**Headline:** 하루 한 번, 돈 관리
**Subheadline:** 3초 가계부로 충분해요
**Matches:** docs/harness/store-assets/ios/01-first.png

## 02 — Home / main screen
**Headline:** 이번 달 얼마 썼지?
**Subheadline:** 카테고리별 지출 한눈에 보기
**Matches:** docs/harness/store-assets/ios/02-home.png

## 03 — Core feature (ex: quick entry)
**Headline:** 손가락 한 번으로 기록
**Subheadline:** 커피 한 잔, 택시비, 바로 입력
**Matches:** docs/harness/store-assets/ios/03-feature.png

## 04 — Secondary feature (ex: statistics)
**Headline:** 내 소비 패턴이 보여요
**Subheadline:** 주간·월간 리포트 자동 생성
**Matches:** docs/harness/store-assets/ios/04-detail.png

## 05 — Last screen (premium / settings / achievement)
**Headline:** 목표 달성까지 D-23
**Subheadline:** 매일 알림으로 잊지 않기
**Matches:** docs/harness/store-assets/ios/05-profile.png
```

Process:
1. Read PRD for feature priorities and value proposition
2. For each screenshot captured (Step 1 list), write a caption
3. Headline emphasizes **user benefit** (not feature name)
   - Bad: "Charts screen" / "차트 화면"
   - Good: "See where your money goes" / "내 소비 패턴이 보여요"
4. Subheadline adds specific detail
5. Save the file, then the user can use it with Figma/Canva/Sketch to overlay text on screenshots

**Why this matters:** Screenshots on the store are viewed at thumbnail size. A user scrolling decides to install in 2-3 seconds based on these captions. A screenshot without a clear headline wastes that opportunity.

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
- [ ] Screenshot captions match what's actually on screen (screenshot_captions.md)
- [ ] iOS keywords.txt uses 95-100 chars

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
- **iOS keywords.txt MUST use 95-100 characters** (total length including commas). Under-utilizing this field hurts ASO. Generate extra keywords if short, trim if over 100.
- **screenshot_captions.md MUST include one caption per screenshot**, with headline + subheadline, matched to the actual on-screen content. Benefit-focused, not feature-focused.
