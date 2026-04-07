# harness-screenshot — Phase 8: 스토어 스크린샷

Maestro를 사용하여 앱 스토어용 스크린샷을 자동 촬영한다.

## Trigger

오케스트레이터에서 Phase 8로 호출됨.

## Input

- `docs/harness/plans/YYYY-MM-DD-prd.md` (화면 구조)
- 실제 프로젝트 코드
- 빌드된 앱 (development build)

## Prerequisites

- Maestro CLI 설치 (`curl -Ls "https://get.maestro.mobile.dev" | bash`)
- iOS Simulator 또는 Android Emulator 실행 중
- Development build 설치됨

## Process

### Step 1: 스크린샷 대상 화면 결정

PRD 기반으로 스토어에 올릴 주요 화면 선정 (5~8장):
1. 온보딩 / 로그인
2. 메인 홈 화면
3. 핵심 기능 1
4. 핵심 기능 2
5. 검색 / 탐색
6. 프로필 / 설정
7. (옵션) 다크 모드
8. (옵션) 광고 없는 프리미엄 화면

### Step 2: Maestro 플로우 작성

`maestro/screenshots.yaml`:
```yaml
appId: com.company.app
---
# 1. 로그인 화면
- launchApp
- takeScreenshot: docs/harness/store-assets/01-login

# 2. 홈 화면
- tapOn: "Login"  # 또는 테스트 계정으로 로그인
- assertVisible: "Home"
- takeScreenshot: docs/harness/store-assets/02-home

# 3. 핵심 기능 화면
- tapOn: "Feature"
- takeScreenshot: docs/harness/store-assets/03-feature

# 4. 상세 화면
- tapOn:
    index: 0
- takeScreenshot: docs/harness/store-assets/04-detail

# 5. 프로필
- tapOn: "Profile"
- takeScreenshot: docs/harness/store-assets/05-profile
```

### Step 3: 디바이스별 스크린샷 촬영

#### iOS (App Store 요구 사양)
```bash
# iPhone 6.7" (iPhone 15 Pro Max) — 필수
maestro --device "iPhone 15 Pro Max" test maestro/screenshots.yaml

# iPhone 6.5" (iPhone 11 Pro Max) — 필수  
maestro --device "iPhone 11 Pro Max" test maestro/screenshots.yaml

# iPhone 5.5" (iPhone 8 Plus) — 선택
maestro --device "iPhone 8 Plus" test maestro/screenshots.yaml

# iPad 12.9" — 선택
maestro --device "iPad Pro (12.9-inch)" test maestro/screenshots.yaml
```

#### Android (Google Play 요구 사양)
```bash
# Phone — 필수
maestro test maestro/screenshots.yaml

# 7" Tablet — 선택
# 10" Tablet — 선택
```

### Step 4: 스크린샷 정리

```
docs/harness/store-assets/
├── ios/
│   ├── 6.7/
│   │   ├── 01-login.png
│   │   ├── 02-home.png
│   │   └── ...
│   ├── 6.5/
│   │   └── ...
│   └── 5.5/
│       └── ...
└── android/
    └── phone/
        ├── 01-login.png
        ├── 02-home.png
        └── ...
```

### Step 5: 스토어 메타데이터 생성

`docs/harness/store-assets/metadata.md`:
```markdown
# Store Metadata

## 앱 이름
[이름] (30자 이내)

## 부제 (iOS)
[부제] (30자 이내)

## 짧은 설명 (Android)
[설명] (80자 이내)

## 전체 설명
[설명] (4000자 이내)

## 키워드 (iOS)
[키워드1, 키워드2, ...] (100자 이내)

## 카테고리
iOS: [카테고리]
Android: [카테고리]

## 개인정보처리방침 URL
[URL — 사용자에게 확인 필요]

## 지원 URL
[URL]

## 마케팅 URL (선택)
[URL]
```

### Step 6: 사용자 확인

AskUserQuestion:
- 스크린샷 확인 요청
- 메타데이터 확인 및 수정
- 개인정보처리방침 URL 입력 요청

## Output

- `docs/harness/store-assets/` — 스크린샷 + 메타데이터
- `maestro/screenshots.yaml` — Maestro 플로우

## State Update

```yaml
current_phase: submit
next_role: harness-submit
```

## HARD GATES

- 최소 5장의 스크린샷 필수
- iOS 6.7" 스크린샷 필수
- 메타데이터 (이름, 설명, 카테고리) 필수
- 개인정보처리방침 URL 필수 (사용자 입력)
- Maestro 미설치 시 수동 캡처 안내로 전환
