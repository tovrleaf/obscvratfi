# 4. Development Testing and Validation Requirements

**Status:** Accepted

**Date:** 2025-12-30 (Updated: 2026-01-25)

## Context

The project has a GitHub Actions CI/CD pipeline (see ADR-003) that validates all code changes before merge:
- Shell script linting (shellcheck)
- YAML linting (yamllint)
- Markdown linting (markdownlint)
- TOML linting (tomli)
- Hugo build validation
- HTML validation (html5validator)
- Secret scanning (TruffleHog)
- Critical link validation

However, developers must push changes to GitHub to get feedback on these validations. This creates friction:
- Commits to wrong branch before discovering linting issues
- Multiple rounds of commits to fix validation failures
- Waiting for GitHub Actions to run (5-15 minutes per run)
- Wasted GitHub Actions runner minutes on easily preventable issues

Additionally, automated validation doesn't catch functional issues:
- Scripts with correct syntax but broken logic
- Templates that build successfully but don't display content correctly
- Test artifacts being committed to the repository
- Real content being accidentally deleted during cleanup
- Changes that work in isolation but break integration

Current workflow problems:
1. Developer makes changes locally
2. Developer commits and pushes to GitHub
3. GitHub Actions runs (5-15 minutes)
4. Developer discovers validation failures
5. Developer fixes and pushes again
6. Repeat until all checks pass
7. Functional issues discovered only after deployment

Better workflow:
1. Developer makes changes locally
2. Developer tests changes manually (functional verification)
3. Pre-commit hooks run automatically (automated validation)
4. Developer fixes issues (if any)
5. Developer pushes to GitHub
6. GitHub Actions re-validates (final safety check)
7. One push succeeds first time with working functionality

## Decision

We will implement a two-layer testing approach:

### Layer 1: Automated Validation (Pre-Commit Hooks)

**Local pre-commit hooks** using the `pre-commit` framework that mirror the GitHub Actions validation checks.

**Architecture Overview:**

**Framework:** pre-commit (Python-based, language-agnostic hook runner)
- Runs before git push (not before commit, to allow WIP commits)
- Catches issues locally within seconds
- Interactive error reporting with clear guidance
- One-command setup: `make setup-hooks`
- Optional bypass for edge cases: `git push --no-verify`

**Hooks to Implement (Mirror GitHub Actions):**

1. **Shell Script Linting (shellcheck)**
   - Validates: `scripts/*.sh`
   - Catches: syntax errors, bad practices, portability issues

2. **YAML Linting (yamllint)**
   - Validates: `.github/workflows/*.yml`, `docker-compose.yml`, etc.
   - Catches: format errors, indentation issues, structure problems

3. **Markdown Linting (markdownlint)**
   - Validates: `docs/**/*.md`, `README.md`, etc.
   - Catches: formatting issues, link problems, consistency

4. **TOML Linting (tomli)**
   - Validates: `website/hugo.toml`, `Dockerfile` config
   - Catches: syntax errors, invalid formats

5. **Hugo Build Validation**
   - Validates: Hugo site builds successfully
   - Catches: template errors, broken links in content
   - Uses: Local Hugo installation

6. **HTML Validation (html5validator)**
   - Validates: Generated HTML (errors only, not warnings)
   - Catches: HTML structure problems

7. **Secret Scanning (TruffleHog)**
   - Validates: No AWS keys, tokens, or secrets in commits
   - Catches: Accidental credential exposure

8. **Critical Link Validation (Custom)**
   - Validates: 6 essential internal links work
   - Links: `/`, `/about/`, `/live/`, `/albums/`, `/feed.xml`, `/sitemap.xml`
   - Uses: Custom bash script with curl

**Configuration Files:**

```
.pre-commit-config.yaml         # Main hook configuration
.pre-commit-hooks.yaml          # Custom hook definitions (link validator)
scripts/pre-push-link-checker.sh # Custom link validation script
```

**Setup & Usage:**

```bash
# One-time setup (installs dependencies, git hook)
make setup-hooks

# Manual run of all checks (optional)
make run-hooks

# Uninstall hooks (if needed)
make uninstall-hooks

# Push normally (hooks run automatically before push)
git push

# Emergency bypass (only when necessary)
git push --no-verify
```

**Error Handling Strategy:**

When a hook fails:
1. Hook displays clear error message with file names and line numbers
2. Error message includes explanation of what's wrong
3. Error message includes how to fix it (when possible)
4. Developer fixes the issue
5. Developer attempts push again (hooks run again automatically)
6. Option to bypass with `--no-verify` if truly necessary (logged for audit)

**Stage Where Hooks Run:**

- **Pre-push stage** (not pre-commit): Allows `git commit` to work freely but blocks `git push` if issues exist
- Rationale: Developers can make WIP commits locally without friction, but can't push broken code to GitHub

### Post-Commit Shellcheck Hook

In addition to pre-push hooks, a **post-commit hook** runs shellcheck immediately after commits that modify shell scripts:

**Behavior:**
- Runs automatically after `git commit` if any `.sh` files were committed
- Only checks shell scripts in that specific commit
- Non-blocking (commit is already made)
- Provides immediate feedback with fix instructions

**Installation:**
The post-commit hook is installed automatically with `make hooks setup`.

**Manual Testing:**
```bash
# Run shellcheck on all scripts
make test sh

# Run shellcheck on scripts in last commit
make test sh-commit
```

**Fix Workflow:**
If shellcheck finds issues after commit:
1. Fix the issues shown in the output
2. Stage the fixes: `git add <files>`
3. Amend the commit: `git commit --amend --no-edit`

**Requirements:**
- Shellcheck must be installed: `brew install shellcheck` (macOS) or via pre-commit framework

### Layer 2: Manual Functional Testing

**Manual testing requirements** for changes that automated validation cannot catch.

#### Script Testing Requirements

When modifying shell scripts, test before committing:

1. **Syntax validation:** Run `bash -n script.sh` to check for syntax errors
2. **Functional testing:** Execute the script with test inputs to verify behavior
3. **Edge cases:** Test with empty inputs, invalid inputs, and boundary conditions
4. **Integration:** Verify the script works with related files and commands
5. **Cleanup:** Remove test artifacts and restore to pre-testing state

Example workflow:
```bash
# Check syntax
bash -n scripts/manage-media.sh

# Test the script interactively or with test data
./scripts/manage-media.sh

# Verify generated files are correct
cat website/content/media/others.md

# Clean up test artifacts (restore to state before testing)
rm -f website/content/media/others.md  # if created during testing
git restore website/content/media/others.md  # if modified during testing
git clean -fd  # remove any untracked files created during testing
```

**Important:** Always restore the repository to the state it was in before testing. Do not commit test artifacts or accidentally delete real content.

#### Template/Webpage Testing Requirements

When modifying Hugo templates or layouts, test by building the site:

1. **Syntax validation:** Check template syntax is valid
2. **Build test:** Compile the site to verify no errors
3. **Output verification:** Check generated HTML in `website/public/`
4. **Do not start server:** Test by building and searching source, not by running server

Example workflow:
```bash
# Build the site
cd website && hugo

# Check for errors in build output
cd website && hugo 2>&1 | grep ERROR

# Verify generated HTML
cat website/public/media/index.html | grep "others-section"

# Clean up if needed
rm -rf website/public/
```

**Important:** Do not hand back modified templates without building and verifying the output.

#### General Testing Principles

- **Test before commit:** Never commit untested code
- **Restore state:** Always return repository to pre-testing state
- **Distinguish test vs real data:** Be careful not to delete real content during cleanup
- **Document in AGENTS.md:** Testing requirements are also documented in AGENTS.md for AI agents

## Alternatives Considered

### Alternative 1: No Local Validation (Current State)
- Rely only on GitHub Actions for validation
- **Pros:**
  - No local setup needed
  - Single source of truth (GitHub Actions)
  - Works on any machine without dependencies
  - Simpler onboarding
- **Cons:**
  - Slow feedback loop (5-15 minutes per push)
  - Wasted GitHub Actions runner minutes
  - Developer context lost between error detection and fix
  - Multiple commits needed to fix validation issues
  - Frustrating experience for developers
- **Why rejected:** Poor developer experience; GitHub Actions minutes wasted on preventable issues

### Alternative 2: Pre-Commit Hooks (Pre-Commit Stage)
- Run hooks before `git commit` (not push)
- **Pros:**
  - Catches issues earlier
  - Prevents creation of "broken" commits
  - Enforces clean commit history
- **Cons:**
  - Blocks WIP commits (work-in-progress)
  - Developers frustrated by inability to save work-in-progress
  - Forces developers to perfect code before committing
  - Not suitable for iterative development
- **Why rejected:** Too restrictive for iterative workflow; pre-push is better balance

### Alternative 3: Pre-Receive Hooks on Server
- Enforce validation on GitHub server-side (push rejection)
- **Pros:**
  - Prevents any broken code reaching repository
  - Single enforcement point
  - No local dependencies needed
- **Cons:**
  - Slower feedback (must push first)
  - Already handled by branch protection rules
  - Redundant with GitHub Actions
  - Doesn't help local development experience
- **Why rejected:** GitHub Actions + branch protection already provide this; doesn't help local workflow

### Alternative 4: Manual Pre-Push Checklist
- Developer manually runs checks before pushing
- **Pros:**
  - No automation needed
  - Fully manual control
  - No dependencies to install
- **Cons:**
  - Easy to forget steps
  - Inconsistent execution
  - No enforcement
  - Defeats purpose of automation
- **Why rejected:** Human error-prone; automation is essential

### Alternative 5: Custom Shell Script Wrapper
- Wrap git push with custom bash script that runs checks
- **Pros:**
  - Custom control
  - No external dependencies (other than tools themselves)
  - Language-agnostic
- **Cons:**
  - More complex to maintain
  - Less standardized (not using established tool)
  - Harder to onboard new developers
  - Difficult to share across team
  - Reinventing the wheel (pre-commit framework exists)
- **Why rejected:** pre-commit framework is more maintainable and standardized

### Alternative 6: Manual Testing Only (No Requirements)
- Let developers test however they want
- **Pros:**
  - Simple, no enforcement
  - Flexible approach
  - No documentation needed
- **Cons:**
  - Easy to forget or skip
  - Inconsistent across developers
  - Leads to broken commits
  - No guidance for new developers
- **Why rejected:** Recent issues show manual testing without requirements leads to broken code

### Alternative 7: Automated Functional Tests
- Write automated tests for all scripts and templates
- **Pros:**
  - Catches functional issues automatically
  - Consistent enforcement
  - No manual work needed
- **Cons:**
  - Time-consuming to write tests
  - Complex to maintain
  - Not all functionality can be easily tested
  - Overkill for simple scripts
- **Why rejected:** Manual testing is sufficient for current needs; can add automated tests later if needed

## Consequences

### Positive
- **Fast feedback:** Validation results within seconds instead of 5-15 minutes
- **Fewer bad pushes:** Issues caught before reaching GitHub
- **Reduced wasted CI minutes:** Don't run GitHub Actions on preventable failures
- **Better developer experience:** Clear errors with solutions right in the terminal
- **Consistency:** Same checks run locally and in CI (single source of truth)
- **Flexibility:** `--no-verify` bypass available for edge cases
- **Lightweight:** Runs only on files that changed (efficient)
- **WIP-friendly:** Pre-push stage allows developers to commit WIP code locally
- **Educational:** Developers learn best practices through linting feedback
- **Cost savings:** Fewer GitHub Actions runs = lower (or zero) cost
- **Fewer broken commits:** Manual testing catches functional issues before commit
- **Faster feedback:** Manual testing provides immediate feedback (seconds vs minutes)
- **Cleaner git history:** Working code committed, not broken code
- **Better understanding:** Hands-on testing improves code comprehension

### Negative
- **Setup complexity:** Developers must run `make setup-hooks` first
- **Additional dependencies:** Requires Python 3.9+, pre-commit framework
- **Performance impact:** Validation adds 10-30 seconds to every push
- **Learning curve:** Developers unfamiliar with pre-commit framework
- **Bypass temptation:** `--no-verify` flag can be abused
- **Environment differences:** Issues caught by local hooks might not match CI exactly
- **Hugo dependency:** Hugo validation requires local Hugo installation (v0.128.2+)
- **Maintenance:** Need to keep `.pre-commit-config.yaml` in sync with GitHub Actions
- **Requires discipline:** Manual testing easy to skip without enforcement
- **Adds time:** Testing adds time to development process
- **Cleanup risk:** Can accidentally delete real content if not careful
- **No automation:** Manual testing not enforced by tooling

### Neutral
- **Pre-push vs pre-commit:** Pre-push stage is middle ground (not earliest possible intervention)
- **Caching:** pre-commit framework caches validated files efficiently
- **Tool versions:** Local hook versions might differ slightly from GitHub Actions
- **Bypass logging:** Can't easily audit `--no-verify` usage
- **Parallel execution:** Hooks run sequentially by default (could parallelize if needed)
- **Documentation:** Testing requirements documented in both ADR and AGENTS.md
- **Two-layer approach:** Automated + manual testing complement each other

## Notes

- **Installation:** Run `make setup-hooks` once after cloning repository
- **Dependencies:** Requires Python 3.9+ for pre-commit framework itself (other tools are native/Docker-based)
- **Scope:** Only validates files changed in current push (efficient)
- **Consistency:** Hooks exactly mirror GitHub Actions checks for consistency
- **Customization:** `.pre-commit-config.yaml` allows disabling individual hooks if needed
- **Performance:** Expected 10-30 second runtime per push (varies by file count)
- **Hugo:** Uses local Hugo installation (same version as production)
- **Link validation:** Custom script validates 6 critical endpoints after build
- **Related:** ADR-003 describes GitHub Actions pipeline that local hooks mirror
- **Future:** Could expand to include unit tests once test suite established
- **Team:** Recommended setup instruction should be added to `CONTRIBUTING.md`
- **CI as backup:** GitHub Actions remains final safety check even with local hooks
- **Manual testing:** Also documented in AGENTS.md for AI agent reference
- **Two-layer approach:** Automated validation (pre-commit hooks) + manual testing (functional verification)
- **Future:** Consider automated functional tests if manual testing becomes insufficient
- **Future:** Add make targets for common testing workflows (e.g., `make test-scripts`)

## Implementation Plan

When ready to implement (future work):

1. Create `.pre-commit-config.yaml` with all hook definitions
2. Create `.pre-commit-hooks.yaml` for custom link validator
3. Create `scripts/pre-push-link-checker.sh` for link validation
4. Update `Makefile` with `setup-hooks`, `run-hooks`, `uninstall-hooks` targets
5. Update `README.md` with local development setup section
6. Update `CONTRIBUTING.md` with setup instructions
7. Update `.gitignore` for pre-commit cache directory (`.pre-commit`)
8. Document any environment-specific setup needs
9. Test setup process from clean repository clone
10. Commit all changes with reference to this ADR

