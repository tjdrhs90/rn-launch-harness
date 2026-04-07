# Evaluation Criteria Reference

QA 평가 시 참고하는 기준과 가이드라인.

## Core Principles

1. **회의적으로 평가하라** — Claude는 기본적으로 관대하게 평가함. 의식적으로 엄격하게.
2. **먼저 탐색하고, 그 다음 판단하라** — 코드 전체를 파악한 후 기준별 검증.
3. **실행 결과가 증거다** — 코드 리뷰 ≠ 증거. 명령 실행 결과가 증거.
4. **Generator의 자체 평가를 믿지 마라** — 독립적으로 검증.

## Hard Thresholds

| 항목 | 임계값 | 위반 시 |
|------|--------|---------|
| TypeScript 에러 | 0개 | FAIL |
| ESLint 에러 | 0개 | FAIL |
| `any` 타입 | 0개 | FAIL |
| FSD 레이어 위반 | 0건 | FAIL |
| SafeAreaView 누락 | 0건 | FAIL |
| barrel export 누락 | 0건 | FAIL |
| 스텁/placeholder | 0건 | FAIL |
| 디자인 총점 | 7/10 미만 | FAIL |
| 테스트 실패 | 1건이라도 | FAIL |

## Design 4-Axis Scoring Guide

### Design Quality (30%)
- **9-10**: 뮤지엄 퀄리티. 색상/타이포/레이아웃이 하나의 정체성을 형성.
- **7-8**: 프로페셔널. 일관성 있고 완성도 높음.
- **5-6**: 적절함. 기능적이지만 인상적이지 않음.
- **3-4**: 불일치. 색상/폰트/간격이 제각각.
- **1-2**: 깨짐. UI가 겹치거나 잘림.

### Originality (25%)
- **9-10**: 독창적 크리에이티브 결정이 돋보임.
- **7-8**: 커스텀 결정이 있으나 일부 제네릭.
- **5-6**: 대부분 기본 컴포넌트. 약간의 커스터마이징.
- **3-4**: 템플릿 그대로. 보라색 그래디언트 + 흰 카드.
- **1-2**: AI 슬롭. 기본값 변경 없음.

### Craft (25%)
- **9-10**: 픽셀 퍼펙트. 간격/정렬/대비 완벽.
- **7-8**: 대부분 정확. 사소한 불일치 1~2곳.
- **5-6**: 기본은 됨. 간격 불일치 여러 곳.
- **3-4**: 거친 실행. 정렬 안 맞음, 대비 부족.
- **1-2**: 깨진 레이아웃.

### Functionality (20%)
- **9-10**: 인터랙션이 직관적. 에러/로딩/빈 상태 완벽.
- **7-8**: 주요 플로우 원활. 에러 처리 대부분 있음.
- **5-6**: 핵심 기능 동작. 일부 상태 누락.
- **3-4**: 내비게이션 혼란. 상태 처리 부족.
- **1-2**: 기본 사용이 어려움.

## FSD Architecture Checks

### 레이어 계층
```
app (routing) → widgets → features → entities → shared
```
상위 → 하위만 참조 가능. 동일 레벨 간 직접 참조 금지.

### Import 규칙
- `@/` alias 사용 필수
- 상대 경로 (`../`) 크로스 레이어 import 금지
- barrel export (index.ts)에서만 import

### 네이밍 규칙
- Interface: `I` prefix (IUserState)
- Type: `T` prefix (TButtonVariant)
- Enum: `E` prefix (EUserRole)
- Hook file: `use-` prefix (use-login.ts)
- API file: `.api.ts` suffix
- Store file: `.store.ts` suffix
- Component: PascalCase (Button.tsx)

## Mobile-Specific Checks

- SafeAreaView: `react-native-safe-area-context`에서 import
- FlashList: 리스트 렌더링은 반드시 FlashList 사용
- KeyboardAvoidingView: 폼 화면에 필수
- 터치 타겟: minimum 44x44 (hitSlop 포함)
- 접근성: accessibilityLabel, accessibilityRole 설정
