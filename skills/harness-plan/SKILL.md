# harness-plan — Phase 2: 기획 (PRD)

시장 조사 결과를 기반으로 상세 기획서(PRD)를 작성한다.

## Trigger

오케스트레이터에서 Phase 2로 호출됨.

## Input

- `docs/harness/specs/YYYY-MM-DD-research.md` (시장 조사)
- `docs/harness/config.md`
- `docs/harness/references/` (있으면)

## Process

### Step 1: 시장 조사 분석

research 산출물을 읽고:
- MVP 기능 리스트 확인
- 차별화 전략 확인
- 기술 타당성 확인

### Step 2: PRD 작성

#### 2a. 제품 개요
- 앱 이름 (가안)
- 한 줄 소개
- 핵심 가치 제안
- 타겟 사용자 페르소나 (2~3개)

#### 2b. 유저 스토리
P0/P1/P2 우선순위로 작성:
```
US-001 [P0]: 사용자는 이메일로 회원가입할 수 있다.
  - 수락 기준: 이메일 형식 검증, 비밀번호 8자 이상, 성공 시 홈 이동
```

#### 2c. 화면 구조 (Expo Router)
```
app/
├── _layout.tsx          # Root layout
├── (auth)/
│   ├── _layout.tsx
│   ├── login.tsx
│   └── signup.tsx
├── (tabs)/
│   ├── _layout.tsx
│   ├── index.tsx        # 홈
│   ├── explore.tsx
│   └── profile.tsx
└── (modal)/
    └── settings.tsx
```

#### 2d. FSD 모듈 맵
```
src/
├── features/
│   ├── auth/            # 인증
│   ├── home/            # 홈 피드
│   └── profile/         # 프로필
├── entities/
│   ├── user/            # 사용자 도메인
│   └── post/            # 게시물 도메인
├── widgets/
│   └── header/          # 공통 헤더
└── shared/
    ├── api/             # Axios 클라이언트
    ├── config/          # 환경설정, 테마
    ├── lib/             # 유틸리티
    ├── types/           # 공통 타입
    └── ui/              # 공통 컴포넌트
```

#### 2e. API 설계
```
POST   /auth/login       # 로그인
POST   /auth/signup      # 회원가입
GET    /users/:id        # 유저 정보
PATCH  /users/:id        # 유저 수정
GET    /posts            # 게시물 목록
POST   /posts            # 게시물 생성
```

#### 2f. 데이터 모델
주요 엔티티의 필드와 관계 정의.

#### 2g. 광고 배치 전략
AdMob 광고 위치 결정:
- 배너: 탭 하단 또는 리스트 사이
- 전면 광고: 화면 전환 시
- 리워드 광고: 프리미엄 기능 해제

#### 2h. MVP 범위
- 1차 출시 기능 (P0)
- 2차 업데이트 기능 (P1)
- 향후 로드맵 (P2)

### Step 3: 사용자 확인

AskUserQuestion으로 PRD 요약 공유:
- 화면 구조 확인
- 핵심 기능 확인
- 광고 배치 확인
- 수정 요청 반영

## Output

`docs/harness/plans/YYYY-MM-DD-prd.md`:

```markdown
# Product Requirements Document

## 1. 제품 개요
### 앱 이름
### 한 줄 소개
### 핵심 가치 제안
### 타겟 사용자

## 2. 유저 스토리
### P0 (MVP 필수)
### P1 (중요)
### P2 (나중에)

## 3. 화면 구조
### Expo Router 파일 구조
### 네비게이션 플로우

## 4. FSD 모듈 맵
### Features
### Entities
### Shared

## 5. API 설계
### 엔드포인트 목록
### 요청/응답 타입

## 6. 데이터 모델
### 엔티티 관계도

## 7. 광고 배치 전략
### 배너 광고 위치
### 전면 광고 트리거
### 리워드 광고 시나리오

## 8. 기술 스택
- React Native 0.81+ / Expo 54+
- TypeScript (strict)
- Expo Router 6 (file-based routing)
- NativeWind 4 (Tailwind CSS)
- Zustand 5 (전역 상태)
- TanStack Query 5 (서버 상태)
- React Hook Form + Zod (폼/검증)
- FlashList 2 (고성능 리스트)
- react-native-google-mobile-ads (AdMob)

## 9. MVP 범위 및 로드맵
```

## State Update

```yaml
current_phase: design
next_role: harness-design
```

## HARD GATES

- 유저 스토리에 수락 기준 필수
- Expo Router 파일 구조 반드시 포함
- FSD 레이어 규칙 준수 (app → widgets → features → entities → shared)
- 사용자 확인 없이 다음 Phase 진행 금지
