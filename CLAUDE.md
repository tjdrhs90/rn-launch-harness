# RN Launch Harness

React Native 모바일 앱을 아이디어부터 스토어 출시까지 자동화하는 Claude Code 플러그인.

## Architecture

Anthropic의 [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) 원칙 기반:

- **Generator-Evaluator 분리**: 빌드하는 에이전트와 평가하는 에이전트를 분리
- **Agent subprocess per phase**: 각 Phase는 독립 에이전트로 실행 (컨텍스트 리셋)
- **파일 기반 핸드오프**: 에이전트 간 통신은 `docs/harness/` 파일로 수행
- **Hard Threshold**: 주관적 판단을 구체적 PASS/FAIL 기준으로 변환
- **Contract Negotiation**: 빌드 전 Generator↔Evaluator 완료 기준 합의

## Pipeline

```
/rn-harness "앱 아이디어" → Research → Plan → Design → Contract → Build → QA → AdMob → Build → Screenshots → Submit
```

## Key Directories

- `skills/` — 각 Phase의 SKILL.md 정의
- `hooks/` — 레이트 리밋 자동 재개 스크립트
- `docs/harness/` — 파이프라인 산출물 (실행 시 생성)

## Hard Gates

- TypeScript 에러 0개
- ESLint 에러 0개
- `any` 타입 사용 0개
- 스텁 구현 = FAIL
- 콘솔 에러 = FAIL
- SafeAreaView 미사용 = FAIL

## Store Submission

### iOS (완전 자동)
- App Store Connect API (JWT 인증)
- Bundle ID 등록 → 앱 생성 → 메타데이터 → 스크린샷 → 빌드 → 심사 제출

### Android (일부 수동)
- Google Play Developer API (Service Account)
- 수동 필요: 앱 생성, IARC 콘텐츠 등급, 데이터 안전 섹션
- 수동 완료 후 AskUserQuestion으로 재개 → AAB 업로드 → 릴리즈

### AdMob (수동 생성 → 자동 통합)
- 광고 단위는 AdMob 콘솔에서 수동 생성 (API 미지원)
- 파이프라인이 필요한 광고 단위 목록을 안내
- 사용자가 Ad Unit ID 입력 → 코드에 자동 삽입
