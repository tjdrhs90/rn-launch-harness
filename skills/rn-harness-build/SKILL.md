# rn-harness-build — Phase 7: EAS Build

EAS Build로 iOS/Android 바이너리를 빌드한다.

## Trigger

오케스트레이터에서 Phase 7로 호출됨.

## Input

- 실제 프로젝트 코드 (AdMob 통합 완료)
- `docs/harness/config.md`

## Prerequisites

사용자 환경에 필요:
- `eas-cli` 설치 (`npm install -g eas-cli`)
- Expo 계정 로그인 (`eas login`)
- `eas.json` 빌드 프로필 설정

## Process

### Step 1: EAS 설정 확인

`eas.json` 존재 여부 확인. 없으면 생성:

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
      "autoIncrement": true
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

### Step 2: app.config.ts 확인

필수 설정 검증:
- `name`, `slug`, `version`
- `ios.bundleIdentifier`
- `android.package`
- `android.versionCode`
- AdMob 플러그인 설정

### Step 3: 로컬 빌드 테스트 (선택)

```bash
# 로컬에서 먼저 빌드 에러 확인 (시간 절약)
eas build --local --platform ios --profile preview
eas build --local --platform android --profile preview
```

에러 발생 시 수정 후 재시도.

### Step 4: 클라우드 빌드

```bash
# iOS 프로덕션 빌드
eas build --platform ios --profile production --non-interactive

# Android 프로덕션 빌드
eas build --platform android --profile production --non-interactive
```

빌드 완료 대기. 빌드 URL 기록.

### Step 5: 빌드 결과 확인

```bash
eas build:list --limit 2
```

빌드 성공 여부 확인.
- 성공 → 다음 Step
- 실패 → 에러 분석 → 수정 → 재빌드

### Step 6: 빌드 아티팩트 기록

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

## Build Config
- bundleIdentifier: com.xxx.xxx
- package: com.xxx.xxx
- version: 1.0.0
- buildNumber/versionCode: 1
```

Git commit:
```bash
git add eas.json app.config.ts
git commit -m "chore: configure EAS build profiles"
```

## State Update

```yaml
current_phase: screenshot
next_role: rn-harness-screenshot
```

## HARD GATES

- `eas.json` 존재 필수
- `app.config.ts`에 bundleIdentifier/package 설정 필수
- 빌드 실패 시 다음 Phase 진행 금지
- 빌드 성공 후 Build URL 기록 필수
