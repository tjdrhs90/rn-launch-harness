# harness-research — Phase 1: 시장 조사

앱 아이디어를 기반으로 시장 조사, 경쟁 앱 분석, 기회 영역을 도출한다.

## Trigger

오케스트레이터(`/harness`)에서 Phase 1으로 호출됨.

## Input

- `docs/harness/config.md`의 `app_idea`
- `docs/harness/references/` (있으면)

## Process

### Step 1: 아이디어 분석

`app_idea`를 읽고 다음을 파악:
- 핵심 도메인 (건강, 금융, 교육, 커머스 등)
- 타겟 사용자층
- 핵심 가치 제안

### Step 2: 시장 조사

WebSearch를 사용하여:
1. **카테고리 트렌드**: 해당 카테고리 App Store/Google Play 인기 앱 조사
2. **경쟁 앱 분석**: 상위 5~10개 경쟁 앱 분석
   - 앱 이름, 평점, 주요 기능, 강점, 약점
   - 유저 리뷰에서 반복되는 불만/요청 사항
3. **시장 기회**: 경쟁 앱이 놓치고 있는 영역
4. **수익화 모델**: 해당 카테고리에서 흔한 수익 모델 (광고, 구독, 인앱결제)

### Step 3: 차별화 전략 수립

경쟁 분석 기반으로:
- 핵심 차별점 3가지
- MVP 핵심 기능 리스트
- "이 앱을 쓰는 이유" 한 줄 정의

### Step 4: 기술 타당성 검토

React Native + Expo로 구현 가능한지:
- 필요한 네이티브 모듈 확인
- Expo SDK 지원 여부
- 서드파티 라이브러리 존재 여부
- 백엔드 요구사항 (Firebase, Supabase 등)

### Step 5: 사용자 확인

AskUserQuestion으로 조사 결과를 공유하고 방향 확인:
- "조사 결과를 확인해주세요. 수정할 부분이 있으면 알려주세요."
- 사용자 피드백 반영

## Output

`docs/harness/specs/YYYY-MM-DD-research.md`:

```markdown
# 시장 조사 보고서

## 앱 아이디어
[원본 아이디어]

## 시장 분석
### 카테고리 트렌드
[조사 결과]

### 경쟁 앱 분석
| 앱 | 평점 | 주요 기능 | 강점 | 약점 |
|---|---|---|---|---|

### 시장 기회
[경쟁 앱이 놓치는 영역]

## 차별화 전략
1. [차별점 1]
2. [차별점 2]
3. [차별점 3]

## 핵심 가치 제안
[한 줄 정의]

## MVP 기능 리스트
### P0 (필수)
- [ ] 기능 1
- [ ] 기능 2

### P1 (중요)
- [ ] 기능 3

### P2 (나중에)
- [ ] 기능 4

## 수익화 전략
[광고, 구독, 인앱결제 등]

## 기술 타당성
### React Native + Expo 호환성
[검토 결과]

### 필요 라이브러리
[목록]

### 백엔드 요구사항
[Firebase/Supabase 등]
```

## State Update

완료 후 `state.md` 업데이트:
```yaml
current_phase: plan
next_role: harness-plan
```

## HARD GATES

- WebSearch를 반드시 사용하여 실제 데이터 기반으로 조사
- 경쟁 앱 최소 3개 이상 분석
- 사용자 확인 없이 다음 Phase로 진행 금지
