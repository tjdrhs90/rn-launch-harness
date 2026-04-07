# harness-admob — Phase 6: AdMob 통합

AdMob 광고를 앱에 통합한다. 광고 단위는 API로 생성 불가하므로 사용자에게 수동 생성을 안내하고, Ad Unit ID를 받아 코드에 삽입한다.

## Trigger

오케스트레이터에서 Phase 6으로 호출됨.

## Input

- `docs/harness/plans/YYYY-MM-DD-prd.md` (광고 배치 전략)
- `docs/harness/config.md` (AdMob 설정)
- 실제 프로젝트 코드

## Process

### Step 0: AdMob 스킵 확인

`config.md`에서 `admob.enabled: false`이면 이 Phase 건너뛰기.

### Step 1: 필요한 광고 단위 목록 생성

PRD의 광고 배치 전략을 기반으로 필요한 광고 단위 정리:

```markdown
## 필요한 광고 단위

### iOS (ca-app-pub-XXXX~YYYY)
| 이름 | 형식 | 배치 위치 |
|------|------|----------|
| home_banner | 배너 | 홈 탭 하단 |
| list_native | 네이티브 | 리스트 5번째 아이템마다 |
| screen_interstitial | 전면 | 상세→목록 복귀 시 |
| reward_premium | 리워드 | 프리미엄 기능 해제 |

### Android (ca-app-pub-XXXX~ZZZZ)
| 이름 | 형식 | 배치 위치 |
|------|------|----------|
| (동일 구조) |
```

### Step 2: 사용자에게 수동 생성 안내

AskUserQuestion으로 안내:

```
AdMob API는 광고 단위 생성을 지원하지 않아 수동으로 만들어야 합니다.

1. https://apps.admob.com 접속
2. 앱 추가 (iOS + Android)
3. 아래 광고 단위를 생성해주세요:

   iOS 앱:
   - home_banner (배너)
   - list_native (네이티브)
   - screen_interstitial (전면)
   - reward_premium (리워드)

   Android 앱:
   - (동일)

4. 생성된 Ad Unit ID를 아래 형식으로 입력해주세요:

   iOS App ID: ca-app-pub-XXXX~YYYY
   Android App ID: ca-app-pub-XXXX~ZZZZ

   iOS home_banner: ca-app-pub-XXXX/YYYY
   iOS screen_interstitial: ca-app-pub-XXXX/YYYY
   iOS reward_premium: ca-app-pub-XXXX/YYYY

   Android home_banner: ca-app-pub-XXXX/ZZZZ
   Android screen_interstitial: ca-app-pub-XXXX/ZZZZ
   Android reward_premium: ca-app-pub-XXXX/ZZZZ

아직 AdMob 계정이 없거나 나중에 하려면 "skip"을 입력하세요.
(테스트 광고 ID로 먼저 구현하고 나중에 교체할 수 있습니다.)
```

### Step 3: Ad Unit ID 처리

**사용자가 ID를 입력한 경우:**
- `docs/harness/config.md`의 `admob.ad_units`에 저장
- 코드에 실제 Ad Unit ID 삽입

**사용자가 "skip"한 경우:**
- Google 제공 테스트 광고 ID 사용:
  - iOS 배너: `ca-app-pub-3940256099942544/2435281174`
  - Android 배너: `ca-app-pub-3940256099942544/9214589741`
  - iOS 전면: `ca-app-pub-3940256099942544/4411468910`
  - Android 전면: `ca-app-pub-3940256099942544/1033173712`
  - iOS 리워드: `ca-app-pub-3940256099942544/1712485313`
  - Android 리워드: `ca-app-pub-3940256099942544/5224354917`
- 코드에 `__DEV__` 조건으로 테스트/실제 ID 분기 구현

### Step 4: AdMob 코드 구현

#### 4a. 설정 파일

`src/shared/config/ads.ts`:
```typescript
import { Platform } from 'react-native';

export const AD_UNIT_IDS = {
  BANNER_HOME: Platform.select({
    ios: 'ca-app-pub-XXXX/YYYY',
    android: 'ca-app-pub-XXXX/ZZZZ',
  }) ?? '',
  INTERSTITIAL: Platform.select({
    ios: '...',
    android: '...',
  }) ?? '',
  REWARDED: Platform.select({
    ios: '...',
    android: '...',
  }) ?? '',
};

// 테스트 모드에서는 테스트 ID 사용
export const getAdUnitId = (key: keyof typeof AD_UNIT_IDS): string => {
  if (__DEV__) {
    // Google 테스트 광고 ID
    const testIds = { ... };
    return testIds[key];
  }
  return AD_UNIT_IDS[key];
};
```

#### 4b. 앱 설정

`app.config.ts`에 AdMob 플러그인 추가:
```typescript
plugins: [
  [
    'react-native-google-mobile-ads',
    {
      androidAppId: 'ca-app-pub-XXXX~ZZZZ',
      iosAppId: 'ca-app-pub-XXXX~YYYY',
    },
  ],
],
```

#### 4c. 광고 컴포넌트

`src/features/ads/ui/AdBanner.tsx` — 배너 광고
`src/features/ads/hooks/use-interstitial.ts` — 전면 광고 hook
`src/features/ads/hooks/use-rewarded.ts` — 리워드 광고 hook
`src/features/ads/index.ts` — barrel export

#### 4d. 광고 배치

PRD에 정의된 위치에 광고 삽입:
- 홈 화면 하단: `<AdBanner />`
- 화면 전환: `useInterstitial` hook
- 프리미엄 기능: `useRewarded` hook

### Step 5: 검증

```bash
npm run typecheck  # AdMob 관련 타입 에러 없음
npm run lint       # 에러 없음
```

Git commit:
```bash
git add .
git commit -m "feat: integrate AdMob ads"
```

## Output

`docs/harness/handoff/admob-setup.md`:

```markdown
# AdMob Integration Report

## Ad Units
| Name | Format | iOS ID | Android ID | Status |
|------|--------|--------|------------|--------|
| home_banner | 배너 | ca-app-pub-... | ca-app-pub-... | [실제/테스트] |

## Files Modified
- app.config.ts
- src/shared/config/ads.ts
- src/features/ads/...

## Notes
[테스트 ID 사용 시 출시 전 교체 필요 안내]
```

## State Update

```yaml
current_phase: build
next_role: harness-build
```

## HARD GATES

- `react-native-google-mobile-ads` 설치 확인
- `app.config.ts`에 AdMob 플러그인 설정 필수
- 테스트 ID와 실제 ID 분기 로직 필수
- AdMob 관련 코드도 FSD 구조 준수 (features/ads/)
