# rn-harness-design — Phase 3: 디자인 시스템

PRD를 기반으로 NativeWind 디자인 시스템을 설계한다.

## Trigger

오케스트레이터에서 Phase 3으로 호출됨.

## Input

- `docs/harness/plans/YYYY-MM-DD-prd.md` (PRD)
- `docs/harness/references/` (있으면)

## Process

### Step 1: 브랜드 톤 결정

3가지 비주얼 방향 제안:
1. **미니멀** — 깔끔, 여백, 모노톤
2. **웜** — 따뜻한 색감, 라운드, 친근
3. **볼드** — 강렬한 색상, 대비, 임팩트

AskUserQuestion으로 사용자 선택.

### Step 2: 컬러 시스템

```typescript
// tailwind.config.js colors 확장
colors: {
  primary: {
    50: '#...',
    100: '#...',
    // ... 900
    DEFAULT: '#...',
  },
  secondary: { ... },
  // Semantic colors
  success: '#...',
  warning: '#...',
  error: '#...',
  info: '#...',
  // Background
  background: '#...',
  surface: '#...',
  // Text
  text: {
    primary: '#...',
    secondary: '#...',
    disabled: '#...',
  },
}
```

Light/Dark 모드 모두 정의.

### Step 3: 타이포그래피

```
Heading 1: 28px / Bold / line-height 36
Heading 2: 24px / Semibold / line-height 32
Heading 3: 20px / Semibold / line-height 28
Body:      16px / Regular / line-height 24
Caption:   12px / Regular / line-height 16
Label:     14px / Medium / line-height 20
```

### Step 4: 컴포넌트 스펙

주요 컴포넌트 variant 정의:
- **Button**: primary, secondary, outline, ghost / sm, md, lg
- **Card**: default, elevated, outlined
- **Input**: default, error, disabled / with icon
- **Typography**: h1, h2, h3, body, caption, label
- **Badge**: default, success, warning, error
- **Toast**: success, error, info, warning

### Step 5: 화면 레이아웃

각 주요 화면의 레이아웃 구조:
```tsx
<SafeAreaView className="flex-1 bg-background">
  <Header />
  <ScrollView className="flex-1 px-4">
    {/* Content */}
  </ScrollView>
  {/* AdBanner는 SafeAreaView 안, 하단 */}
  <AdBanner />
</SafeAreaView>
```

### Step 6: 광고 배치 디자인

AdMob 광고의 시각적 통합:
- 배너: 콘텐츠와 자연스럽게 어우러지는 배치
- 전면: 닫기 버튼 접근성 확보
- 리워드: 보상 안내 UI 디자인

### Step 7: 4축 자체 평가

| 축 | 비중 | 목표 | 설명 |
|---|---|---|---|
| Design Quality | 30% | 7/10+ | 일관성, 정체성 |
| Originality | 25% | 6/10+ | 커스텀 결정, 템플릿 탈피 |
| Craft | 25% | 7/10+ | 간격, 타이포, 대비 |
| Functionality | 20% | 8/10+ | 사용성 |

## Output

`docs/harness/plans/YYYY-MM-DD-design.md`:

```markdown
# Design System

## 브랜드 톤
[선택된 톤 + 이유]

## 컬러 시스템
### Light Mode
### Dark Mode

## 타이포그래피

## 컴포넌트 스펙
### Button
### Card
### Input
### Typography

## 화면 레이아웃
### 홈
### 상세
### 프로필

## 광고 배치 디자인

## 자체 평가
| 축 | 점수 | 근거 |
```

추가로 파일 직접 수정:
- `tailwind.config.js` — colors, fonts 확장
- `src/shared/config/theme.ts` — 테마 토큰 정의

## State Update

```yaml
current_phase: contract
next_role: rn-harness-contract
```

## HARD GATES

- NativeWind className만 사용 (inline style 금지)
- Light/Dark 모드 모두 정의
- 컬러 대비 4.5:1 이상
- SafeAreaView 모든 화면에 필수
- 사용자 브랜드 톤 확인 필수
