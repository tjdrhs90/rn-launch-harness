# RN Launch Harness

React Native 모바일 앱을 **아이디어부터 스토어 출시까지** 자동화하는 Claude Code 플러그인.

한 줄 명령으로 시장 조사, 기획, 디자인, 개발, AdMob 광고 통합, EAS 빌드, 스토어 스크린샷 촬영, App Store/Google Play 심사 제출까지 전체 파이프라인을 실행합니다.

Inspired by [Anthropic's Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/rn-harness-design-long-running-apps).

## Install

```bash
claude plugins marketplace add tjdrhs90/rn-launch-harness
claude plugins install rn-launch-harness@rn-launch-harness
```

## Quick Start

```bash
# 아이디어가 있을 때
/rn-harness "일일 커피 구독 관리 앱"

# 아이디어가 없을 때 — 스토어 탑차트 조사 → 1인개발 가능한 앱 추천
/rn-harness

# 참고 사이트/이미지 포함
/rn-harness "캘린더 앱" --ref https://cal.com

# 진행 상황 확인
/rn-harness --status

# 레이트 리밋 후 재개
/rn-harness --resume
```

## Pipeline

```
/rn-harness "앱 아이디어"
    |
    v
 Phase 1: 시장 조사 (WebSearch)
    |  경쟁 앱 분석, 차별화 전략, 수익화 모델
    v
 Phase 2: 기획 (PRD)
    |  유저 스토리, Expo Router 화면 구조, FSD 모듈 맵, API 설계
    v
 Phase 3: 디자인 시스템
    |  NativeWind 테마, 컬러/타이포, 컴포넌트, Light/Dark
    v
 Phase 4: 계약 협상
    |  Generator↔Evaluator 완료 기준 합의 (15~30개 기준)
    v
 Phase 5: 빌드 & QA 루프
    |  Generator: React Native + Expo 앱 전체 빌드
    |  Evaluator: typecheck, lint, FSD 검증, UX 검증
    |  FAIL → Generator 수정 → Evaluator 재검증 (반복)
    |  PASS → 다음 Phase
    v
 Phase 6: AdMob 광고 통합
    |  광고 단위 목록 안내 → 사용자 수동 생성 → ID 입력 → 코드 삽입
    |  ATT (App Tracking Transparency) 권한 요청 포함
    v
 Phase 7: EAS Build
    |  iOS (.ipa) + Android (.aab) 프로덕션 빌드
    v
 Phase 8: 스토어 스크린샷
    |  Maestro 자동 촬영 + 메타데이터 생성
    v
 Phase 9: 스토어 제출
    |  iOS: App Store Connect API (완전 자동)
    |  Android: Play Console 수동 작업 → API 자동 (일부 수동)
    v
 DONE — 양 스토어 심사 대기
```

## Requirements

- **Claude Code** (latest)
- **Node.js** 20+
- **EAS CLI** (`npm install -g eas-cli`)
- **Maestro** (스크린샷용, 선택) — `curl -Ls "https://get.maestro.mobile.dev" | bash`
- **gh CLI** (GitHub 연동)

## Setup — 키 파일 & 환경 변수

### 1. 프로젝트 디렉토리 구조

```
my-app/
├── credentials/              # 키 파일 (git에 올라가지 않음)
│   ├── asc-api-key.p8        # App Store Connect API Key
│   └── google-play-sa.json   # Google Play Service Account
├── .env                      # 환경 변수 (git에 올라가지 않음)
├── .env.example              # 환경 변수 템플릿
└── .gitignore                # credentials/, .env 제외
```

### 2. 환경 변수 (.env)

프로젝트 루트에 `.env` 파일 생성:

```bash
# ──────────────────────────────────
# App Store Connect API (iOS 제출)
# ──────────────────────────────────
ASC_KEY_ID=XXXXXXXXXX              # API Key ID (10자리)
ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  # Issuer ID (UUID)
ASC_PRIVATE_KEY_PATH=./credentials/asc-api-key.p8   # .p8 파일 경로

# ──────────────────────────────────
# Google Play Developer API (Android 제출)
# ──────────────────────────────────
GOOGLE_PLAY_SA_JSON=./credentials/google-play-sa.json  # Service Account JSON 경로

# ──────────────────────────────────
# AdMob (광고)
# ──────────────────────────────────
ADMOB_IOS_APP_ID=ca-app-pub-XXXX~YYYY       # AdMob iOS App ID
ADMOB_ANDROID_APP_ID=ca-app-pub-XXXX~ZZZZ   # AdMob Android App ID
# Ad Unit ID는 파이프라인 Phase 6에서 입력

# ──────────────────────────────────
# AI 이미지 생성 (스토어 에셋용, 선택)
# ──────────────────────────────────
GEMINI_API_KEY=                     # Google Gemini API Key
# 앱 아이콘, Feature Graphic, 스크린샷 프레임 등 생성에 사용

# ──────────────────────────────────
# EAS (Expo Application Services)
# ──────────────────────────────────
EXPO_TOKEN=                         # Expo 액세스 토큰 (선택, CI용)
```

### 3. 키 파일 발급 가이드

#### App Store Connect API Key (.p8)

1. [App Store Connect](https://appstoreconnect.apple.com) 접속
2. **Users and Access** → **Integrations** → **App Store Connect API**
3. **Team Keys** 탭 → **Generate API Key**
4. 이름 입력, 권한: **Admin** 또는 **App Manager**
5. .p8 파일 다운로드 → `credentials/asc-api-key.p8`에 저장
6. **Key ID** (10자리)와 **Issuer ID** (UUID)를 `.env`에 기록

> .p8 파일은 **한 번만 다운로드 가능**합니다. 분실 시 새로 발급해야 합니다.

#### Google Play Service Account (.json)

1. [Google Play Console](https://play.google.com/console) 접속
2. **Settings** → **API access**
3. **Create new service account** 또는 Google Cloud Console에서 생성
4. **역할**: Service Account User + Android Management → Release Manager
5. Google Cloud Console에서 해당 Service Account의 **키 생성** → JSON
6. JSON 파일 → `credentials/google-play-sa.json`에 저장

#### Google Gemini API Key (선택 — AI 이미지 생성)

1. [Google AI Studio](https://aistudio.google.com/apikey) 접속
2. **Create API Key** 클릭
3. 키 복사 → `.env`의 `GEMINI_API_KEY`에 기록
4. 앱 아이콘, Feature Graphic, 프로모션 이미지 등 자동 생성에 사용

#### AdMob App ID

1. [AdMob](https://apps.admob.com) 접속
2. **Apps** → **Add App** (iOS + Android 각각)
3. App ID (`ca-app-pub-XXXX~YYYY`) → `.env`에 기록
4. 광고 단위는 Phase 6에서 안내에 따라 수동 생성

### 4. .gitignore (필수)

프로젝트 생성 시 자동으로 추가됨:

```gitignore
# Credentials — 절대 git에 올리지 않음
credentials/
*.p8
*.p12
*-sa.json
service-account*.json

# Environment
.env
.env.local
.env.*.local
```

### 5. 필수 vs 선택

| 항목 | 필수 여부 | 없으면? |
|------|----------|---------|
| ASC API Key (.p8) | Phase 9에서 필요 | iOS 자동 제출 불가 → 수동 EAS Submit |
| Google Play SA (.json) | Phase 9에서 필요 | Android API 호출 불가 → 수동 Play Console |
| AdMob App ID | Phase 6에서 필요 | `--skip-admob`으로 건너뛰기 가능 |
| Gemini API Key | 선택 | 이미지 직접 준비 (Figma, Canva 등) |
| EAS Token | 선택 (CI용) | `eas login` 대화형 로그인으로 대체 |

> **Phase 1~5 (시장조사~QA)는 키 파일 없이도 실행 가능합니다.**
> 키는 Phase 6 이후에만 필요하므로 개발 먼저 하고 나중에 설정해도 됩니다.

## Architecture

### Key Design Principles

| 원칙 | 설명 |
|------|------|
| **Generator-Evaluator 분리** | 빌드하는 에이전트와 평가하는 에이전트를 분리하여 자기평가 편향 제거 |
| **Agent subprocess per phase** | 각 Phase를 독립 에이전트로 실행 (컨텍스트 리셋) |
| **파일 기반 핸드오프** | 에이전트 간 통신은 `docs/harness/` 파일로 수행 |
| **Hard Threshold** | 주관적 판단을 구체적 PASS/FAIL 기준으로 변환 |
| **Contract Negotiation** | 빌드 전 Generator↔Evaluator 완료 기준 합의 |
| **Pause & Resume** | 수동 작업 필요 시 대기, 완료 후 자동 재개 |

### Hard Gates

| 항목 | 임계값 |
|------|--------|
| TypeScript 에러 | 0개 |
| ESLint 에러 | 0개 |
| `any` 타입 사용 | 0개 |
| FSD 레이어 위반 | 0건 |
| SafeAreaView 누락 | 0건 |
| 스텁/placeholder | 0건 |
| 디자인 4축 총점 | 7/10 미만 = FAIL |

### Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | React Native + Expo |
| Language | TypeScript (strict) |
| Routing | Expo Router (file-based) |
| Styling | NativeWind (Tailwind CSS) |
| State | Zustand + TanStack Query |
| Forms | React Hook Form + Zod |
| Lists | FlashList |
| Ads | react-native-google-mobile-ads |
| ATT | expo-tracking-transparency |
| Build | EAS Build |
| Screenshots | Maestro |
| iOS Submit | App Store Connect API |
| Android Submit | Google Play Developer API |

### FSD Architecture

```
app (routing) → widgets → features → entities → shared
```

상위 레이어는 하위 레이어만 참조 가능. 동일 레벨 간 직접 참조 금지.

## Pipeline Output

```
docs/harness/
├── specs/           # 시장 조사 결과
├── plans/           # PRD + 디자인 시스템
├── contract.md      # Generator↔Evaluator 합의 기준
├── handoff/         # Generator → Evaluator 핸드오프
├── feedback/        # Evaluator 피드백
├── store-assets/    # 스토어 스크린샷 + 메타데이터
├── screenshots/     # QA 스크린샷
├── references/      # 참고 자료
├── config.md        # 파이프라인 설정
├── state.md         # 파이프라인 상태
├── build-log.md     # 라운드 결과 기록
└── pipeline-log.md  # 이벤트 로그
```

## Store Submission Details

### iOS (완전 자동)

App Store Connect API를 통해 전체 자동화:
1. Bundle ID 등록 → 앱 레코드 생성
2. 메타데이터 설정 (한국어 기본)
3. 스크린샷 업로드
4. EAS Submit으로 빌드 업로드
5. 빌드 연결 → 심사 제출

**자동 설정:**
- 방향: Portrait only
- iPad 지원: 제거
- 암호화: No (ITSAppUsesNonExemptEncryption)
- ATT 권한 요청 (AdMob용, 2초 딜레이)
- Accessibility Bundle Name 자동 생성

### Android (일부 수동)

Play Console에서 수동 필요:
1. 앱 생성
2. IARC 콘텐츠 등급 설문
3. 데이터 안전 섹션
4. 대상 연령 + 광고 포함 신고

수동 완료 후 API 자동:
- 스토어 등록정보 업데이트
- AAB 업로드
- 트랙 릴리즈

### AdMob (수동 생성 → 자동 통합)

AdMob API는 광고 단위 생성을 지원하지 않음:
- 파이프라인이 필요한 광고 형식/위치 목록을 안내
- 사용자가 AdMob 콘솔에서 수동 생성
- Ad Unit ID 입력 → 코드에 자동 삽입
- `skip` 시 Google 테스트 광고 ID로 개발, 출시 전 교체

## Skills Reference

| Skill | Type | Description |
|-------|------|-------------|
| `/rn-harness` | user-invoked | 파이프라인 시작/재개/상태 |
| `/rn-harness --status` | user-invoked | 진행 상황 표시 |
| `/rn-harness --resume` | user-invoked | 일시정지 후 재개 |
| `rn-harness-research` | role | 시장 조사 + 경쟁 분석 |
| `rn-harness-plan` | role | PRD 작성 |
| `rn-harness-design` | role | 디자인 시스템 |
| `rn-harness-contract` | role | 완료 기준 협상 |
| `rn-harness-generator` | role | React Native 앱 빌드 |
| `rn-harness-evaluator` | role | QA 검증 (PASS/FAIL) |
| `rn-harness-admob` | role | AdMob 광고 통합 |
| `rn-harness-build` | role | EAS Build |
| `rn-harness-screenshot` | role | Maestro 스크린샷 |
| `rn-harness-submit` | role | App Store + Google Play 제출 |
| `rn-harness-status` | utility | 파이프라인 상태 조회 |
| `rn-harness-resume` | utility | 파이프라인 재개 |

## Configuration

파이프라인 시작 시 자동 수집 + `docs/harness/config.md` 생성:

```yaml
app_idea: "커피 구독 앱"
default_language: ko
bundle_id: com.gonigon.coffee    # iOS/Android 동일

developer:
  company_name: gonigon
  email: user@example.com
  privacy_url: https://example.com/privacy
  homepage_url: https://example.com
  copyright: "Copyright 2026. Name all rights reserved."

ios_review:
  first_name: Gildong
  last_name: Hong
  phone: "+821012345678"

admob:
  enabled: true
  ios_app_id: ""
  android_app_id: ""
  ad_units: []
```

## Arguments

```bash
/rn-harness "앱 설명"              # 새 파이프라인
/rn-harness --resume               # 재개
/rn-harness --status               # 상태 확인
/rn-harness --status --verbose     # 상세 상태
/rn-harness --rounds 5             # QA 최대 5라운드
/rn-harness --ref https://...      # 참고 사이트
/rn-harness --ref ./mockup.png     # 참고 이미지
/rn-harness --skip-research        # 시장 조사 스킵
/rn-harness --skip-admob           # AdMob 스킵
```

## Auto-Resume

레이트 리밋 발생 시:
1. `hooks/stop-failure-handler.sh`가 자동 감지
2. `state.md` → `paused`
3. macOS 알림 발송
4. 5분 후 자동 재개 스케줄

## Credits

- **[Anthropic's Harness Engineering](https://www.anthropic.com/engineering/rn-harness-design-long-running-apps)** — Generator-Evaluator 분리, 파일 핸드오프, 계약 협상, Hard Threshold
- **[super-hype-harness](https://github.com/jae1jeong/super-hype-harness)** — 웹 앱 하네스 플러그인 구조
- **[react-native-fsd-agent-template](https://github.com/seungmanchoi/react-native-fsd-agent-template)** — FSD 아키텍처, 모바일 에이전트 설계

## License

MIT
