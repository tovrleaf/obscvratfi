# 6. Repository Branch Protection with GitHub Rulesets

**Status:** Accepted

**Date:** 2025-12-30

## Context

The repository currently has no branch protection on the `main` branch. This creates several risks:

- Developers can accidentally push directly to `main` without code review
- Unvalidated code (failing GitHub Actions checks) can reach production
- No enforcement of pull request workflow
- Easy to accidentally overwrite important branch with force push
- No audit trail of who approved changes

The project already has:
- GitHub Actions CI/CD pipeline (`pr-checks.yml`) validating all PRs
- Local pre-commit hooks for developer validation (ADR-005)
- Clear branching conventions in CONTRIBUTING.md
- Manual deployment process (not automated)

The challenge is enforcing a code review workflow while keeping setup simple and allowing self-approval (since this is a personal repository).

## Decision

We will implement **GitHub Repository Rulesets** to protect the `main` branch with the following configuration:

**Ruleset Name:** `Protect Main Branch`

**Target:** `main` branch only

**Enforcement:** Active (fully enforced, not test mode)

**Rules Applied:**

1. **Pull Request Required**
   - All code changes must go through pull requests
   - Direct pushes to `main` are blocked
   - Self-approval is allowed (one approval required)
   - Stale reviews are dismissed on new pushes

2. **Resolve Conversations**
   - All discussions/review comments must be resolved
   - Prevents merging PRs with unresolved feedback

3. **Required Status Checks**
   - GitHub Actions workflow (`pr-checks.yml`) must pass
   - PR must be up-to-date with latest `main` before merge
   - Strict mode enabled

4. **Allowed Merge Methods**
   - Merge commits: `merge`
   - Squash and merge: `squash`
   - Rebase and merge: `rebase`
   - All three allowed for flexibility

**Admin Bypass:** Not configured
- Repository owner (you) can still bypass rules in emergency situations
- GitHub allows admin override even when not explicitly configured

**Workflow After Implementation:**

```
1. Create feature branch from main
   ↓
2. Make changes, commit, push to origin
   ↓
3. Create Pull Request to main
   ↓
4. GitHub Actions runs validation (pr-checks.yml)
   ↓
5. If CI fails: Fix issues and push updates
   If CI passes: Continue to step 6
   ↓
6. Review code (can be your own approval)
   ↓
7. Resolve any conversations/feedback
   ↓
8. Merge to main (via GitHub UI)
   ↓
9. Ready for deployment
```

## Alternatives Considered

### Alternative 1: No Branch Protection
- **Pros:**
  - No setup required
  - No restrictions on pushing
  - Maximum flexibility
  - Faster workflow (one less step)
- **Cons:**
  - Risk of accidentally pushing to main
  - Can bypass CI/CD checks
  - No audit trail of approvals
  - Easy to break production with direct push
  - No code review enforcement
- **Why rejected:** Risk of accidental production breaks outweighs minor workflow simplification

### Alternative 2: Legacy Branch Protection Rules
- GitHub's older protection mechanism
- **Pros:**
  - Simpler API (deprecated but still works)
  - Web UI is straightforward
- **Cons:**
  - Less flexible than rulesets
  - Fewer options for customization
  - Legacy technology (newer features don't support it)
  - Harder to automate with scripts
  - GitHub recommending migration to rulesets
- **Why rejected:** Rulesets are the modern standard with better automation support

### Alternative 3: Manual GitHub Web UI Setup
- Configure protection directly in GitHub repository settings
- **Pros:**
  - No scripts needed
  - Straightforward GUI
  - Clear visual feedback
- **Cons:**
  - Not reproducible or documented in code
  - Hard to version control the configuration
  - No audit trail of when/why it was changed
  - Difficult to transfer to new repository
  - Manual steps hard to automate on other machines
- **Why rejected:** Infrastructure-as-code approach (scripts) is more maintainable and auditable

### Alternative 4: Require Two Approvals
- Enforce two independent approvals before merge
- **Pros:**
  - Higher code review standard
  - Better for multi-person teams
- **Cons:**
  - Overkill for solo developer
  - Blocks all PRs (even tiny fixes)
  - Slower workflow without team members
  - Not necessary for personal project
- **Why rejected:** One approval sufficient for personal repository; can be increased later if team grows

### Alternative 5: Require Code Owner Review
- Enforce approval from CODEOWNERS file
- **Pros:**
  - Ensures designated reviewers approve specific files
  - Good for large teams with specialized areas
- **Cons:**
  - No CODEOWNERS file yet (not needed)
  - Requires setup and maintenance
  - Overkill for single developer
  - Can be added later when team structure requires it
- **Why rejected:** Not applicable to personal repository without team structure

## Consequences

### Positive
- **Prevents Accidents:** Cannot accidentally push directly to main
- **Enforces Workflow:** All code goes through pull requests with review
- **Quality Assurance:** CI/CD must pass before merge possible
- **Audit Trail:** GitHub records who approved what and when
- **Conversation Resolution:** Forces addressing all feedback before merge
- **Easy Rollback:** PRs can be closed and rework done if needed
- **Self-Approval:** Can approve own PRs (no bottleneck for solo developer)
- **Automation:** Setup and verification via scripts (infrastructure-as-code)
- **Documentation:** ADR documents why this decision was made
- **Flexible:** Can adjust rules later without recreating from scratch

### Negative
- **Extra Step:** Adds one more step to workflow (create PR instead of direct push)
- **Slight Overhead:** Takes few extra minutes to create and review own PR
- **Learning Curve:** New developers need to learn PR workflow
- **GitHub Dependency:** Requires GitHub to be accessible (can't commit when GitHub down)
- **API Limit Consideration:** Using gh CLI counts toward rate limits (very minor)

### Neutral
- **Admin Override Available:** Repository owner can bypass in true emergencies
- **Discussions Resolution:** Requires resolving conversations (good practice anyway)
- **Status Checks:** GitHub Actions must pass (already required locally by ADR-005)
- **Stale Review Dismissal:** New commits dismiss old approvals (encourages fresh review)
- **Self-Approval Allowed:** Supports solo development workflow
- **No Breaking Changes:** Existing PRs not affected, applies to future changes

## Notes

- **Repository Info:** Extracted from git config (`git@github.com:tovrleaf/obscvratfi.git`)
- **Setup Scripts:** Three scripts provided for automation:
  - `scripts/protect-main-branch.sh` - Create the ruleset (idempotent)
  - `scripts/list-branch-rules.sh` - View current rulesets
  - `scripts/remove-branch-protection.sh` - Emergency rollback
- **Makefile Targets:** Easy access to scripts via `make protect-main`, `make show-branch-rules`, `make unprotect-main`
- **Documentation:** CONTRIBUTING.md updated with branch protection workflow section
- **Idempotent:** Scripts check if ruleset exists before creating (safe to run multiple times)
- **Integration with Existing Systems:**
  - Works with GitHub Actions CI/CD (ADR-003)
  - Works with local pre-commit hooks (ADR-005)
  - Enforces branching conventions in CONTRIBUTING.md
- **Future Changes:**
  - Can adjust approval count if team grows
  - Can add required reviewers when needed
  - Can add code owner requirements later
  - Can add deployment protection rules for production
- **Related ADRs:**
  - ADR-003: Website hosting and GitHub Actions CI/CD
  - ADR-005: Local pre-commit hooks for development validation

## Implementation Plan

When ready to implement (future work):

1. Create `scripts/protect-main-branch.sh` for automated ruleset creation
2. Create `scripts/list-branch-rules.sh` to view rulesets
3. Create `scripts/remove-branch-protection.sh` for emergency rollback
4. Update `Makefile` with three new targets
5. Update `CONTRIBUTING.md` with branch protection workflow section
6. Update `docs/adr/README.md` to include ADR-006
7. Test scripts work correctly and ruleset is created
8. Verify branch protection is enforced (try pushing to main, should fail)
9. Commit all changes with reference to ADR-006

## Detailed Rule Configuration

For reference, the GitHub Ruleset API configuration:

```json
{
  "name": "Protect Main Branch",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"]
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true,
        "allowed_merge_methods": ["merge", "squash", "rebase"]
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          {
            "context": "pr-checks.yml"
          }
        ]
      }
    }
  ]
}
```

**Rules Explained:**

- `required_approving_review_count: 1` - Need 1 approval (self-approval allowed)
- `dismiss_stale_reviews_on_push: true` - New commits dismiss old approvals (fresh review)
- `require_code_owner_review: false` - Not using CODEOWNERS (no team structure)
- `require_last_push_approval: false` - Last push doesn't need different approver (solo dev)
- `required_review_thread_resolution: true` - Must resolve all conversations
- `allowed_merge_methods: ["merge", "squash", "rebase"]` - Allow all merge methods
- `strict_required_status_checks_policy: true` - PR must be up-to-date with main
- `context: "pr-checks.yml"` - GitHub Actions workflow must pass
