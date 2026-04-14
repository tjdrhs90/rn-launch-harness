---
name: rn-harness
description: React Native app launch harness — from market research to App Store & Google Play submission. One command takes you from idea to store review.
argument-hint: <app description> [--resume] [--status] [--rounds <N>] [--ref <url-or-image>] [--strict] [--with-spec] [--skip-research] [--skip-admob]
allowed-tools: [Agent, Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch, AskUserQuestion, TaskCreate, TaskUpdate]
---

# /rn-harness — RN Launch Harness

React Native 모바일 앱을 아이디어부터 스토어 출시까지 자동화하는 메인 오케스트레이터.

## Arguments

- `"앱 설명"` — 새 파이프라인 시작 (아이디어가 있을 때)
- (인자 없음) — 아이디어 발굴부터 시작 (스토어 탑차트 조사 → 1인개발 가능한 앱 추천)
- `--resume` — Resume paused pipeline
- `--status` — Check progress
- `--rounds <N>` — Max QA rounds per phase (default: **3**)
- `--ref <url-or-image>` — Reference material (repeatable)
- `--skip-research` — Skip market research
- `--skip-admob` — Skip AdMob integration
- `--strict` — Enable full 3-phase QA + Agent Team (costs more tokens)
- `--with-spec` — Enable Phase 2.5 spec planning with task checklists

## Execution

### Step 0: Argument Parsing

```
if --status → Skill("rn-harness-status")
if --resume → Skill("rn-harness-resume")
```

Save app description as `$APP_IDEA`.

### Step 1: Bootstrap

**Project structure:** The harness creates `docs/harness/` in the current working directory for pipeline artifacts. The actual Expo project is created as a **subdirectory** during Phase 5 (Generator), named after the app (kebab-case).

```
current-directory/          ← claude session here (history preserved)
├── docs/harness/           ← pipeline artifacts
│   ├── specs/
│   ├── plans/
│   ├── handoff/
│   ├── feedback/
│   ├── references/
│   ├── screenshots/
│   ├── store-assets/
│   ├── config.md
│   ├── state.md
│   ├── build-log.md
│   └── pipeline-log.md
└── $APP_SLUG/              ← Expo project (created in Phase 5)
    ├── app/
    ├── src/
    ├── .env
    ├── credentials/
    └── ...
```

`$APP_SLUG` is derived from the app name in kebab-case (e.g., "가계부 앱" → `budget-book`, "커피 구독" → `coffee-tracker`). Determined during Phase 2 (Plan) and stored in `config.md` as `app_slug`.

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
max_rounds: 3                # Default 3 (use --rounds to override)
strict_mode: false           # Default off (--strict enables 3-phase QA + Agent Team)
with_spec: false             # Default off (--with-spec enables Phase 2.5)
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
next_role: rn-harness-research
created_at: YYYY-MM-DD HH:mm
updated_at: YYYY-MM-DD HH:mm
```

### Step 6: Git Commit

```bash
git add docs/harness/
git commit -m "chore: bootstrap harness pipeline"
```

### Step 7: Role Loop

Pipeline phase order depends on mode:

#### Default Mode (token-efficient, ~$30-60)

```
 1. Research   → Skill("rn-harness-research")     # Market research
 2. Plan       → Skill("rn-harness-plan")         # PRD
 3. Design     → Skill("rn-harness-design")       # Design system
 4. Contract   → Skill("rn-harness-contract")     # 1-pass: propose → confirm → done
 5. Generator  → Skill("rn-harness-generator")    # Build app (3 sub-phases)
 6. Evaluator  → Skill("rn-harness-evaluator")    # Functional QA only (Phase 6.1)
    ↳ FAIL → Generator fix → re-evaluate (max 3 rounds)
    ↳ PASS → Next phase
 7. AdMob      → Skill("rn-harness-admob")        # Smart ad placement
 8. Build      → Skill("rn-harness-build")        # EAS Build
 9. Screenshot → Skill("rn-harness-screenshot")   # Store screenshots
10. Submit     → Skill("rn-harness-submit")       # App Store + Google Play
```

#### --strict Mode (thorough, ~$100-160)

```
 1. Research   → Skill("rn-harness-research")     # Market research
 2. Plan       → Skill("rn-harness-plan")         # PRD
 2.5 Spec      → Skill("rn-harness-spec")         # Task checklists (if --with-spec)
 3. Design     → Skill("rn-harness-design")       # Design system
 4. Contract   → Skill("rn-harness-contract")     # Multi-round negotiation
 5. Generator  → Skill("rn-harness-generator")    # Build app (3 sub-phases)
 6. Evaluator  → 3-Phase Progressive QA:
    6.1 Functional → Does it WORK? (typecheck, lint, contract)
    6.2 Quality    → Is it GOOD? (design 4-axis, states)
    6.3 Edge Cases → Can it SURVIVE? (6 Agent Team + simulator)
    Each: FAIL → Generator fix → re-evaluate (max rounds per phase)
 7. AdMob      → Skill("rn-harness-admob")
 8. Build      → Skill("rn-harness-build")
 9. Screenshot → Skill("rn-harness-screenshot")
10. Submit     → Skill("rn-harness-submit")
11. Retro      → Skill("rn-harness-retro")        # Pipeline retrospective
```

각 Phase 실행 후:
1. `state.md`의 `next_role` 업데이트
2. `pipeline-log.md`에 이벤트 기록
3. `build-log.md`에 라운드 결과 기록

### Role Loop 규칙

**Phase 전환 시:**
- Agent subprocess로 실행 (컨텍스트 리셋)
- 이전 Phase 산출물은 파일로 핸드오프

**Generator↔Evaluator Loop:**

Default mode:
- Evaluator runs **Phase 6.1 (Functional)** only
- FAIL → Generator fixes → re-evaluate
- Max `max_rounds` (default 3) then force PASS
- Single-phase keeps costs low

Strict mode (`--strict`):
- Phase 6.1 (Functional) → 6.2 (Quality) → 6.3 (Edge Cases)
- Each phase has its own round limit
- Phase 6.3 launches 6 parallel Agent Team
- `max_rounds` per QA phase → force advance to next phase

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
