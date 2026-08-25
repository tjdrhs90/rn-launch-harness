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
/rn-harness "앱 아이디어" → Research → Plan → Design → Contract → Build → QA → AdMob → Accept(사용자 승인) → Build → Screenshots → Submit
```

## Key Directories

- `skills/` — 각 Phase의 SKILL.md 정의
- `hooks/` — 레이트 리밋 자동 재개 스크립트
- 파이프라인 산출물 — **런별 격리**: Phase 1~4는 유니크한 `.rn-harness/<run-id>/`에 스테이징, Phase 5에서 최상위 `<app-slug>/`로 졸업하며 `docs/harness/`를 그 안으로 이동 (같은 폴더에서 여러 런 동시 실행 시 충돌 방지)

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
- Bundle ID 등록 → 앱 생성 → 메타데이터 → 스크린샷 → 빌드 → 연령 등급 → 심사 제출
- 심사 제출은 `reviewSubmissions` **3-call 플로우**. `appStoreVersionSubmissions` CREATE 는
  폐기됨(403)
- 메타데이터는 `WAITING_FOR_REVIEW`·`IN_REVIEW` 까지 수정 가능, `READY_FOR_SALE` 에서 잠김

### Android (일부 수동)
- Google Play Developer API (Service Account)
- 수동 필요: 앱 생성, IARC 콘텐츠 등급, 데이터 안전 섹션
- 수동 완료 후 AskUserQuestion으로 재개 → AAB 업로드 → 릴리즈

### AdMob (수동 생성 → 자동 통합)
- 광고 단위는 AdMob 콘솔에서 수동 생성 (API 미지원)
- 파이프라인이 필요한 광고 단위 목록을 안내
- 사용자가 Ad Unit ID 입력 → 코드에 자동 삽입
- **연령 등급의 `advertising` 을 반드시 Yes 로** — 배너만 있어도 해당. 누락 시 Apple 자동
  분석이 사람 심사 전에 반려한다

### 제출 전 필수 점검

리젝을 실제로 부른 것들. 자세한 내용은 `docs/store-gotchas.md`.

- **Expo 는 의존성에 있으면 config plugin 을 자동 적용한다** — `plugins` 배열에 없어도.
  `expo-image-picker`/`expo-camera` 의 기본 마이크 문구가 그대로 나가 5.1.1 반려를 부른다.
  `plugins` 가 아니라 prebuild 로 생성된 `Info.plist` 를 봐야 한다
- 도달할 수 없는 기능의 권한은 넣지 않는다
- Android 는 **병합된 매니페스트**를 본다 — 의존성이 밀어 넣은 `FOREGROUND_SERVICE_*` 등은
  Play Console 별도 선언 대상이고, 선언에는 데모 영상이 필수다
