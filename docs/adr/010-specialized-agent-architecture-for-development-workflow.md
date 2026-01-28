# ADR-010: Specialized Agent Architecture for Development Workflow

**Status:** Accepted  
**Date:** 2026-01-26  
**Deciders:** Niko Kivela  
**Tags:** #agents #workflow #automation #git

## Context

The project uses Kiro CLI with AI agents to assist development.
Initially, we had a single build agent handling all tasks - planning,
implementation, and git operations. This created several issues:

1. **Mixed responsibilities:** One agent doing planning, coding, and
   committing
2. **Poor commit messages:** Build agent focused on implementation, not
   git workflow
3. **No validation checkpoint:** Changes committed without review
4. **Unclear workflow:** No separation between "make changes" and
   "commit changes"

We need a clear agent architecture that separates concerns and improves
workflow quality.

## Decision

Implement a **three-agent architecture** with specialized roles:

### 1. Plan Agent

**Purpose:** Architecture decisions, research, task breakdown

**Capabilities:**

- Read entire codebase
- Search web for research
- Write to `docs/adr/**` (ADR creation)
- Access to: README, AGENTS.md, CONTRIBUTING.md, ADRs

**Responsibilities:**

- Identify when ADRs are needed
- Research alternatives and present pros/cons
- Break down complex tasks into steps
- Create and update ADRs
- Guide architectural decisions

**Limitations:**

- Cannot write code
- Cannot run commands
- Cannot commit changes

### 2. Build Agent

**Purpose:** Implementation, testing, making code changes

**Capabilities:**

- Read entire codebase
- Write to all files except `.git/**`
- Run commands: `make`, `hugo`, `git status`, `git diff`

**Responsibilities:**

- Implement planned features
- Run tests and validations
- Make minimal, focused changes
- Follow established patterns
- Check what changed (`git status`, `git diff`)

**Limitations:**

- Cannot commit changes
- Cannot push to remote
- Cannot create ADRs (delegates to Plan Agent)

### 3. Commit Agent

**Purpose:** Git workflow, commit messages, validation

**Capabilities:**

- Read entire codebase
- Run git commands: `status`, `diff`, `add`, `commit`, `push`
- Access to: CONTRIBUTING.md (commit format)

**Responsibilities:**

- Review changes made by Build Agent
- Stage files intelligently (group related changes)
- Write commit messages following CONTRIBUTING.md format
- Run pre-commit checks
- Create atomic commits
- Reference issues/ADRs in messages
- Suggest splitting large changes

**Limitations:**

- Cannot write code
- Cannot modify files
- Only handles git operations

## Workflow

```text
User Request
    ↓
Plan Agent (if architectural decision needed)
    ↓ (creates ADR, breaks down tasks)
Build Agent (implements changes)
    ↓ (makes code changes, runs tests)
Commit Agent (commits changes)
    ↓ (validates, writes proper commit message)
Done
```

**Example:**

```text
User: "Add HTML validation to testing"
  ↓
Plan Agent: Research options, create plan
  ↓
User: Switch to Build Agent
  ↓
Build Agent: Implement html5lib validation, add make commands
  ↓
Build Agent: "Changes ready. Run 'git status' to review."
  ↓
User: Switch to Commit Agent
  ↓
Commit Agent: Review changes, create commit with proper message
  ↓
Done
```

## Agent Handoff

Since agents cannot directly communicate, handoff happens through:

1. **User orchestration:** User switches between agents manually
2. **Conversation context:** New agent sees previous conversation
3. **Git state:** Commit Agent checks `git status` to see Build Agent's
   work
4. **Agent instructions:** Each agent ends with next step suggestion

## Consequences

### Positive

- **Clear separation of concerns:** Each agent has one job
- **Better commit messages:** Specialized agent follows format
  consistently
- **Validation checkpoint:** Commit Agent reviews before committing
- **Prevents accidents:** Build Agent can't commit half-finished work
- **Improved quality:** Plan Agent ensures architectural decisions are
  documented
- **Focused context:** Each agent has only relevant tools and resources

### Negative

- **More context switching:** User must switch between agents
- **No automatic handoff:** User orchestrates the workflow
- **Learning curve:** User needs to know which agent to use when

### Neutral

- **Three agents to maintain:** More configuration files
- **Workflow discipline required:** User must follow the pattern

## Alternatives Considered

### 1. Single Agent (Current State)

**Pros:** Simple, no context switching  
**Cons:** Mixed responsibilities, poor commit messages, no validation  
**Rejected:** Quality issues outweigh simplicity

### 2. Two Agents (Plan + Build with Git)

**Pros:** Fewer agents, less switching  
**Cons:** Build Agent still handles both code and commits  
**Rejected:** Doesn't solve commit message quality issue

### 3. Four+ Agents (Add Review, Deploy, Test, Content)

**Pros:** Even more specialized  
**Cons:** Too much complexity for current needs  
**Deferred:** Can add later if needed

## Implementation

1. ✅ Create Plan Agent config (`.kiro/agents/plan.json`)
2. ⏳ Update Build Agent to remove commit access
3. ⏳ Create Commit Agent config
4. ⏳ Update AGENTS.md with workflow guidance
5. ⏳ Test workflow with real changes

## Related

- ADR-002: Decision Making Workflow
- AGENTS.md: Agent guidelines
- CONTRIBUTING.md: Commit message format

## Notes

Future agents to consider:

- **Review Agent:** Code review, security checks, quality validation
- **Deploy Agent:** Handle AWS deployments and infrastructure
- **Content Agent:** Manage Hugo content (gigs, albums)
- **Test Agent:** Run and analyze test suites
