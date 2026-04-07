# rn-harness-spec — Phase 2.5: Spec Planning

Breaks down the PRD into file-level task checklists under `docs/specs/`, organized by feature and implementation phase. Sits between Plan (Phase 2) and Design (Phase 3).

## Trigger

Called by the orchestrator after Phase 2 (Plan) completes.

## Input

- `docs/harness/plans/YYYY-MM-DD-prd.md` (PRD from Phase 2)
- `docs/harness/config.md`

## Process

### Step 1: Extract Feature List

Read the PRD and extract the full list of features to implement.
Map each feature to the FSD module structure defined in the PRD (features/, entities/, widgets/, shared/).

Sort features by priority:
- P0 features first (MVP required)
- P1 features next (important)
- P2 features last (future roadmap)

### Step 2: Create Feature Spec Directories

For each feature, create a numbered directory under `docs/specs/`:

```
docs/specs/
├── 01-auth/
├── 02-home/
├── 03-profile/
├── ...
└── README.md
```

The `NN` prefix reflects implementation priority order (01, 02, 03...).

### Step 3: Generate Phase Files

Inside each feature directory, create phase markdown files:

```
docs/specs/01-auth/
├── phase1-mvp.md           # Core MVP functionality
├── phase2-enhancement.md   # Enhancements and extensions
└── phase3-polish.md        # Optimization and polish (if needed)
```

Phase breakdown rules:
- **Phase 1 (MVP)**: Minimum viable implementation — types, API, store, core UI, screen, barrel export
- **Phase 2 (Enhancement)**: Extended features — validation, error states, loading states, edge cases
- **Phase 3 (Polish)**: Optimization — animations, accessibility, performance tuning

P0 features should have at least Phase 1 and Phase 2.
P1 features may only have Phase 1.
P2 features are documented but not given phase files (noted in README as future scope).

### Step 4: Write Tasks in Checkbox Format

Each phase file must follow this exact structure:

```markdown
---
feature: auth
phase: 1
title: MVP - Authentication
status: not-started
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Phase 1: MVP - Authentication

## Tasks

### Entity Setup
- [ ] `src/entities/user/types/index.ts` — IUser interface definition
- [ ] `src/entities/user/store/index.ts` — Zustand user store

### Feature Implementation
- [ ] `src/features/auth/api/auth.api.ts` — Login/signup API calls
- [ ] `src/features/auth/hooks/useLogin.ts` — Login mutation hook
- [ ] `src/features/auth/hooks/useRegister.ts` — Signup mutation hook
- [ ] `src/features/auth/store/index.ts` — Token management store
- [ ] `src/features/auth/ui/LoginForm.tsx` — Login form component
- [ ] `src/features/auth/types/index.ts` — Auth-related types
- [ ] `src/features/auth/index.ts` — Barrel export

### Screen Implementation
- [ ] `app/(auth)/login.tsx` — Login screen
- [ ] `app/(auth)/register.tsx` — Register screen

### QA
- [ ] typecheck passes
- [ ] lint passes
- [ ] feature functions correctly
```

Task format rules:
- Every task line starts with `- [ ]`
- File path in backticks, followed by ` — ` (em dash) and a brief description
- Group tasks by FSD layer: Entity Setup, Feature Implementation, Screen Implementation, Widget (if applicable), Shared (if applicable)
- Always end each phase with a QA section

### Step 5: Generate Progress Dashboard

Create `docs/specs/README.md` as a progress dashboard:

```markdown
# Spec Dashboard

> Generated: YYYY-MM-DD
> Source PRD: docs/harness/plans/YYYY-MM-DD-prd.md

## Progress Overview

| # | Feature | Phase 1 | Phase 2 | Phase 3 | Status |
|---|---------|---------|---------|---------|--------|
| 01 | auth | 0/12 | 0/8 | - | not-started |
| 02 | home | 0/9 | 0/5 | - | not-started |
| 03 | profile | 0/7 | - | - | not-started |

## Feature Details

### 01-auth
- Phase 1: MVP - Authentication (12 tasks)
- Phase 2: Enhancement - Auth polish (8 tasks)

### 02-home
- Phase 1: MVP - Home feed (9 tasks)
- Phase 2: Enhancement - Feed optimization (5 tasks)

...

## Future Scope (P2)
- [ ] Feature X — deferred to post-launch
- [ ] Feature Y — deferred to post-launch
```

### Step 6: User Confirmation

Present the spec structure summary via AskUserQuestion:
- Total number of features and tasks
- Phase breakdown per feature
- Estimated scope
- Ask for adjustments before proceeding

## Spec Frontmatter Schema

```yaml
---
feature: {feature-name}        # Matches directory name (without NN prefix)
phase: {1|2|3}                 # Implementation phase
title: {phase title}           # Human-readable title
status: {not-started|in-progress|completed}
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
---
```

## Checkbox Update Rules (Phase 5: Generator)

During Phase 5 (Generator), as the Generator implements each file:

1. Update the corresponding task: `- [ ]` to `- [x]`
2. Update the frontmatter `updated` date
3. When all tasks in a phase are checked, set `status: completed`
4. Update `docs/specs/README.md` dashboard counts (e.g., `3/12`)
5. Update dashboard status column based on progress:
   - `not-started` — 0 tasks completed
   - `in-progress` — at least 1 task completed
   - `completed` — all tasks completed

## Output

```
docs/specs/
├── 01-{feature}/
│   ├── phase1-mvp.md
│   ├── phase2-enhancement.md
│   └── phase3-polish.md (optional)
├── 02-{feature}/
│   ├── phase1-mvp.md
│   └── phase2-enhancement.md
├── ...
└── README.md
```

## State Update

```yaml
current_phase: design
next_role: rn-harness-design
```

## HARD GATES

- Every task must include a file path — no vague descriptions like "implement auth"
- File paths must follow FSD layer conventions (features/, entities/, shared/, widgets/)
- YAML frontmatter required on every phase file
- README.md dashboard must be generated
- QA section required in every phase file
- User confirmation required before proceeding to Phase 3
- P0 features must have at minimum Phase 1 tasks defined
