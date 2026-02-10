# Workflow: Lint Fix Changed Files

You are the **Orchestrator Agent** coordinating a linting fix workflow.

## Objective

Fix all linting errors in changed/staged files by alternating between Test Agent and Build Agent until all checks pass.

## Workflow Steps

### 1. Test Agent - Check for linting errors

Delegate to Test Agent:
- Check changed files: `git diff --name-only --cached` (staged) and `git diff --name-only` (unstaged)
- Run appropriate linting:
  - `make test sh-commit` - Shell scripts in last commit
  - `make test yaml-commit` - YAML files in last commit
  - `make test md-commit` - Markdown files in last commit
  - `make test py` - Python files
- Report any linting errors found

### 2. Build Agent - Fix errors (if any found)

If Test Agent found errors, delegate to Build Agent:
- Fix the specific linting errors reported
- Use auto-fix tools where possible (e.g., `ruff --fix`)
- Report what was fixed

### 3. Test Agent - Verify fixes

Delegate back to Test Agent:
- Re-run linting on the same files
- Confirm all issues are resolved

### 4. Repeat if needed

If Test Agent still finds errors, repeat steps 2-3.

### 5. Report success

When all linting passes, report:
"✅ All linting checks passed for changed files"

## Agent Alternation Pattern

```
Test Agent → finds errors
     ↓
Build Agent → fixes errors
     ↓
Test Agent → verifies fixes
     ↓
(repeat if needed)
     ↓
Success
```

## Important Notes

- Only test changed/staged files, not entire codebase
- Do not commit - just fix and verify
- Continue until all linting passes
- Report clear status at each step
