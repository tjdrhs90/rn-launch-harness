#!/bin/bash
# stop-failure-handler.sh
# 레이트 리밋 발생 시 자동 재개 스케줄링

set -euo pipefail

STATE_FILE="docs/harness/state.md"
LOG_FILE="docs/harness/pipeline-log.md"

# state.md가 없으면 하네스 프로젝트가 아님
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# 현재 상태 확인
CURRENT_STATUS=$(grep "^status:" "$STATE_FILE" | head -1 | awk '{print $2}')
if [ "$CURRENT_STATUS" != "running" ]; then
  exit 0
fi

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
  echo "claude --skill harness-resume" | at now + 5 minutes 2>/dev/null || true

  echo "Rate limit detected. Pipeline paused. Auto-resume in 5 minutes."
fi
