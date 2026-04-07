# rn-harness-contract — Phase 4: 계약 협상

Generator와 Evaluator가 빌드 전 완료 기준에 합의한다.

## Trigger

오케스트레이터에서 Phase 4로 호출됨.

## Input

- `docs/harness/plans/YYYY-MM-DD-prd.md` (PRD)
- `docs/harness/plans/YYYY-MM-DD-design.md` (디자인)
- `docs/harness/specs/YYYY-MM-DD-research.md` (시장 조사)

## Process

### Step 1: Generator가 계약안 작성

PRD의 유저 스토리와 디자인 스펙을 기반으로 15~30개의 검증 가능한 기준을 작성:

```markdown
## Contract Proposal

### 1. 회원가입
- **Test**: 이메일/비밀번호 입력 → 가입 버튼 탭
- **Expected**: 유효성 검사 통과 → 홈 화면 이동 → 유저 데이터 저장
- **Evidence**: typecheck pass + 코드 확인
- **Type**: code

### 2. 로그인 후 홈 피드
- **Test**: 로그인 → 홈 탭 → 데이터 로드
- **Expected**: 로딩 스피너 → 데이터 표시 → 스크롤 가능
- **Evidence**: typecheck pass + 코드 확인
- **Type**: code

### 3. 프로필 수정
- **Test**: 프로필 화면 → 이름 수정 → 저장
- **Expected**: 수정 후 반영, 에러 시 Toast 표시
- **Evidence**: typecheck pass + 코드 확인
- **Type**: code
```

### Step 2: Review (mode-dependent)

**Default mode (1-pass):**
- Generator writes the contract with mandatory criteria included
- Self-review for completeness and specificity
- Mark as AGREED immediately
- Saves tokens by skipping multi-round negotiation

**Strict mode (`--strict`):**
- Evaluator reviews each criterion (specific enough? verifiable? edge cases?)
- Generator revises based on feedback
- Iterate until `## Review` section says "AGREED"

### 필수 기준 (MANDATORY)

모든 계약에 반드시 포함:

#### Anti-Stub 기준
- **AS-1**: 핵심 기능이 실제 동작 (setTimeout/mock 아님)
- **AS-2**: 엔드투엔드 데이터 흐름 (생성 → 저장 → 새로고침 → 존재 확인)
- **AS-3**: 에러 핸들링 (잘못된 입력 시 적절한 에러 표시)

#### 테스트 기준
- **T-1**: 테스트 러너 설치 (`npm test` exit 0)
- **T-2**: 핵심 비즈니스 로직 유닛 테스트 존재

#### 코드 품질 기준
- **CQ-1**: `npm run typecheck` 에러 0개
- **CQ-2**: `npm run lint` 에러 0개
- **CQ-3**: `any` 타입 사용 0개

#### FSD 아키텍처 기준
- **FSD-1**: 레이어 계층 준수 (app → widgets → features → entities → shared)
- **FSD-2**: 동일 레이어 간 직접 참조 없음
- **FSD-3**: barrel export (index.ts) 완전성

#### 모바일 UX 기준
- **UX-1**: 모든 화면 SafeAreaView 사용
- **UX-2**: 로딩/에러/빈 상태 처리
- **UX-3**: 터치 타겟 44x44 이상
- **UX-4**: NativeWind className만 사용 (inline style 금지)

## Output

`docs/harness/contract.md`:

```markdown
# Build Contract

## Status: AGREED

## Criteria

### Functional
1. [기준 1]
2. [기준 2]
...

### Anti-Stub
AS-1: ...
AS-2: ...
AS-3: ...

### Test
T-1: ...
T-2: ...

### Code Quality
CQ-1: ...
CQ-2: ...
CQ-3: ...

### FSD Architecture
FSD-1: ...
FSD-2: ...
FSD-3: ...

### Mobile UX
UX-1: ...
UX-2: ...
UX-3: ...
UX-4: ...

## Review
AGREED — [날짜]

## Negotiation History
### Round 1 — Generator Proposal
[원본]
### Round 2 — Evaluator Review
[피드백]
### Round 3 — Final Agreement
[합의]
```

## State Update

```yaml
current_phase: generator
next_role: rn-harness-generator
current_round: 1
```

## HARD GATES

- Anti-Stub 기준 (AS-1~3) 반드시 포함
- 테스트 기준 (T-1~2) 반드시 포함
- 코드 품질 기준 (CQ-1~3) 반드시 포함
- FSD 기준 (FSD-1~3) 반드시 포함
- 모바일 UX 기준 (UX-1~4) 반드시 포함
- "AGREED" 없으면 빌드 진행 금지
