# rn-harness-retro — Harness Retrospective

Retrospective analysis of a project built with the RN Launch Harness pipeline. Evaluates the app against Anthropic's harness design principles and optionally verifies the app runs correctly.

> "Every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing." — Anthropic

## Trigger

- User invokes `/rn-harness-retro`
- Called after the full pipeline completes (post Phase 10: Submit)

## Arguments

Parse `$ARGUMENTS` for:
- `[project-dir]` — Target project path (default: current directory)
- `--run-app` — Attempt to build and run the app, verify it works on simulator
- `--deep` — Deep analysis including source code review

---

## Phase 1: Collect Harness Outputs

### 1.1 Read All Harness Artifacts

Read every file in `docs/harness/` and `docs/specs/`:

```
docs/harness/state.md          → Pipeline state
docs/harness/config.md         → Configuration
docs/harness/contract.md       → Contract (Generator-Evaluator agreement)
docs/harness/build-log.md      → Build log (rounds, scores)
docs/harness/pipeline-log.md   → Pipeline event log
docs/harness/plans/            → PRD and planning documents
docs/harness/feedback/         → QA feedback (all rounds)
docs/harness/handoff/          → Handoff documents (all rounds)
docs/harness/screenshots/      → Screenshots taken during evaluation
docs/specs/                    → Spec files and progress dashboard
```

Read all files and reconstruct the full pipeline history.

### 1.2 Git History Analysis

```bash
git log --oneline --all
git log --format="%h %s" --since="$(cat docs/harness/state.md | grep created_at | cut -d' ' -f2)"
```

Trace the build/QA cycle from commit messages. Identify:
- Number of build rounds
- Generator vs Evaluator commits
- Phase transition points

### 1.3 App Run Verification (--run-app flag)

If `--run-app` is specified:

1. **Install dependencies**: `npm install`
2. **TypeScript check**: `npx tsc --noEmit` — must pass with 0 errors
3. **Lint check**: `npm run lint` — must pass with 0 errors
4. **Start Metro bundler**: `npx expo start`
5. **iOS Simulator**: `npx expo run:ios` — verify app launches without crash
6. **Android Emulator**: `npx expo run:android` — verify app launches without crash (if available)
7. **Spot-check contract criteria**: Pick 3-5 key criteria from contract.md and manually verify
8. **Console errors**: Check Metro output for red/yellow box errors

Record all results for the retro report.

---

## Phase 2: Evaluate Against Anthropic's Harness Principles

Reference: [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)

Evaluate the pipeline's adherence to each of the following 9 principles. For each principle, check the evidence, apply the checklist, and assign a star rating.

### P1. Generator-Evaluator Separation

> "Separating the agent doing the work from the agent judging it proves to be a strong lever."

**Checklist:**
- [ ] Generator and Evaluator executed as separate roles (different skill invocations)
- [ ] Evaluator did not modify source code (only `docs/harness/` files)
- [ ] Evaluator actually ran the app and tested it (screenshot evidence)
- [ ] Generator's self-assessment differed from Evaluator's assessment (skeptical evaluation)

**Evidence sources:** pipeline-log.md for generator/evaluator alternation, feedback/ files for FAIL verdicts

### P2. Evaluator Skepticism

> "Out of the box, Claude is a poor QA agent... would identify legitimate issues, then talk itself into deciding they weren't a big deal."

**Checklist:**
- [ ] Evaluator issued at least 1 FAIL verdict
- [ ] FAIL reasons were specific and reproducible (steps to reproduce included)
- [ ] No lenient "mostly works fine" style evaluations
- [ ] Scores actually improved across rounds (improving trend)

**Evidence sources:** feedback/ files score trends, specificity of FAIL reasons

### P3. Contract Negotiation Quality

> "The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal."

**Checklist:**
- [ ] contract.md exists and is in AGREED state
- [ ] Each criterion is machine-verifiable (screenshots, command output, etc.)
- [ ] Anti-stub verification is included
- [ ] Edge case verification is included
- [ ] Criteria count provides sufficient coverage relative to the spec

**Evidence sources:** contract.md criteria count and coverage mapping

### P4. File-Based Handoff

> "Communication was handled via files: one agent would write a file, another agent would read it."

**Checklist:**
- [ ] Handoff documents exist for each round (handoff/round-N-gen.md)
- [ ] Handoffs include build evidence (commit SHA, build success status)
- [ ] Evaluator read and responded to handoffs (evidence in feedback)
- [ ] state.md was correctly updated with next_role transitions

**Evidence sources:** handoff/ file existence, state.md change history

### P5. No Sprints (V2 Architecture)

> "I started by removing the sprint construct entirely."
> "The model handled 2+ hours of coherent building without sprint decomposition."

**Checklist:**
- [ ] Generator built the entire app in a single pass (no sprint decomposition)
- [ ] QA ran as a single pass at the end of each build round (not per-sprint QA)
- [ ] Build -> QA -> Fix -> Re-QA cycle iterated correctly

**Evidence sources:** build-log.md round structure

### P6. Screenshot-and-Study

> "The evaluator would navigate the page on its own, screenshotting and carefully studying the implementation."

**Checklist:**
- [ ] Evaluator launched the app on a simulator
- [ ] Screenshots saved in docs/harness/screenshots/ or feedback/
- [ ] Screenshots were read and visually analyzed (Read tool on image files)
- [ ] Multiple screens/routes were explored (free exploration)

**Evidence sources:** screenshot files, feedback references to visual verification

### P7. Simplicity

> "Find the simplest solution possible, and only increase complexity when needed."

**Checklist:**
- [ ] No unnecessary complexity added (excessive rounds, unnecessary roles)
- [ ] Each pipeline phase provided substantive value
- [ ] Planner scoped appropriately (neither under-scope nor over-scope)
- [ ] FSD layer structure was not over-engineered for the app's complexity

**Evidence sources:** pipeline-log.md phase durations, each phase's actual contribution

### P8. Cost-Quality Tradeoff

> 20x cost increase justified by 20x output quality improvement.

**Checklist:**
- [ ] Total pipeline duration and round count are recorded
- [ ] QA scores actually improved across rounds
- [ ] Final result shows meaningful quality improvement vs. a solo agent approach
- [ ] No wasted rounds (rounds with no score change)

**Evidence sources:** build-log.md score trends, total duration

### P9. Test Deduplication

> Comprehensive testing should avoid redundant test cases across evaluation passes.

**Checklist:**
- [ ] No duplicate or near-duplicate test cases across QA rounds
- [ ] Test scope was clearly defined per round (what to test, what was already PASS)
- [ ] Previously passing criteria were not re-tested unnecessarily
- [ ] Evaluator focused on failed/new criteria in subsequent rounds

**Evidence sources:** feedback/ files test case comparison across rounds

---

## Phase 3: App Verification (--run-app)

If `--run-app` was specified, compile the results from Phase 1.3:

| Item | Result | Notes |
|------|--------|-------|
| npm install | PASS/FAIL | [error details] |
| TypeScript check | PASS/FAIL | [error count] |
| Lint check | PASS/FAIL | [error count] |
| iOS Simulator launch | PASS/FAIL | [crash details] |
| Android Emulator launch | PASS/FAIL | [crash details] |
| Contract spot-check | N/M PASS | [failed items] |
| Console errors | N found | [severity] |

---

## Phase 4: Write Retro Report

Generate `docs/harness/retro.md`:

```markdown
# Harness Retrospective — [Project Name]

> Generated: [date]
> Pipeline duration: [start ~ end]
> Total rounds: [N]
> Final QA score: [score]

## App Verification Results

| Item | Result | Notes |
|------|--------|-------|
| Build | PASS/FAIL | [error details] |
| TypeScript | PASS/FAIL | [error count] |
| Lint | PASS/FAIL | [error count] |
| iOS Launch | PASS/FAIL | [details] |
| Android Launch | PASS/FAIL | [details] |
| Contract Spot-check | N/M PASS | [failed items] |
| Console Errors | N found | [severity] |

## Anthropic Principle Adherence

| Principle | Rating | Summary |
|-----------|--------|---------|
| P1. Generator-Evaluator Separation | ★★★☆☆ | [one-line assessment] |
| P2. Evaluator Skepticism | ★★★☆☆ | [one-line assessment] |
| P3. Contract Negotiation | ★★★☆☆ | [one-line assessment] |
| P4. File-Based Handoff | ★★★☆☆ | [one-line assessment] |
| P5. No Sprints (V2) | ★★★☆☆ | [one-line assessment] |
| P6. Screenshot-and-Study | ★★★☆☆ | [one-line assessment] |
| P7. Simplicity | ★★★☆☆ | [one-line assessment] |
| P8. Cost-Quality Tradeoff | ★★★☆☆ | [one-line assessment] |
| P9. Test Deduplication | ★★★☆☆ | [one-line assessment] |

### Detailed Analysis per Principle

#### P1. Generator-Evaluator Separation
**Rating: ★★★☆☆**

[Evidence-based detailed analysis. Include checklist results.]

... (repeat for P2 through P9)

## Keep (What Went Well)
1. [Specific example with evidence]
2. ...

## Improve (What Needs Improvement)
1. [Specific example with improvement direction]
2. ...

## Try (Experiments for Next Project)
1. [Ideas to experiment with in the next pipeline run]
2. ...

## Harness Improvement Suggestions
[Based on this project's experience, improvement points for rn-launch-harness itself]
```

## Rating Scale

| Rating | Meaning |
|--------|---------|
| ★★★★★ | Principle perfectly implemented. On par with Anthropic's reference examples. |
| ★★★★☆ | Principle well followed. Minor room for improvement. |
| ★★★☆☆ | Basics followed but some gaps or superficial adherence. |
| ★★☆☆☆ | Principle only partially followed. Substantive improvement needed. |
| ★☆☆☆☆ | Principle barely implemented. |

---

## Completion

After writing the retro report:

1. Git commit: `docs: harness retrospective report`
2. Present the top 3 key findings to the user as a summary
3. If `--deep` was used, include specific code-level observations in the report
