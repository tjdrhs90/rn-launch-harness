---
name: rn-harness-status
description: Display current pipeline progress, build rounds, scores, and state.
argument-hint: [--verbose] [--log]
allowed-tools: [Read, Bash, Glob, Grep]
---

# rn-harness-status — 파이프라인 상태 조회

현재 파이프라인 진행 상황을 표시한다.

## Trigger

- `/rn-harness --status`
- `/rn-harness-status`

## Arguments

- `--verbose` — 최신 피드백 요약 포함
- `--log` — 최근 20개 이벤트 표시

## Process

### Step 0: 런 워크스페이스 탐색

런은 격리된 폴더에 있으므로 `state.md`가 고정 경로에 없다:
```bash
find . -maxdepth 5 \
  \( -path './.rn-harness/*/docs/harness/state.md' \
     -o -path './*/docs/harness/state.md' \
     -o -path './docs/harness/state.md' \) 2>/dev/null
```
- 1개 → 그 워크스페이스 사용.
- 여러 개 → 각 `run_id`·`current_phase`·`status`를 한 줄씩 나열(여러 런 동시 표시). 특정 런만 보려면 사용자가 지정.
- 0개 → "진행 중인 파이프라인 없음".

이후 경로는 선택된 워크스페이스의 `docs/harness/` 기준.

### Step 1: state.md 읽기

`docs/harness/state.md`에서:
- status (running/paused/completed)
- current_phase
- current_round
- next_role

### Step 2: build-log.md 읽기

라운드별 결과 테이블.

### Step 3: 출력

```
[프로젝트명]
Status: [running/paused/completed]
Phase: [current_phase] | Round: [current_round]
Next: [next_role]

Pipeline Progress:
  [x] Research    — 완료
  [x] Plan        — 완료
  [x] Design      — 완료
  [x] Contract    — 완료
  [ ] Generator   — 진행 중 (Round 2)
  [ ] Evaluator
  [ ] AdMob
  [ ] Build
  [ ] Screenshot
  [ ] Submit

Round | Phase | Score | Duration | Notes
------|-------|-------|----------|------
  1   | Build |   -   | 45m      |
  1   | QA    | 5/10  | 8m       | 7 criteria failed
  2   | Build |   -   | 20m      | Fix round
```

`--verbose` 시:
```
Latest Feedback:
- [FAIL] 기준 3: SafeAreaView 누락 (profile.tsx)
- [FAIL] 기준 7: 에러 상태 미처리
- Score: 5/10
```

`--log` 시:
```
Recent Events:
| Time | Event | Phase | Details |
|------|-------|-------|---------|
| 14:30 | DISPATCH | generator | Round 2 시작 |
| 14:10 | JUDGMENT | evaluator | FAIL (5/10) |
| 13:25 | DISPATCH | evaluator | Round 1 QA |
```
