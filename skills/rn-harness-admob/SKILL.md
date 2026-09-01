---
name: rn-harness-admob
description: Phase 7 — Smart AdMob ad placement analysis and integration. Guides user through manual ad unit creation.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

# rn-harness-admob — Phase 7: AdMob Integration

Integrate AdMob ads into the app. Analyze the app to determine the best ad strategy, then guide the user through manual ad unit creation and inject code automatically.

## Trigger

Called by the orchestrator as Phase 7.

## Input

- `docs/harness/plans/YYYY-MM-DD-prd.md` (PRD with ad placement strategy)
- `docs/harness/config.md` (AdMob settings)
- Actual project code (screens, navigation structure)

## Process

### Step 0: Skip Check

If `config.md` has `admob.enabled: false` → skip this phase entirely.

### Step 1: Analyze App for Ad Strategy

Read the actual project code to understand:
- **Screen count and types**: How many screens? Which are content-heavy vs action-heavy?
- **User flow**: What are the main navigation paths?
- **Content type**: List-based? Tool/utility? Media? Social?
- **Session pattern**: Quick in-and-out? Or long sessions?

Based on analysis, determine the optimal ad mix:

#### Banner Ads — DEFAULT: ALL SCREENS (unless excluded)

Banners go on **every screen** except where they harm UX:

**Include (banner on):**
- Home / main feed
- List screens
- Detail / content screens
- Profile / settings
- Search / explore
- Any screen where user spends time reading/browsing

**Exclude (no banner):**
- Login / signup / onboarding (first impression matters)
- Full-screen media playback (video, camera)
- Payment / checkout flow
- Modal dialogs
- Screens with keyboard-heavy input (forms with many fields)

Banner placement: **Bottom of SafeAreaView, above tab bar** (if tabs exist) or at screen bottom.

#### Interstitial Ads — Context-Aware Placement

Analyze navigation patterns and place interstitials at **natural transition points**:

| App Type | Best Interstitial Triggers |
|----------|---------------------------|
| **Content/News** | After reading 3+ articles, on back navigation from detail |
| **Utility/Tool** | After completing a task (save, export, convert) |
| **List/Directory** | After viewing 5+ detail pages in a session |
| **Game** | Between levels, after game over |
| **Social** | NOT recommended (disrupts social flow) |
| **E-commerce** | After adding to cart (NOT during checkout) |

**Frequency cap**: Max 1 interstitial per 3 minutes to avoid user annoyance.

#### Rewarded Ads — Value Exchange

Only add rewarded ads if the app has a clear value to offer:

| Scenario | Reward |
|----------|--------|
| Premium feature unlock (temporary) | 24h access to premium feature |
| Remove ads (temporary) | 1h ad-free experience |
| Extra content | Unlock bonus content/article |
| Tool usage limit | Extra uses of a limited feature |
| In-app currency | Bonus coins/points |

If no natural reward fits → **skip rewarded ads** (don't force them).

#### App Open Ads — Optional

Consider app open ads if:
- App has frequent cold starts (utility apps)
- Users return multiple times per day
- NOT for apps where quick access matters (timer, calculator)

If added: Show on cold start only, NOT on resume from background. Max 1 per 30 minutes.

### Step 2: Generate Ad Unit List

Based on analysis, create the specific list:

```markdown
## Required Ad Units

Based on app analysis: [App Type] with [N] screens

### Banner Ads (on [X]/[N] screens)
| Name | Placement |
|------|-----------|
| banner_home | Home tab bottom |
| banner_list | List screen bottom |
| banner_detail | Detail screen bottom |
| banner_profile | Profile screen bottom |
| banner_search | Search screen bottom |

### Interstitial (triggered at [context])
| Name | Trigger |
|------|---------|
| interstitial_transition | [specific trigger based on analysis] |

### Rewarded (if applicable)
| Name | Reward |
|------|--------|
| rewarded_premium | [specific reward] |

### Excluded Screens (no ads)
- login / signup (onboarding flow)
- [other excluded screens with reasons]
```

### Step 3: User Confirmation

AskUserQuestion:
```
Based on your app's structure, here's the recommended ad strategy:

BANNER ADS (on X/Y screens):
  [list of screens with banners]

INTERSTITIAL:
  [trigger description]

REWARDED:
  [reward description, or "Not recommended for this app type"]

EXCLUDED (no ads):
  [list with reasons]

Options:
1. Accept this strategy (recommended)
2. Modify — tell me what to change
3. Minimal — banners only, no interstitial/rewarded
4. Maximum — add all ad types everywhere possible

Which option? (1/2/3/4)
```

### Step 4: Manual Ad Unit Creation Guide

AskUserQuestion:
```
AdMob API does not support ad unit creation — you need to create them manually.

1. Go to https://apps.admob.com
2. Add your app (iOS + Android)
3. Create these ad units:

   iOS App:
   [list from Step 2]

   Android App:
   [same list]

4. Enter the Ad Unit IDs in this format:

   iOS App ID: ca-app-pub-XXXX~YYYY
   Android App ID: ca-app-pub-XXXX~ZZZZ

   [For each ad unit:]
   iOS [name]: ca-app-pub-XXXX/YYYY
   Android [name]: ca-app-pub-XXXX/ZZZZ

Type "skip" to use Google test ad IDs for now (replace before release).
```

### Step 5: Ad Unit ID Handling

**If user provides IDs:**
- Save to `docs/harness/config.md` `admob.ad_units`
- Insert real Ad Unit IDs into code

**If user types "skip":**
- Use Google test ad IDs:
  - iOS Banner: `ca-app-pub-3940256099942544/2435281174`
  - Android Banner: `ca-app-pub-3940256099942544/9214589741`
  - iOS Interstitial: `ca-app-pub-3940256099942544/4411468910`
  - Android Interstitial: `ca-app-pub-3940256099942544/1033173712`
  - iOS Rewarded: `ca-app-pub-3940256099942544/1712485313`
  - Android Rewarded: `ca-app-pub-3940256099942544/5224354917`
  - iOS App Open: `ca-app-pub-3940256099942544/5575463023`
  - Android App Open: `ca-app-pub-3940256099942544/9257395921`
- Implement `__DEV__` conditional for test/production ID switching

### Step 5.5: iOS SKAdNetwork Identifiers (ad attribution)

iOS 14+ attributes ad-driven installs via **SKAdNetwork**. If the network IDs aren't in `Info.plist`, iOS ad-revenue attribution and reporting are degraded — the app still runs and ads still show, but you lose install attribution. Google provides an **advised list** and the `react-native-google-mobile-ads` config plugin injects it via the `skAdNetworkItems` option.

1. Fetch the **current** advised identifiers (the list changes over time):
   https://developers.google.com/admob/ios/3p-skadnetworks
2. Populate `skAdNetworkItems` in the `react-native-google-mobile-ads` plugin block of `app.config.ts` (see generator scaffold). At minimum keep Google's own `cstr6suwn9.skadnetwork`; add the rest of the advised third-party IDs.
3. After `expo prebuild` (Phase 8), verify they landed:
   ```bash
   /usr/libexec/PlistBuddy -c "Print :SKAdNetworkItems" ios/*/Info.plist | head
   ```

> Do NOT hardcode a stale list permanently — refresh from Google's page around each release.

### Step 6: Implement Ad Code

#### 6a-prereq. UMP (User Messaging Platform) — REQUIRED for EU/UK users

Google requires consent collection (GDPR/ePrivacy) before showing personalized ads to users in the EU/UK/Switzerland. **Without UMP, your AdMob account can be flagged or revenue restricted.**

`react-native-google-mobile-ads` includes UMP support via `AdsConsent`. Implementation:

**Step 1**: Configure consent form in AdMob console (one-time, manual):
- Go to https://apps.admob.com → Privacy & messaging → GDPR
- Create a GDPR message
- Select "User consent (paid + unpaid)" mode
- Publish to all your apps

**Step 2**: Implement consent flow on app start.

`src/features/ads/lib/init-ads.ts`:
```typescript
import mobileAds, {
  AdsConsent,
  AdsConsentStatus,
  AdsConsentDebugGeography,
} from 'react-native-google-mobile-ads';

let started = false;

export async function initializeAds(): Promise<void> {
  // 두 번 들어오면 폼이 떠 있는 동안 ATT 가 뜬다. 한 번만 돌게 막는다.
  if (started) return;
  started = true;

  // 1. Request UMP consent info update
  const consentInfo = await AdsConsent.requestInfoUpdate({
    // For testing in non-EU regions, simulate EU geography:
    debugGeography: __DEV__
      ? AdsConsentDebugGeography.EEA
      : AdsConsentDebugGeography.DISABLED,
    testDeviceIdentifiers: __DEV__ ? ['EMULATOR'] : [],
  });

  // 2. Show consent form if required — this must finish before ATT
  if (
    consentInfo.isConsentFormAvailable &&
    consentInfo.status === AdsConsentStatus.REQUIRED
  ) {
    await AdsConsent.showForm();
  }

  // 3. iOS ATT — only after the consent form is gone.
  //    AdMob 의 ATT 안내 메시지가 "다음 화면에서 '허용'을 탭하세요" 라고
  //    말하므로 순서가 뒤집히면 안내가 무의미해진다.
  //    ATT 얼럿은 앱이 active 일 때만 뜬다. 아직이면 한 번만 기다린다.
  if (Platform.OS === 'ios') {
    await whenActive();
    await requestTrackingPermissionsAsync();
  }

  // 4. Check final consent status
  const { canRequestAds } = await AdsConsent.getConsentInfo();

  // 5. Initialize Mobile Ads SDK only after consent is resolved
  if (canRequestAds) {
    await mobileAds().initialize();
  }
}

/** 앱이 foreground 로 올라올 때까지 기다린다. 이미 active 면 즉시 반환. */
function whenActive(): Promise<void> {
  if (AppState.currentState === 'active') return Promise.resolve();
  return new Promise((resolve) => {
    const sub = AppState.addEventListener('change', (state) => {
      if (state === 'active') {
        sub.remove();
        resolve();
      }
    });
  });
}
```

임포트에 다음이 필요하다:

```typescript
import { AppState, Platform } from 'react-native';
import { requestTrackingPermissionsAsync } from 'expo-tracking-transparency';
```

**Step 3**: Call `initializeAds()` once at app startup. ATT 는 이 함수 안에서
동의 폼 뒤에 이어서 요청한다 — **별도의 ATT 훅이나 타이머를 두지 않는다.**

`app/_layout.tsx` (Root layout):
```typescript
import { useEffect } from 'react';
import { initializeAds } from '@features/ads';

export default function RootLayout() {
  // UMP 동의 → (iOS) ATT → SDK 초기화. 순서가 이 함수 안에서 보장된다.
  useEffect(() => {
    void initializeAds().catch(console.warn);
  }, []);

  // ...
}
```

> **왜 타이머를 쓰지 않나.** 전에는 ATT 를 2초, UMP 를 2.5초 타이머로 띄웠다.
> 순서를 시간에 맡기면 경쟁이 된다 — ATT 얼럿이 조금만 늦어도 UMP 폼이 그
> 위에 겹쳐 두 개가 한꺼번에 뜬다. 실제로 출시된 앱에서 그렇게 나갔다
> (2026-08, 51개 앱 점검). 콜백으로 이어 붙이면 시간과 무관하게 순서가 선다.

**Step 4**: Allow users to revisit consent (Settings screen):
```typescript
// "Manage privacy preferences" button in settings
import { AdsConsent } from 'react-native-google-mobile-ads';

const handlePrivacyOptions = async () => {
  await AdsConsent.showPrivacyOptionsForm();
};
```

Required by Google: A user-accessible "manage privacy" option must exist in the app for users who already consented to be able to change their choice later.

**Step 5**: Update ad request based on consent.

When consent is denied for personalized ads, request non-personalized only:
```typescript
// In AdBanner.tsx, useInterstitial.ts, etc.
const { canRequestAds, status } = await AdsConsent.getConsentInfo();
const requestNonPersonalizedAdsOnly = status !== AdsConsentStatus.OBTAINED;

<BannerAd
  unitId={getAdUnitId('BANNER')}
  size={size}
  requestOptions={{ requestNonPersonalizedAdsOnly }}
/>
```

#### 6a. Ad Config

`src/shared/config/ads.ts`:
```typescript
import { Platform } from 'react-native';

const TEST_IDS = {
  BANNER: Platform.select({
    ios: 'ca-app-pub-3940256099942544/2435281174',
    android: 'ca-app-pub-3940256099942544/9214589741',
  }) ?? '',
  INTERSTITIAL: Platform.select({
    ios: 'ca-app-pub-3940256099942544/4411468910',
    android: 'ca-app-pub-3940256099942544/1033173712',
  }) ?? '',
  REWARDED: Platform.select({
    ios: 'ca-app-pub-3940256099942544/1712485313',
    android: 'ca-app-pub-3940256099942544/5224354917',
  }) ?? '',
  APP_OPEN: Platform.select({
    ios: 'ca-app-pub-3940256099942544/5575463023',
    android: 'ca-app-pub-3940256099942544/9257395921',
  }) ?? '',
};

const PRODUCTION_IDS = {
  BANNER: Platform.select({ ios: '...', android: '...' }) ?? '',
  INTERSTITIAL: Platform.select({ ios: '...', android: '...' }) ?? '',
  REWARDED: Platform.select({ ios: '...', android: '...' }) ?? '',
  APP_OPEN: Platform.select({ ios: '...', android: '...' }) ?? '',
};

export type TAdUnitKey = keyof typeof TEST_IDS;

export const getAdUnitId = (key: TAdUnitKey): string => {
  return __DEV__ ? TEST_IDS[key] : PRODUCTION_IDS[key];
};

// Hide all ads (for store screenshots)
export const isAdsHidden = (): boolean => {
  return process.env.EXPO_PUBLIC_HIDE_ADS === 'true';
};

// Interstitial frequency cap (ms)
export const INTERSTITIAL_MIN_INTERVAL = 3 * 60 * 1000; // 3 minutes
```

#### 6b. Ad Feature Module (FSD)

```
src/features/ads/
├── ui/
│   └── AdBanner.tsx              # Reusable banner (handles bottom safe area internally)
├── hooks/
│   ├── use-interstitial.ts       # Interstitial with frequency cap
│   ├── use-rewarded.ts           # Rewarded with callback
│   └── use-app-open-ad.ts        # App open ad (if applicable)
├── lib/
│   └── init-ads.ts               # UMP consent flow + mobileAds initialization
├── store/
│   └── ads.store.ts              # Ad state (last shown time, rewards)
├── types/
│   └── ads.types.ts
└── index.ts                      # barrel export
```

#### 6c. AdBanner Component (anchored to bottom edge — no gap)

**Common bug**: wrapping the banner inside `<SafeAreaView>` adds a bottom safe-area inset between the banner and the screen edge, leaving a visible gap above the home indicator. The correct pattern is for the banner component itself to consume the bottom safe area, so the banner sits flush against the home indicator with no gap.

```typescript
// src/features/ads/ui/AdBanner.tsx
import { View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { BannerAd, BannerAdSize } from 'react-native-google-mobile-ads';
import { getAdUnitId, isAdsHidden } from '@shared/config/ads';

interface IAdBannerProps {
  size?: BannerAdSize;
}

export function AdBanner({ size = BannerAdSize.ANCHORED_ADAPTIVE_BANNER }: IAdBannerProps) {
  // Hidden during store screenshot capture (EXPO_PUBLIC_HIDE_ADS=true)
  if (isAdsHidden()) return null;

  const insets = useSafeAreaInsets();

  return (
    <View style={{ paddingBottom: insets.bottom, backgroundColor: '#000' }}>
      <BannerAd
        unitId={getAdUnitId('BANNER')}
        size={size}
        requestOptions={{ requestNonPersonalizedAdsOnly: true }}
      />
    </View>
  );
}
```

Why this works:
- The banner itself sits flush against the bottom (no visual gap)
- The `paddingBottom: insets.bottom` puts a black strip BELOW the banner that fills the home indicator area
- Banner content stays touchable; nothing overlaps the system UI
- `backgroundColor: '#000'` blends with status/home indicator on dark theme; use `theme.background` for adaptive theming

#### 6d. Interstitial Hook (with frequency cap)

```typescript
// src/features/ads/hooks/use-interstitial.ts
import { useCallback, useRef } from 'react';
import { InterstitialAd, AdEventType } from 'react-native-google-mobile-ads';
import { getAdUnitId, INTERSTITIAL_MIN_INTERVAL } from '@shared/config/ads';

export function useInterstitial() {
  const lastShownRef = useRef<number>(0);
  const adRef = useRef(InterstitialAd.createForAdRequest(getAdUnitId('INTERSTITIAL')));

  const show = useCallback(async () => {
    const now = Date.now();
    if (now - lastShownRef.current < INTERSTITIAL_MIN_INTERVAL) return false;

    return new Promise<boolean>((resolve) => {
      const ad = InterstitialAd.createForAdRequest(getAdUnitId('INTERSTITIAL'));
      ad.addAdEventListener(AdEventType.LOADED, () => {
        ad.show();
        lastShownRef.current = Date.now();
        resolve(true);
      });
      ad.addAdEventListener(AdEventType.ERROR, () => resolve(false));
      ad.load();
    });
  }, []);

  return { show };
}
```

#### 6e. Place Ads in Screens

For **every screen with banner** (from Step 2):

**CORRECT pattern** (no gap between banner and screen edge):
```tsx
<View className="flex-1 bg-background">
  <SafeAreaView edges={['top', 'left', 'right']} className="flex-1">
    <ScrollView className="flex-1">
      {/* Screen content */}
    </ScrollView>
  </SafeAreaView>
  {/* AdBanner handles its own bottom safe area internally */}
  <AdBanner />
</View>
```

**WRONG pattern** (causes the gap users complain about):
```tsx
<SafeAreaView className="flex-1 bg-background">
  <ScrollView className="flex-1">
    {/* content */}
  </ScrollView>
  <AdBanner />  {/* ← Banner is INSIDE SafeAreaView, gets pushed up by bottom inset */}
</SafeAreaView>
```

Key difference:
- Use `<View>` as the outer container, not `<SafeAreaView>`
- SafeAreaView wraps ONLY the content area with `edges={['top', 'left', 'right']}` (no bottom)
- AdBanner sits at the very bottom; its internal `paddingBottom: insets.bottom` handles the home indicator
- This makes the ad flush against the visible screen edge with no white gap

For **interstitial triggers**:
```tsx
const { show: showInterstitial } = useInterstitial();

const handleNavigateBack = () => {
  showInterstitial(); // Fire-and-forget, respects frequency cap
  navigation.goBack();
};
```

For **rewarded**:
```tsx
const { show: showRewarded } = useRewarded({
  onRewarded: () => {
    // Grant reward
  },
});
```

### Step 7: Verify

```bash
npm run typecheck  # No AdMob type errors
npm run lint       # No errors
```

Git commit:
```bash
git add .
git commit -m "feat: integrate AdMob ads with smart placement strategy"
```

## Output

`docs/harness/handoff/admob-setup.md`:

```markdown
# AdMob Integration Report

## Ad Strategy
- App Type: [analyzed type]
- Banner Screens: [X]/[Y] screens
- Interstitial: [trigger description]
- Rewarded: [reward or "skipped"]
- App Open: [yes/no]

## Ad Units
| Name | Format | iOS ID | Android ID | Status |
|------|--------|--------|------------|--------|
| banner | Banner | ... | ... | [real/test] |
| interstitial | Interstitial | ... | ... | [real/test] |
| rewarded | Rewarded | ... | ... | [real/test] |

## Excluded Screens
| Screen | Reason |
|--------|--------|
| login | Onboarding flow |
| signup | Onboarding flow |

## Files Created/Modified
- src/shared/config/ads.ts
- src/features/ads/**
- app.config.ts
- [Modified screen files]

## Notes
[If using test IDs: Replace before release]
```

## State Update

```yaml
current_phase: acceptance
next_role: rn-harness-acceptance   # Phase 7.5 human gate before build (skip handled inside that skill if skip_acceptance)
```

## HARD GATES

- `react-native-google-mobile-ads` must be installed
- `app.config.ts` must have AdMob plugin config
- iOS `skAdNetworkItems` populated from Google's advised list (SKAdNetwork attribution) — verify in `Info.plist` after prebuild
- Test/production ID switching logic required (`__DEV__` conditional)
- All ad code must follow FSD structure (`features/ads/`)
- Banner on ALL screens except explicitly excluded ones
- Interstitial frequency cap (min 3 minutes) MANDATORY
- No ads on login/signup/onboarding screens
- No ads on payment/checkout screens
- **AdBanner uses `useSafeAreaInsets` internally for bottom padding** (no gap between ad and screen edge)
- **Outer container is `<View>` not `<SafeAreaView>`** when AdBanner is at the bottom
- SafeAreaView wraps content with `edges={['top', 'left', 'right']}` only — bottom is handled by AdBanner
- **UMP consent flow MANDATORY** (`AdsConsent.requestInfoUpdate` → `AdsConsent.showForm` → `mobileAds().initialize()`)
- **AdMob console must have a published GDPR message** (manual one-time setup)
- Privacy options entry point in app settings (`AdsConsent.showPrivacyOptionsForm`)
- `mobileAds().initialize()` MUST NOT be called before `AdsConsent.requestInfoUpdate` resolves
