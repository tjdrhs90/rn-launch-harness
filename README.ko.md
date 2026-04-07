# RN Launch Harness

React Native 모바일 앱을 **아이디어부터 스토어 출시까지** 자동화하는 Claude Code 플러그인.

한 줄 명령으로 시장 조사, 기획, 디자인, 개발, AdMob 광고 통합, EAS 빌드, 스토어 스크린샷 촬영, App Store/Google Play 심사 제출까지 전체 파이프라인을 실행합니다.

> **아이디어가 없어도 OK.** 인자 없이 실행하면 App Store/Google Play 탑 차트를 조사해서 1인 개발 가능 + 서버 불필요한 앱을 추천합니다.

[Anthropic의 Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)에서 영감을 받아 제작.

[English](./README.md)

## 설치

```bash
claude plugins marketplace add tjdrhs90/rn-launch-harness
claude plugins install rn-launch-harness@rn-launch-harness
```

## 사용법

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

## 파이프라인

### 기본 모드 (~$30-60, Claude Max 친화적)

```
/rn-harness "앱 아이디어"
    |
 Phase 1: 시장 조사 → 경쟁 분석, 수익화
 Phase 2: 기획 → PRD, 유저 스토리, FSD 모듈 맵
 Phase 3: 디자인 시스템 → NativeWind 테마, 컴포넌트
 Phase 4: 계약 → 1회 기준 작성 (협상 없음)
 Phase 5: 빌드 (3단계)
    |  5a: Feature/Entity 스캐폴딩 → Quick QA
    |  5b: API 연동 → Quick QA
    |  5c: 스크린/UI 개발 → Quick QA
 Phase 6: QA — 기능 검증만 (typecheck, lint, FSD, 계약 기준)
    |  FAIL → 수정 → 재검증 (최대 3라운드)
 Phase 7: AdMob → 스마트 광고 배치 + 코드 삽입
 Phase 8: EAS Build → iOS + Android
 Phase 9: 스크린샷 → Maestro + 메타데이터
 Phase 10: 스토어 제출 → ASC API + Google Play API
```

### --strict 모드 (~$100-160, 철저)

```
/rn-harness "앱 아이디어" --strict
    |
 + Phase 2.5: 스펙 분해 → 파일별 태스크 체크리스트
 + Phase 4: 계약 → Generator↔Evaluator 다회 협상
 + Phase 6: 3단계 점진적 QA
    |  6.1 기능 검증 — 동작하는가?
    |  6.2 품질 검증 — 좋은가? (디자인 4축)
    |  6.3 엣지 케이스 — 살아남는가? (6개 Agent Team + 시뮬레이터)
 + Phase 11: 회고 → Anthropic 원칙 평가
```

## 요구사항

- **Claude Code** (최신)
- **Node.js** 20+
- **EAS CLI** (`npm install -g eas-cli`)
- **Maestro** (스크린샷용, 선택) — `curl -Ls "https://get.maestro.mobile.dev" | bash`
- **gh CLI** (GitHub 연동)

## 설정 — 키 파일 & 환경 변수

### 프로젝트 디렉토리 구조

```
my-app/
├── credentials/              # 키 파일 (git에 올라가지 않음)
│   ├── asc-api-key.p8        # App Store Connect API Key
│   └── google-play-sa.json   # Google Play Service Account
├── .env                      # 환경 변수 (git에 올라가지 않음)
├── .env.example              # 환경 변수 템플릿
└── .gitignore                # credentials/, .env 제외
```

### 환경 변수 (.env)

```bash
# ── App Store Connect API (iOS 제출) ──
ASC_KEY_ID=XXXXXXXXXX
ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ASC_PRIVATE_KEY_PATH=./credentials/asc-api-key.p8

# ── Google Play Developer API (Android 제출) ──
GOOGLE_PLAY_SA_JSON=./credentials/google-play-sa.json

# ── AdMob ──
ADMOB_IOS_APP_ID=ca-app-pub-XXXX~YYYY
ADMOB_ANDROID_APP_ID=ca-app-pub-XXXX~ZZZZ

# ── AI 이미지 생성 (스토어 에셋용, 선택) ──
GEMINI_API_KEY=

# ── EAS (선택, CI용) ──
EXPO_TOKEN=
```

### 키 파일 발급 가이드

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
3. Service Account 생성 (또는 Google Cloud Console에서)
4. **역할**: Release Manager
5. JSON 키 생성 → `credentials/google-play-sa.json`에 저장

#### Google Gemini API Key (선택 — AI 이미지 생성)

1. [Google AI Studio](https://aistudio.google.com/apikey) 접속
2. **Create API Key** 클릭
3. `.env`의 `GEMINI_API_KEY`에 기록
4. 앱 아이콘, Feature Graphic, 프로모션 이미지 등 자동 생성에 사용

#### AdMob App ID

1. [AdMob](https://apps.admob.com) 접속
2. **Apps** → **Add App** (iOS + Android 각각)
3. App ID (`ca-app-pub-XXXX~YYYY`) → `.env`에 기록
4. 광고 단위는 Phase 6에서 안내에 따라 수동 생성

### 필수 vs 선택

| 항목 | 필수 여부 | 없으면? |
|------|----------|---------|
| ASC API Key (.p8) | Phase 9에서 필요 | iOS 자동 제출 불가 → 수동 EAS Submit |
| Google Play SA (.json) | Phase 9에서 필요 | Android API 호출 불가 → 수동 Play Console |
| AdMob App ID | Phase 6에서 필요 | `--skip-admob`으로 건너뛰기 가능 |
| Gemini API Key | 선택 | 이미지 직접 준비 (Figma, Canva 등) |
| EAS Token | 선택 (CI용) | `eas login` 대화형 로그인으로 대체 |

> **Phase 1~5 (시장조사~QA)는 키 파일 없이도 실행 가능합니다.**
> 키는 Phase 6 이후에만 필요하므로 개발 먼저 하고 나중에 설정해도 됩니다.

## 아키텍처

### 핵심 설계 원칙

| 원칙 | 설명 |
|------|------|
| **Generator-Evaluator 분리** | 빌드 에이전트와 평가 에이전트를 분리하여 자기평가 편향 제거 |
| **Phase별 Agent Subprocess** | 각 Phase를 독립 에이전트로 실행 (컨텍스트 리셋) |
| **파일 기반 핸드오프** | 에이전트 간 통신은 `docs/harness/` 파일로 수행 |
| **Hard Threshold** | 주관적 판단을 구체적 PASS/FAIL 기준으로 변환 |
| **계약 협상** | 빌드 전 Generator↔Evaluator 완료 기준 합의 |
| **일시정지 & 재개** | 수동 작업 필요 시 대기, 완료 후 자동 재개 |

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

### 기술 스택

| 분류 | 기술 |
|------|------|
| 프레임워크 | React Native + Expo |
| 언어 | TypeScript (strict) |
| 라우팅 | Expo Router (파일 기반) |
| 스타일링 | NativeWind (Tailwind CSS) |
| 상태 관리 | Zustand + TanStack Query |
| 폼 | React Hook Form + Zod |
| 리스트 | FlashList |
| 광고 | react-native-google-mobile-ads |
| 추적 권한 | expo-tracking-transparency |
| 빌드 | EAS Build |
| 스크린샷 | Maestro |
| iOS 제출 | App Store Connect API |
| Android 제출 | Google Play Developer API |

### FSD 아키텍처

```
app (routing) → widgets → features → entities → shared
```

상위 레이어는 하위 레이어만 참조 가능. 동일 레벨 간 직접 참조 금지.

## 스토어 제출 상세

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
- 암호화: No (`ITSAppUsesNonExemptEncryption`)
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

> 파이프라인이 수동 작업을 **안내하고 대기**한 뒤, 완료 확인 후 자동으로 이어갑니다.

### AdMob (수동 생성 → 자동 통합)

AdMob API는 광고 단위 생성을 지원하지 않음:
- 파이프라인이 필요한 광고 형식/위치 목록을 안내
- 사용자가 AdMob 콘솔에서 수동 생성
- Ad Unit ID 입력 → 코드에 자동 삽입
- `skip` 시 Google 테스트 광고 ID로 개발, 출시 전 교체

## 인자 (Arguments)

```bash
/rn-harness "앱 설명"              # 새 파이프라인
/rn-harness                         # 아이디어 발굴 모드
/rn-harness --resume                # 재개
/rn-harness --status                # 상태 확인
/rn-harness --status --verbose      # 상세 상태
/rn-harness --rounds 5              # QA 최대 5라운드
/rn-harness --ref https://...       # 참고 사이트
/rn-harness --ref ./mockup.png      # 참고 이미지
/rn-harness --skip-research         # 시장 조사 스킵
/rn-harness --skip-admob            # AdMob 스킵
```

## 자동 재개

레이트 리밋 발생 시:
1. `hooks/stop-failure-handler.sh`가 자동 감지
2. `state.md` → `paused`
3. macOS 알림 발송
4. 5분 후 자동 재개 스케줄

## 크레딧

- **[Anthropic's Harness Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)** — Generator-Evaluator 분리, 파일 핸드오프, 계약 협상, Hard Threshold
- **[super-hype-harness](https://github.com/jae1jeong/super-hype-harness)** — 웹 앱 하네스 플러그인 구조
- **[react-native-fsd-agent-template](https://github.com/seungmanchoi/react-native-fsd-agent-template)** — FSD 아키텍처, 모바일 에이전트 설계

## 라이선스

MIT
