# rn-harness-resume — 파이프라인 재개

일시정지된 파이프라인을 재개한다. 레이트 리밋, 수동 작업 완료 후 사용.

## Trigger

- `/rn-harness --resume`
- 자동 재개 (hooks/stop-failure-handler.sh)

## Process

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

- paused 상태가 아니면 재개 불가
- rate_limit인데 아직 제한 중이면 재개 금지
- manual_action인데 사용자 확인 없으면 재개 금지
