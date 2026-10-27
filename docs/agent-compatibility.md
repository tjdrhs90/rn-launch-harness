# Multi-Agent Compatibility Guide

`rn-launch-harness` is designed to be **agent-agnostic**. While originally built as a Claude Code plugin, its underlying architecture—file-based handoffs (`docs/harness/`), contract negotiations, and strict hard gates—runs identically across any modern AI coding assistant (Antigravity, OpenAI Codex, Claude Code, Cursor, etc.).

---

## Tool Mapping Across Environments

| Feature | Claude Code | Google Antigravity | OpenAI Codex / CLI |
| :--- | :--- | :--- | :--- |
| **Harness Entry** | `/rn-harness "idea"` | `/rn-harness "idea"` | `@rn-harness "idea"` or task prompt |
| **Phase Skill Call**| `Skill("rn-harness-<phase>")` | Read `skills/rn-harness-<phase>/SKILL.md` | Execute skill file or injection |
| **Subagent Spawn** | `Agent(role, prompt)` | `invoke_subagent` (TypeName="self") | Subprocess agent execution |
| **User Gate Input** | `AskUserQuestion` | `ask_question` / user prompt | Stdin / question tool |
| **Handoff Data** | `docs/harness/state.md` | `docs/harness/state.md` | `docs/harness/state.md` |

---

## How to Set Up in Your Agent Environment

### 1. Claude Code
Install via Claude Code plugin marketplace or clone directly into `.claude-plugin/`:
```bash
claude plugin add rn-launch-harness
```
Invoke with:
```
/rn-harness "My Habit Tracker App"
```

### 2. Google Antigravity
Link the harness skills into your workspace's `.agents/skills/`:
```bash
mkdir -p .agents/skills
ln -s /path/to/rn-launch-harness/skills/rn-harness .agents/skills/rn-harness
```
Once linked, Antigravity automatically detects the skill frontmatter. Invoke naturally or via slash command:
```
/rn-harness "My Habit Tracker App"
```

### 3. OpenAI Codex & CLI Agents
Provide the root `skills/rn-harness/SKILL.md` as the guiding instruction or orchestrator skill. The orchestrator reads `docs/harness/state.md` and dispatches each phase task sequentially, preserving full isolation and hard gates.
