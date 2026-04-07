# /harness — RN Launch Harness

React Native 모바일 앱을 아이디어부터 스토어 출시까지 자동화하는 메인 오케스트레이터.

## Arguments

- `"앱 설명"` — 새 파이프라인 시작
- `--resume` — 일시정지된 파이프라인 재개
- `--status` — 진행 상황 확인
- `--rounds <N>` — QA Phase 당 최대 라운드 수 (기본: 10, 0=무제한)
- `--ref <url-or-image>` — 참고 자료 (반복 가능)
- `--skip-research` — 시장 조사 건너뛰기
- `--skip-admob` — AdMob 통합 건너뛰기

## Execution

### Step 0: Argument Parsing

```
if --status → Skill("harness-status")
if --resume → Skill("harness-resume")
```

앱 설명을 `$APP_IDEA`로 저장.

### Step 1: Bootstrap

디렉토리 구조 생성:
```
docs/harness/
├── specs/
├── plans/
├── handoff/
├── feedback/
├── references/
├── screenshots/
├── store-assets/
├── config.md
├── state.md
├── build-log.md
└── pipeline-log.md
```

### Step 2: Reference Capture

`--ref`가 있으면:
- URL → WebFetch로 내용 확인 + 메모
- 이미지 파일 → `docs/harness/references/`에 복사

### Step 3: 사용자 정보 수집

AskUserQuestion으로 필수 정보 수집:

```
앱 개발을 시작하기 전에 몇 가지 정보가 필요합니다:

1. 회사/개발자명 (Bundle ID용, 예: gonigon)
   → com.{회사명}.{앱이름} 형태로 iOS/Android 동일하게 사용

2. 앱 기본 언어: (기본: ko — 한국어)

3. 개인정보처리방침 URL:
4. 지원 이메일:
5. 홈페이지 URL: (Android 홈페이지 + iOS 마케팅 URL로 사용)

6. 저작권 표기: (예: Copyright 2026. 홍길동 all rights reserved.)

7. iOS 심사 연락처:
   - 이름 (First Name):
   - 성 (Last Name):
   - 전화번호: (국가코드 포함, 예: +821012345678)

8. AdMob 사용 여부: (yes/no)

이미 설정된 값이 있으면 알려주세요.
```

### Step 4: Config 생성

`docs/harness/config.md` 생성:
```yaml
app_idea: "$APP_IDEA"
auto_resume: true
max_rounds: 10
skip_research: false
skip_admob: false
has_references: false
default_language: ko

# Developer Info
developer:
  company_name: ""          # Bundle ID용 (예: gonigon)
  email: ""                 # 지원 이메일
  privacy_url: ""           # 개인정보처리방침 URL
  homepage_url: ""          # 홈페이지 (Android) / 마케팅 URL (iOS)
  copyright: ""             # 저작권 표기

# iOS 심사 정보
ios_review:
  first_name: ""
  last_name: ""
  phone: ""                 # +821012345678

# App Identity (양 플랫폼 동일)
bundle_id: ""               # com.{company}.{appname} — iOS/Android 동일

# Store Submission
ios:
  enabled: true
  asc_api_key_id: ""        # App Store Connect API Key ID
  asc_issuer_id: ""         # Issuer ID
  asc_private_key_path: ""  # .p8 파일 경로

android:
  enabled: true
  service_account_json: ""  # Google Play Service Account JSON 경로

# AdMob
admob:
  enabled: true
  ios_app_id: ""            # ca-app-pub-XXXX~YYYY
  android_app_id: ""        # ca-app-pub-XXXX~YYYY
  ad_units: []              # 파이프라인에서 안내 후 사용자 입력
```

### Step 5: State 초기화

`docs/harness/state.md` 생성:
```yaml
status: running
current_phase: research
current_round: 0
next_role: harness-research
created_at: YYYY-MM-DD HH:mm
updated_at: YYYY-MM-DD HH:mm
```

### Step 6: Git Commit

```bash
git add docs/harness/
git commit -m "chore: bootstrap harness pipeline"
```

### Step 7: Role Loop

파이프라인 Phase 순서:

```
1. Research  → Skill("harness-research")    # 시장 조사
2. Plan      → Skill("harness-plan")        # 기획/PRD
3. Design    → Skill("harness-design")      # 디자인 시스템
4. Contract  → Skill("harness-contract")    # 완료 기준 협상
5. Generator → Skill("harness-generator")   # 앱 빌드
6. Evaluator → Skill("harness-evaluator")   # QA
   ↳ FAIL → Generator로 돌아가 수정 (라운드 반복)
   ↳ PASS → 다음 Phase
7. AdMob     → Skill("harness-admob")       # 광고 통합
8. Build     → Skill("harness-build")       # EAS 빌드
9. Screenshot→ Skill("harness-screenshot")  # 스토어 스크린샷
10. Submit   → Skill("harness-submit")      # 스토어 제출
```

각 Phase 실행 후:
1. `state.md`의 `next_role` 업데이트
2. `pipeline-log.md`에 이벤트 기록
3. `build-log.md`에 라운드 결과 기록

### Role Loop 규칙

**Phase 전환 시:**
- Agent subprocess로 실행 (컨텍스트 리셋)
- 이전 Phase 산출물은 파일로 핸드오프

**Generator↔Evaluator 루프:**
- Round 1: Generator 빌드 → Evaluator QA
- Round 2+: Generator가 피드백 기반 수정 → Evaluator 재검증
- `max_rounds` 도달 시 강제 PASS 후 다음 Phase

**PAUSE 처리:**
- 수동 작업 필요 시 (AdMob, Android Play Console)
- `state.md` status를 `paused`로 변경
- AskUserQuestion으로 사용자에게 안내
- 사용자 확인 후 `status: running`으로 변경하고 계속

### Pipeline Log Format

`docs/harness/pipeline-log.md`:
```markdown
| Time | Event | Phase | Details |
|------|-------|-------|---------|
| 14:30 | DISPATCH | research | Agent subprocess started |
| 14:35 | COMPLETE | research | Spec generated |
| 14:36 | DISPATCH | plan | Agent subprocess started |
```

### Build Log Format

`docs/harness/build-log.md`:
```markdown
| Round | Phase | Score | Duration | Notes |
|-------|-------|-------|----------|-------|
| 1 | Build | - | 45m | Initial build |
| 1 | QA | 5/10 | 8m | 7 criteria failed |
| 2 | Build | - | 20m | Fix round |
| 2 | QA | 8/10 | 6m | PASS |
```

## HARD GATES

1. **config.md 필수**: config 없으면 진행 불가
2. **state.md 동기화**: 매 Phase 전환 시 반드시 업데이트
3. **Git commit per phase**: 각 Phase 완료 시 커밋
4. **PAUSE 존중**: 수동 작업 필요 시 반드시 사용자 확인 대기
