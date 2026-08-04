---
name: rn-harness-acceptance
description: Phase 7.5 — Human acceptance gate before store build. Runs an automated Maestro E2E smoke test on a real simulator/emulator, then PAUSES for the user to run the app themselves and explicitly approve before any EAS/local build or store submission.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

# rn-harness-acceptance — Phase 7.5: User Acceptance Gate

The last checkpoint **before irreversible work** (store build → submission). The agent Evaluator (Phase 6) already judged that the app *works*; this phase asks a different question a machine can't answer: **"is this the app the user actually wanted, and are they OK shipping it?"**

Runs **after AdMob (Phase 7)** so the user reviews the real, ad-integrated app, and **before Build (Phase 8)** so nothing gets built or submitted without an explicit human yes.

```
Evaluator PASS → AdMob → [👤 THIS PHASE] → Build → Screenshots → Submit
```

## Trigger

Called by the orchestrator as Phase 7.5. Skipped only if `config.md → skip_acceptance: true` (e.g. unattended CI) — and even then, log loudly that a human gate was bypassed.

## Input

- Project code (AdMob integration complete)
- `docs/harness/plans/YYYY-MM-DD-prd.md` (PRD — core user journeys)
- `docs/harness/config.md`

## Two parts

### Part 1: Automated E2E Smoke (objective floor)

Give the human a **known-good starting point** — don't ask them to approve an app that fails its own core flows.

**Why Maestro:** the screenshot phase already uses it, so it's a cheap add. Maestro drives the real app on a simulator/emulator via YAML flows. (Alternatives: Detox — RN-specific, heavier setup; Appium — cross-platform, heaviest. Default to Maestro here.)

1. **Launch the app** (AdMob = native module → **Expo Go will crash**; use a dev client / native run):
   ```bash
   # iOS (macOS + Xcode)
   npx expo run:ios
   # Android (SDK + emulator)
   npx expo run:android
   ```

2. **Create/reuse E2E flows** under `.maestro/` — one flow per core user journey from the PRD. Keep them smoke-level (does the happy path work end to end), not exhaustive:
   ```yaml
   # .maestro/smoke_core.yaml
   appId: com.company.app
   ---
   - launchApp
   - assertVisible: "<home screen anchor text>"
   - tapOn: "<primary CTA>"
   - assertVisible: "<expected next screen>"
   # ...one block per PRD journey (create, list, edit, navigate, etc.)
   ```

3. **Run the flows:**
   ```bash
   maestro test .maestro/
   ```

4. **Report** per-flow pass/fail. Any failure → this is a bug the Evaluator missed: hand back to Generator with the failing flow as evidence, then re-run. Do **not** advance to the human step on a red smoke test (unless the user explicitly overrides).

> This is automated regression coverage — it answers "does it still work," not "is it good." That second question is Part 2.

### Part 2: Human Acceptance PAUSE (subjective judgment)

Set `state.md` status to `paused`, then **AskUserQuestion**:

```
앱이 기능 QA + E2E 스모크를 통과했습니다. 스토어 빌드/제출 전에 직접 확인해 주세요.

▶ 실행 방법:
  npx expo run:ios      # 또는
  npx expo run:android
  (AdMob 통합 상태라 Expo Go 아님 — 위 명령으로 dev 빌드 실행)

▶ 자동 E2E 스모크 결과:
  [flow별 PASS/FAIL 요약]

직접 써보고 아래에서 선택하세요:
```

| 선택지 | 결과 |
|--------|------|
| 승인 — 빌드 진행 | `status: running` → Phase 8 (Build)로 진행 |
| 수정 요청 | 피드백을 `docs/harness/feedback/`에 기록 → Generator(Phase 5)로 되돌림 → 재QA |
| 중단 | `status: paused` 유지, 파이프라인 정지 |

- "수정 요청" 선택 시 **구체적으로 무엇을 고칠지** 사용자 입력을 받아 feedback 파일로 저장하고 Generator에 핸드오프.
- 승인 전에는 **어떤 빌드/제출 명령도 실행 금지.**

## Output

`docs/harness/handoff/acceptance-result.md`:

```markdown
# User Acceptance — Phase 7.5

## Automated E2E (Maestro)
- Flows run: [N]
- Passed: [N] / Failed: [N]
- Failing flows: [list or none]

## Human Decision
- Result: [APPROVED / CHANGES_REQUESTED / ABORTED]
- Reviewed on: [simulator/device]
- Feedback (if changes requested): [text → docs/harness/feedback/...]
- Approved by: user
```

## State Update

On approval:
```yaml
current_phase: build
next_role: rn-harness-build   # or rn-harness-build-local per config build.method
```
On changes requested:
```yaml
current_phase: generator
next_role: rn-harness-generator
```

## HARD GATES

- E2E smoke must PASS before presenting the app for approval (or user explicitly overrides a known failure)
- **No build or submission command runs before explicit user approval** — this is the whole point of the gate
- AdMob apps: never launch via Expo Go (crashes) — use `expo run:*` / dev client
- "Changes requested" must capture concrete feedback and route back to Generator, not silently loop
- If `skip_acceptance: true`, log a loud warning that the human gate was bypassed
