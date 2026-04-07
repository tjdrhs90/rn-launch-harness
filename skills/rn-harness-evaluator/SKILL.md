# rn-harness-evaluator — Phase 5: 3-Phase Progressive QA

Verifies the Generator's build against contract criteria through a progressive 3-phase evaluation pipeline.

## Principle

**"Run the code, see the app, then judge."** Never PASS based on code review alone. Execute commands, capture screenshots when possible, and verify independently.

## Trigger

Called by the orchestrator for Phase 5 (Evaluator). The orchestrator sets the **QA phase** (5.1, 5.2, or 5.3) and the **evaluator profile**.

## Input

- `docs/harness/contract.md` (completion criteria)
- `docs/harness/handoff/round-N-gen.md` (Generator handoff)
- `docs/harness/config.md` — read `evaluator` field for profile selection
- `references/evaluation-criteria.md` (scoring rubrics)
- Actual project source code

## Evaluator Profiles

Read the `evaluator` field from `docs/harness/config.md` to determine the profile:

| Profile | Behavior |
|---------|----------|
| `default` | Full 3-phase QA (5.1 → 5.2 → 5.3) |
| `quick` | Phase 5.1 only (functional check). Skip design and edge cases. |
| `strict` | All 3 phases with lower pass thresholds: Design 8+, ALL 6 edge-case teammates must PASS with zero warnings |

If no `evaluator` field is found, use `default`.

---

## Phase 5.1: Functional (Does it WORK?)

The foundation gate. If the code does not compile, lint, pass tests, and meet the contract, nothing else matters.

### Step 1: Run Automated Checks

```bash
npm run typecheck 2>&1
npm run lint 2>&1
npm test 2>&1
```

Record every result. Any error = automatic FAIL for that criterion.

### Step 2: NativeWind 6-Check Gate (CRITICAL)

Verify all 6 configuration points:

1. `babel.config.js` — `jsxImportSource` + `nativewind/babel` plugin
2. `metro.config.js` — `withNativeWind` wrapper
3. `tailwind.config.js` — `nativewind/preset` + correct `content` paths
4. `global.css` — `@tailwind base/components/utilities` directives
5. Root `_layout.tsx` — `import "./global.css"` present
6. `nativewind-env.d.ts` — `/// <reference types="nativewind/types" />`

**ANY missing item = FULL FAIL** (className will not work at runtime).

### Step 3: FSD Architecture Validation

```bash
# any type usage
grep -r ":\s*any" src/ --include="*.ts" --include="*.tsx" | grep -v node_modules
grep -r "<any>" src/ --include="*.ts" --include="*.tsx" | grep -v node_modules

# FSD layer violations (features importing from features)
grep -r "from '@features/" src/features/ --include="*.ts" --include="*.tsx"

# barrel export check
find src/features src/entities -name "index.ts" -type f
```

- `any` type count > 0 → FAIL
- FSD cross-layer violation > 0 → FAIL
- Missing barrel export → FAIL

### Step 4: Contract Criteria Verification

For EACH criterion in `docs/harness/contract.md`:

1. Perform actual verification (run command or analyze specific code with file:line evidence)
2. Determine PASS or FAIL
3. Record evidence (command output, code reference, or test result)

Evidence types: `typecheck`, `lint`, `test`, `code` (file:line), `runtime` (simulator output)

### Step 5: Stub Detection

```bash
grep -rn "TODO\|FIXME\|HACK\|XXX\|STUB\|setTimeout.*mock\|placeholder\|dummy" src/ --include="*.ts" --include="*.tsx"
```

Any stub found = FAIL.

### Step 6: End-to-End Data Flow Check

Trace at least one complete data flow from user action → state change → UI update. Verify the chain is real, not mocked.

### Phase 5.1 Judgment

**PASS conditions (ALL must be met):**
- typecheck errors: 0
- lint errors: 0
- `any` types: 0
- FSD violations: 0
- NativeWind config: complete
- SafeAreaView: present on all screens
- Stubs: 0
- ALL contract criteria: PASS
- Tests: all passing
- End-to-end data flow: verified

**FAIL → Return feedback to Generator with specific fix instructions.**

If evaluator profile is `quick`, stop here after Phase 5.1 and issue final judgment.

---

## Phase 5.2: Quality (Is it GOOD?)

Only entered after Phase 5.1 PASS.

### Step 1: Design 4-Axis Scoring

Score each axis 1-10 using `references/evaluation-criteria.md` rubrics:

| Axis | Weight | Criteria |
|------|--------|----------|
| Design Quality | 30% | Consistency, identity, color/typography/layout harmony |
| Originality | 25% | Custom design decisions, avoidance of template/AI slop |
| Craft | 25% | Spacing consistency, typographic hierarchy, contrast ratios |
| Functionality | 20% | Usability, accessibility, interaction quality |

Weighted total = (DQ * 0.3) + (O * 0.25) + (C * 0.25) + (F * 0.20)

### Step 2: Console and Build Warnings

```bash
npm run typecheck 2>&1 | grep -i "warning"
npm run lint 2>&1 | grep -i "warning"
```

Record all warnings. While warnings do not auto-FAIL, they factor into Craft scoring.

### Step 3: Interaction States Audit

Every screen and data-dependent component MUST have:

- **Loading state** — ActivityIndicator or custom skeleton
- **Error state** — Error message + retry action
- **Empty state** — Helpful guidance when no data exists

Check every screen file for all three states.

### Step 4: Responsive Layout Check

Verify layouts work across different screen sizes:
- Check for hardcoded pixel widths (should use flex/percentage/responsive units)
- Verify ScrollView or FlashList for content that may overflow
- Check horizontal layout assumptions that could break on narrow screens

### Phase 5.2 Judgment

**PASS conditions:**
- Design weighted total: 7/10 or higher (8/10 for `strict` profile)
- ALL interaction states present (loading, error, empty) on every data screen
- No critical responsive layout issues

**FAIL → Return feedback with specific design/UX fix instructions.**

---

## Phase 5.3: Edge Cases (Can it SURVIVE?)

Only entered after Phase 5.2 PASS.

### Step 1: Screenshot-and-Study (Simulator-Based)

Before scoring, attempt to run the app on a simulator and capture screenshots:

```bash
# Check if Maestro is available
which maestro
```

**If Maestro IS available:**

1. Generate a quick Maestro flow YAML that navigates through all screens and takes screenshots:
   ```bash
   # Create maestro directory if needed
   mkdir -p maestro

   # Generate qa-flow.yaml based on app's navigation structure
   # (analyze _layout.tsx and navigation config to build the flow)
   ```

2. Run the flow:
   ```bash
   npx expo start --ios &
   sleep 10
   maestro test maestro/qa-flow.yaml
   ```

3. Store screenshots in `docs/harness/screenshots/round-N/`

4. Read each screenshot with the Read tool to visually analyze the app — check for layout issues, misalignments, broken UI, and visual quality.

**If Maestro is NOT available:**

Fall back to code-only analysis. Note this as a limitation in the feedback report:
```
> NOTE: Maestro not available. Phase 5.3 performed via code analysis only.
> Visual verification was not possible. Consider installing Maestro for full QA.
```

### Step 2: Agent Team (6 Parallel Sub-Agents)

Launch 6 parallel sub-agents using the **Agent tool**. Each agent focuses on a specific testing dimension. ALL 6 must PASS for Phase 5.3 to PASS.

#### Agent 1: Component Tester
- Verify every UI component in `src/` renders correctly
- Check prop types are properly defined
- Verify component composition (no god components)
- Check that interactive elements have proper press handlers
- Verify NativeWind className usage is correct on each component

#### Agent 2: E2E Flow Tester
- Trace every user journey from entry to completion
- Verify navigation flow matches the spec
- Check data persistence (AsyncStorage, state management)
- Verify deep linking if applicable
- Confirm back navigation works correctly at every level

#### Agent 3: Edge Case Tester
- Empty input submission handling
- Double tap / rapid press protection
- Back button behavior at every screen
- Large data sets (check FlashList estimatedItemSize, keyExtractor)
- Boundary values (max length inputs, special characters, emoji)
- Network error simulation handling
- Offline state handling (if applicable)

#### Agent 4: Code Quality Inspector
- Unused imports detection
- Dead code identification
- Potential memory leaks (unsubscribed listeners, intervals without cleanup)
- Missing cleanup in useEffect return
- Accessibility audit (accessibilityLabel, accessibilityRole)
- Console.log statements left in code
- Hardcoded strings that should be constants

#### Agent 5: Test Case Generator
- Generate comprehensive test cases for untested code paths
- Write the test cases to `__tests__/` directory
- Run the generated tests
- Share test results with other teammates via handoff notes
- Identify coverage gaps

#### Agent 6: Adversarial Reviewer
- Challenge every PASS judgment from Agents 1-5
- Look for scenarios the other agents missed
- Try to find ways the app could crash or misbehave
- Check for security issues (exposed keys, unsanitized input)
- Verify error boundaries exist and work
- Question optimistic assumptions

### Phase 5.3 Judgment

**PASS conditions:**
- ALL 6 agent teammates return PASS
- No critical or major bugs found
- Screenshots (if available) show no visual defects

**FAIL → Return comprehensive feedback from all failing agents.**

---

## Output

Write evaluation results to `docs/harness/feedback/round-N-qa.md`:

```markdown
# Evaluator Feedback — Round N

## Phase: [5.1 | 5.2 | 5.3]
## Profile: [default | quick | strict]
## Score: X/10
## Trend: [improving | stagnant | declining]
## Judgment: [PASS | FAIL]

## Phase 5.1: Functional
### Test Results
- typecheck: [PASS/FAIL] — [error count]
- lint: [PASS/FAIL] — [error count]
- test: [PASS/FAIL] — [X/Y passed]

### NativeWind Setup
- [PASS/FAIL] — [missing items if any]

### FSD Compliance
- any types: [count]
- Layer violations: [list]
- Barrel exports: [missing list]

### Contract Verification
- [PASS] Criterion 1: [evidence]
- [FAIL] Criterion 2: [expected vs actual]
...

### Stub Detection
- [list of stubs found, or "None"]

### End-to-End Data Flow
- [traced flow description and verification result]

## Phase 5.2: Quality (if reached)
### Design Quality
| Axis | Score | Evidence |
|------|-------|----------|
| Design Quality | X/10 | ... |
| Originality | X/10 | ... |
| Craft | X/10 | ... |
| Functionality | X/10 | ... |
| **Weighted Total** | **X/10** | |

### Console/Build Warnings
- [list or "None"]

### Interaction States
- Screen A: loading [Y/N], error [Y/N], empty [Y/N]
- Screen B: loading [Y/N], error [Y/N], empty [Y/N]
...

### Responsive Layout
- [findings]

## Phase 5.3: Edge Cases (if reached)
### Simulator Screenshots
- [available / not available]
- [screenshot analysis findings]

### Agent Team Results
| Agent | Result | Key Findings |
|-------|--------|-------------|
| Component Tester | [PASS/FAIL] | ... |
| E2E Flow Tester | [PASS/FAIL] | ... |
| Edge Case Tester | [PASS/FAIL] | ... |
| Code Quality Inspector | [PASS/FAIL] | ... |
| Test Case Generator | [PASS/FAIL] | ... |
| Adversarial Reviewer | [PASS/FAIL] | ... |

## Bugs Found
1. **[critical]** [description] — [file:line]
2. **[major]** [description] — [file:line]
3. **[minor]** [description] — [file:line]

## Reasoning
[Comprehensive justification for the PASS/FAIL judgment]

## Fix Instructions (if FAIL)
[Ordered list of specific fixes the Generator must make, with file paths and expected changes]
```

## State Update

### On PASS (all required phases complete):
```yaml
current_phase: admob
next_role: rn-harness-admob
```

### On FAIL:
```yaml
next_role: rn-harness-generator
current_round: N+1
```

### On Phase Progression (e.g., 5.1 PASS → 5.2):
The orchestrator advances the QA sub-phase. The evaluator is re-invoked for the next phase.

---

## HARD GATES

These rules are absolute and cannot be overridden:

1. **No code-review-only PASS** — Commands MUST be executed before judgment
2. **Ignore Generator self-assessment** — "38/38 DONE" means nothing. Verify independently.
3. **No judgment without typecheck/lint/test execution** — Run all three, always
4. **No progression without NativeWind verification** — Gate blocks all phases
5. **Stub detected = automatic FAIL** — No exceptions
6. **`max_rounds` reached = forced judgment** — Evaluate current state as-is
7. **Phase order is mandatory** — Cannot skip to 5.2 without 5.1 PASS, cannot skip to 5.3 without 5.2 PASS
8. **Agent team disagreement = FAIL** — If ANY of the 6 agents in Phase 5.3 returns FAIL, the phase FAILS
9. **Screenshots are evidence** — When simulator screenshots are available, they MUST be analyzed before judgment
