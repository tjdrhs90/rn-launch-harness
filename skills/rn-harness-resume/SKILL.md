---
name: rn-harness-resume
description: Resume a paused pipeline from saved state (after rate limit or manual action).
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# rn-harness-resume — 파이프라인 재개

일시정지된 파이프라인을 재개한다. 레이트 리밋, 수동 작업 완료 후 사용.

## Trigger

- `/rn-harness --resume`
- 자동 재개 (hooks/stop-failure-handler.sh)

## Process

### Step 0: 런 워크스페이스 탐색 (Locate the run)

각 런은 격리된 폴더에 있으므로 `state.md`가 고정 경로에 없다. 후보를 모두 찾는다:

```bash
# 스테이징 중인 런(Phase 1–4, depth 5) + 졸업한 프로젝트(Phase 5+, depth 4) 모두 스캔
find . -maxdepth 5 \
  \( -path './.rn-harness/*/docs/harness/state.md' \
     -o -path './*/docs/harness/state.md' \
     -o -path './docs/harness/state.md' \) 2>/dev/null
```

- **후보 1개** → 그 폴더가 워크스페이스. `workspace_dir`로 사용.
- **후보 여러 개** (여러 런이 진행/일시정지 중) → 각 `state.md`의 `run_id`·`current_phase`·`status`·`updated_at`을 요약해 **AskUserQuestion으로 어느 런을 재개할지** 선택받는다.
- **후보 0개** → 재개할 파이프라인 없음. 사용자에게 안내 후 종료.

선택된 워크스페이스로 `cd`한 뒤(이후 모든 경로는 그 안의 `docs/harness/` 기준) Step 1로 진행한다.

### Step 1: state.md 확인

```yaml
status: paused
pause_reason: [rate_limit | manual_action | error]
next_role: [재개할 스킬]
```

### Step 2: 재개 조건 확인

**rate_limit:**
- 레이트 리밋이 풀렸는지 확인
- 아직 제한 중이면 대기

**manual_action:**
- 사용자에게 수동 작업 완료 여부 확인
- AskUserQuestion: "수동 작업을 완료하셨나요?"

**error:**
- 에러 내용 확인
- 수정 가능하면 수정 후 재개
- 수정 불가하면 사용자에게 안내

### Step 3: 상태 복구

```yaml
status: running
pause_reason: ""
resume_attempts: N+1
updated_at: [현재 시간]
```

### Step 4: 역할 루프 재개

`next_role`에 해당하는 스킬 호출.

## Auto-Resume (hooks)

`hooks/stop-failure-handler.sh`가 레이트 리밋 감지 시:
1. `state.md` → `status: paused, pause_reason: rate_limit`
2. 리셋 시간 파싱
3. `at` 명령으로 자동 재개 스케줄
4. macOS 알림 발송

## HARD GATES

- 재개 전 반드시 런 워크스페이스를 특정하고 그 안에서 작업 (여러 런이면 사용자에게 선택받음)
- paused 상태가 아니면 재개 불가
- rate_limit인데 아직 제한 중이면 재개 금지
- manual_action인데 사용자 확인 없으면 재개 금지
