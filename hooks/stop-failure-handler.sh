#!/bin/bash
# stop-failure-handler.sh
# 레이트 리밋 발생 시 자동 재개 스케줄링

set -euo pipefail

# 런은 격리된 워크스페이스에 있으므로 state.md 경로가 고정이 아니다.
# 스테이징(.rn-harness/*/), 졸업 프로젝트(*/), 레거시(docs/) 중
# status: running 인 state.md를 찾아 가장 최근 것을 고른다.
STATE_FILE=""
while IFS= read -r candidate; do
  [ -f "$candidate" ] || continue
  status=$(grep "^status:" "$candidate" 2>/dev/null | head -1 | awk '{print $2}' || true)
  [ "$status" = "running" ] || continue
  if [ -z "$STATE_FILE" ] || [ "$candidate" -nt "$STATE_FILE" ]; then
    STATE_FILE="$candidate"
  fi
done < <(find . -maxdepth 5 \
  \( -path './.rn-harness/*/docs/harness/state.md' \
     -o -path './*/docs/harness/state.md' \
     -o -path './docs/harness/state.md' \) 2>/dev/null)

# running 상태의 하네스가 없으면 종료
[ -n "$STATE_FILE" ] || exit 0

STATE_DIR=$(dirname "$STATE_FILE")
LOG_FILE="$STATE_DIR/pipeline-log.md"

# 에러 메시지에서 rate_limit 감지
ERROR_MSG="${CLAUDE_STOP_ERROR:-}"
if echo "$ERROR_MSG" | grep -qi "rate.limit\|too.many.requests\|429"; then
  # state.md 업데이트
  sed -i '' 's/^status:.*/status: paused/' "$STATE_FILE"

  # pause_reason 추가/업데이트
  if grep -q "^pause_reason:" "$STATE_FILE"; then
    sed -i '' 's/^pause_reason:.*/pause_reason: rate_limit/' "$STATE_FILE"
  else
    echo "pause_reason: rate_limit" >> "$STATE_FILE"
  fi

  # 로그 기록
  TIMESTAMP=$(date "+%H:%M")
  echo "| $TIMESTAMP | PAUSED | rate_limit | Auto-pause due to rate limit |" >> "$LOG_FILE"

  # macOS 알림
  if command -v osascript &> /dev/null; then
    osascript -e 'display notification "Rate limit hit. Auto-resume scheduled." with title "RN Launch Harness" sound name "Glass"'
  fi

  # 5분 후 자동 재개 스케줄
  # NOTE: `at` 잡은 기본적으로 $HOME에서 실행되므로, resume 스킬이 워크스페이스를
  # 탐색하려면 반드시 이 실행 디렉터리(run-directory root)로 cd 해줘야 한다.
  # macOS에선 atrun이 기본 비활성 — 자동재개를 쓰려면 한 번:
  #   sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist
  RUN_DIR="$(pwd)"
  echo "cd $(printf %q "$RUN_DIR") && claude --skill rn-harness-resume" | at now + 5 minutes 2>/dev/null || true

  echo "Rate limit detected. Pipeline paused. Auto-resume in 5 minutes."
fi
