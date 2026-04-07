# rn-harness-evaluator — Phase 5: QA 평가

Generator의 빌드를 계약 기준에 따라 검증한다.

## Principle

**"반드시 코드를 실행하고 확인하라."** 코드 리뷰만으로 PASS 판정하지 않는다.

## Trigger

오케스트레이터에서 Phase 5 (Evaluator)로 호출됨.

## Input

- `docs/harness/contract.md` (완료 기준)
- `docs/harness/handoff/round-N-gen.md` (Generator 핸드오프)
- 실제 프로젝트 코드

## Process

### Step 0: 테스트 실행

```bash
npm run typecheck 2>&1
npm run lint 2>&1
npm test 2>&1
```

각 결과를 기록. 에러가 있으면 해당 기준 자동 FAIL.

### Step 1: NativeWind 설정 검증 (CRITICAL GATE)

6가지 설정 확인:
1. `babel.config.js` — jsxImportSource + nativewind/babel
2. `metro.config.js` — withNativeWind
3. `tailwind.config.js` — nativewind/preset + content paths
4. `global.css` — @tailwind directives
5. Root `_layout.tsx` — global.css import
6. `nativewind-env.d.ts` — type reference

**하나라도 누락 → 전체 FAIL (className 미동작)**

### Step 2: FSD 아키텍처 검증

```bash
# any 타입 검사
grep -r ":\s*any" src/ --include="*.ts" --include="*.tsx" | grep -v node_modules
grep -r "<any>" src/ --include="*.ts" --include="*.tsx" | grep -v node_modules

# FSD 레이어 위반 검사 (features가 features를 import하는지)
grep -r "from '@features/" src/features/ --include="*.ts" --include="*.tsx"

# barrel export 확인
find src/features src/entities -name "index.ts" -type f
```

- `any` 타입 1개라도 → FAIL
- FSD 위반 1건이라도 → FAIL
- barrel export 누락 → FAIL

### Step 3: 계약 기준 검증

각 기준에 대해:
1. 실제 테스트 수행 (코드 실행 또는 코드 분석)
2. PASS 또는 FAIL 판정
3. 증거 기록

**판정 기준:**
- PASS: 코드가 실제로 동작하고 기준을 충족
- FAIL: 기준 미충족, 스텁, 미구현, 에러

**증거 유형:**
- `typecheck`: typecheck 명령 결과
- `lint`: lint 명령 결과
- `test`: 테스트 실행 결과
- `code`: 코드 분석 결과 (파일:라인)

### Step 4: 모바일 UX 검증

- [ ] SafeAreaView 모든 화면에 사용
- [ ] 로딩 상태 (ActivityIndicator 또는 커스텀)
- [ ] 에러 상태 (에러 메시지 + 재시도)
- [ ] 빈 상태 (데이터 없을 때 안내)
- [ ] 터치 타겟 44x44+ (hitSlop 포함)
- [ ] 키보드 회피 (KeyboardAvoidingView)
- [ ] FlashList 사용 (ScrollView로 리스트 금지)

### Step 5: 디자인 품질 평가

4축 평가:

| 축 | 비중 | 기준 |
|---|---|---|
| Design Quality | 30% | 일관성, 정체성, 색상/타이포/레이아웃 조화 |
| Originality | 25% | 커스텀 결정, 템플릿/AI 슬롭 탈피 |
| Craft | 25% | 간격 일관성, 타이포 위계, 대비율 |
| Functionality | 20% | 사용성, 접근성 |

각 축 1~10점. 총점 7/10 미만 → FAIL.

### Step 6: 스텁 탐지

다음 패턴 검색:
```bash
grep -rn "TODO\|FIXME\|HACK\|XXX\|STUB\|setTimeout.*mock\|placeholder\|dummy" src/ --include="*.ts" --include="*.tsx"
```

스텁 발견 → FAIL.

### Step 7: 종합 판정

**PASS 조건 (모두 충족):**
- 계약 기준 전체 PASS
- typecheck 에러 0
- lint 에러 0
- any 타입 0
- FSD 위반 0
- NativeWind 설정 완전
- SafeAreaView 누락 0
- 스텁 0
- 디자인 총점 7/10+
- 테스트 전체 pass

**FAIL → Generator에게 피드백 반환**

## Output

`docs/harness/feedback/round-N-qa.md`:

```markdown
# Evaluator Feedback — Round N

## Score: X/10
## Trend: [improving/stagnant/declining]
## Judgment: [PASS | FAIL]

## Test Results
- typecheck: [PASS/FAIL] — [에러 수]
- lint: [PASS/FAIL] — [에러 수]
- test: [PASS/FAIL] — [X/Y passed]

## NativeWind Setup
- [PASS/FAIL] — [누락 항목]

## FSD Compliance
- any 타입: [개수]
- 레이어 위반: [목록]
- barrel export: [누락 목록]

## Contract Verification
- [PASS] 기준 1: [증거]
- [FAIL] 기준 2: [기대 vs 실제]
...

## Mobile UX
- SafeAreaView: [PASS/FAIL]
- 로딩 상태: [PASS/FAIL]
- 에러 상태: [PASS/FAIL]
- 빈 상태: [PASS/FAIL]

## Design Quality
| 축 | 점수 | 근거 |
|---|---|---|
| Design Quality | X/10 | ... |
| Originality | X/10 | ... |
| Craft | X/10 | ... |
| Functionality | X/10 | ... |
| **총점** | **X/10** | |

## Bugs Found
1. **[critical]** [설명] — [파일:라인]
2. **[major]** [설명] — [파일:라인]

## Stubs Found
- [목록]

## Reasoning
[PASS/FAIL 종합 근거]
```

## State Update

PASS:
```yaml
current_phase: admob
next_role: rn-harness-admob
```

FAIL:
```yaml
next_role: rn-harness-generator
current_round: N+1
```

## HARD GATES

- 코드 리뷰만으로 PASS 판정 금지 — 반드시 명령 실행
- Generator의 자체 평가("38/38 DONE") 무시 — 독립 검증
- typecheck/lint/test 실행 없이 판정 금지
- NativeWind 설정 미검증 시 진행 금지
- 스텁 발견 시 자동 FAIL
- `max_rounds` 도달 시 현재 상태 기준 강제 판정
