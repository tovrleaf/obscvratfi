# Agent Guidelines for Obscvrat

This document provides guidelines for AI coding agents working in this repository.

## Prerequisites

Enable the subagent feature in Kiro CLI (required for multi-agent
workflows):

```bash
kiro-cli settings chat.enableSubagent true
```

This is a one-time global setting that enables subagent functionality
across all projects.

## MCP Servers

The project uses Model Context Protocol (MCP) servers to provide specialized tools for agents.

### Gear Management Server

Located in `.mcp/gear-server/`, provides tools for managing the gear inventory:

- **add_gear** - Add new gear with validation
- **list_gear** - List all gear with optional filters  
- **search_gear** - Search by name, manufacturer, types, or description
- **update_gear** - Update existing gear fields
- **delete_gear** - Remove gear from inventory

**Configuration:** `.kiro/mcp.json`

**Usage:** Tools are automatically available to agents. See `.mcp/gear-server/README.md` for details.

**Benefits:**
- Type-safe data validation
- Consistent YAML formatting
- Duplicate prevention
- Atomic file operations

## Agent Workflow

The project uses a specialized five-agent architecture (see ADR-010):

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER REQUEST                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │ ORCHESTRATOR AGENT   │  Workflow Coordination
                  │                      │  • Delegates to agents
                  │  Read Only           │  • Monitors progress
                  │  + Delegate Tool     │  • Handles errors
                  │  + Git Status/Diff   │  • Reports status
                  └──────────┬───────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
     ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
     │  PLAN AGENT    │ │  BUILD AGENT   │ │  TEST AGENT    │
     │                │ │                │ │                │
     │  Read + Write  │ │  Read + Write  │ │  Read Only     │
     │  (docs/adr/)   │ │  (except ADRs) │ │  + Test Cmds   │
     │  + Web Search  │ │  + Shell       │ │                │
     └────────────────┘ └────────────────┘ └────────────────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ COMMIT AGENT   │  Git Workflow
                    │                │  • Reviews changes
                    │  Read Only     │  • Creates commits
                    │  + Git Cmds    │  • Writes messages
                    │  + Push/PR     │  • Pushes to remote
                    └────────┬───────┘
                             │
                             ▼
                    ┌────────────────┐
                    │   COMPLETED    │
                    └────────────────┘

Agent Responsibilities:
───────────────────────

ORCHESTRATOR - Coordinates multi-agent workflows
  • Delegates tasks to specialized agents
  • Monitors progress and handles errors
  • Manages test-fix-retest loops
  • Reports final status to user

PLAN - Architecture & Research
  • Creates ADRs
  • Researches alternatives
  • Breaks down tasks
  • Designs solutions

BUILD - Implementation
  • Writes code
  • Runs tests
  • Builds site
  • Makes changes

TEST - Validation (Optional)
  • Runs linters
  • Validates builds
  • Checks for secrets

COMMIT - Git Workflow
  • Reviews changes
  • Creates atomic commits
  • Writes commit messages
  • Pushes to remote
  • Creates pull requests

Flow Examples:
─────────────

Automated full workflow (via Orchestrator):
  User → Orchestrator → Plan → Build → Test → Commit → Done
                         └──────┴──────┴──────┴────────┘
                         (orchestrator delegates to each)

Manual simple change:
  User → Build Agent → Commit Agent → Done

Manual with architecture decision:
  User → Plan Agent → Build Agent → Commit Agent → Done

Manual with validation:
  User → Build Agent → Test Agent → Commit Agent → Done
       └─────────────────┘ (if tests fail, back to Build)
```

## Agent Limitations

**Important:** Agents may occasionally violate their role boundaries. Current enforcement relies on self-discipline rather than technical restrictions.

**Known issues:**
- Commit Agent may modify code files when it should only commit changes made by Build Agent
- Agents may perform actions outside their designated capabilities

**Best practices:**
- Review `git diff` output carefully before commits
- Question unexpected file changes (e.g., code changes from Commit Agent)
- Explicitly switch agents when crossing role boundaries
- If an agent violates boundaries, point it out and request the correct agent

**Future improvement:** Technical enforcement of agent file permissions would prevent these violations.

## Available Prompts

Prompts streamline common workflows. Invoke with `@prompt-name`.

### Workflow Prompts

- **`@branch`** - Create new feature branch
  - Asks what you're building
  - Suggests properly formatted branch name
  - Switches to main, pulls latest, creates branch
  - Use: Starting any new work

- **`@pr`** - Create and open pull request
  - Checks all changes are committed
  - Pushes branch to remote
  - Creates PR with auto-filled title/body
  - Opens PR in browser automatically
  - Use: When feature is ready for review

- **`@commit`** - Commit workflow
  - Reviews changes with git status/diff
  - Creates atomic commits
  - Writes proper commit messages
  - Use: When you have changes to commit

### Automated Workflows

- **`@workflow-full`** - Complete development workflow
  - Plan → Build → Test → Commit → Push
  - Full orchestrated workflow
  - Use: For complex features requiring all steps

- **`@workflow-lint-fix-changed`** - Fix linting on changed files
  - Identifies changed files
  - Runs appropriate linters
  - Fixes issues automatically
  - Use: When linting fails on specific files

- **`@workflow-cicd-fix`** - Fix CI/CD pipeline failures
  - Fetches failure logs from GitHub Actions
  - Analyzes root cause
  - Fixes issues and pushes
  - Monitors until pipeline passes
  - Use: When GitHub Actions fails

- **`@workflow-release`** - Automated release workflow
  - Bumps version (major/minor/patch)
  - Updates CHANGELOG.md
  - Creates commit and git tag
  - Pushes and creates PR
  - Monitors deployment
  - Use: When ready to release new version

All prompts are in `.kiro/prompts/` with detailed documentation.

## Project Overview

Obscvrat is a band website built with Hugo static site generator, deployed to AWS S3 + CloudFront. The project uses Python scripts and shell scripts for automation and infrastructure management.

## Make Commands Reference

### Testing Commands
```bash
make test              # Show available test commands
make test sh           # Shell script linting (shellcheck)
make test yaml         # YAML linting (yamllint)
make test md           # Markdown linting (pymarkdown)
make test html         # HTML validation (html5lib)
make test py           # Python tests (pytest + ruff)
make test secrets      # Secret scanning (detect-secrets)
make test links        # Critical link validation
```

### Hook Commands
```bash
make hooks setup       # Install pre-commit hooks (one-time)
make hooks run         # Run all hooks manually
make hooks uninstall   # Remove pre-commit hooks
```

### Build Commands
```bash
# Start local development server (http://localhost:1313)
make serve

# Build the site locally
make build

# Build for production (minified, optimized)
make build-prod

# Clean build artifacts
make clean

# View all available commands
make help
```

### ADR Commands
```bash
make adr new TITLE="Decision Title"  # Create new ADR
make adr list                        # List all ADRs
make adr list-accepted               # List accepted ADRs
```

### Content Management
```bash
make live    # Generate live performance pages
make media   # Generate media pages
make music   # Generate music pages
```

### Deployment
```bash
make deploy production  # Deploy to AWS S3 + CloudFront
```

## CI/CD Workflow

### PR Checks Workflow (`pr-checks.yml`)

Runs on every push and pull request to validate code quality.

**Jobs (run in parallel):**
1. **Lint** - Shellcheck, yamllint, markdown linting
2. **Build & Validate** - Hugo build, HTML validation, link checking
3. **Security** - Secret scanning, AWS key detection

**Jobs (run after validation):**
4. **Results** - Post PR comment with status
5. **Notify** - Send email notifications

**Triggers:**
- Push to any branch
- Pull request to main

**Duration:** ~30 seconds

### Deploy Workflow (`deploy.yml`)

Deploys to production after pr-checks pass on main branch.

**Steps:**
1. Configure AWS credentials (OIDC)
2. Build Hugo site with production settings
3. Sync to S3 bucket
4. Invalidate CloudFront cache
5. Create GitHub release (if tagged)

**Triggers:**
- Automatically after pr-checks succeeds on main
- Manual trigger via workflow_dispatch

**Duration:** ~20 seconds

**Safety:** Only deploys if pr-checks passed or manually triggered.

See [docs/CI-CD.md](docs/CI-CD.md) for detailed pipeline documentation.

## Release Process

### Version Bumping

Use `bump_version.py` to update version:

```bash
# Bump patch version (1.2.0 → 1.2.1)
python3 scripts/bump_version.py patch

# Bump minor version (1.2.0 → 1.3.0)
python3 scripts/bump_version.py minor

# Bump major version (1.2.0 → 2.0.0)
python3 scripts/bump_version.py major
```

**What it does:**
- Updates CHANGELOG.md with new version entry
- Updates website/data/changelog.txt
- Creates empty sections (Added, Changed, Fixed)
- Prints new version number

### Creating a Release

**IMPORTANT:** Version bumping happens on feature branch BEFORE creating PR.

1. **On feature branch:** Make changes and commit
2. **Bump version** - `python3 scripts/bump_version.py minor` (or patch/major)
3. **Fill CHANGELOG.md** - Add changes under appropriate sections
4. **Commit version** - `git add CHANGELOG.md website/data/changelog.txt README.md && git commit -m "Release v1.4.0: Description"`
5. **Push and create PR** - Push branch and create pull request
6. **Merge PR to main** - Merge after review and CI passes
7. **Auto-deploy** - Deploy workflow runs automatically
8. **GitHub release** - Created automatically from CHANGELOG

**Version Guidelines:**
- **Major (2.0.0)** - Breaking changes, major features
- **Minor (1.3.0)** - New features, no breaking changes
- **Patch (1.2.1)** - Bug fixes, small improvements

## Common Workflows

### New Feature Workflow

```
1. @branch
   → Creates feature/feature-name branch from main

2. Build Agent
   → Implement feature
   → Run tests: make test

3. @commit
   → Reviews changes
   → Creates atomic commits

4. @pr
   → Pushes to remote
   → Creates PR
   → Opens in browser

5. Merge PR
   → pr-checks validates
   → Merge to main
   → Auto-deploys to production
```

### Bug Fix Workflow

```
1. @branch
   → Creates fix/bug-name branch from main

2. Build Agent
   → Fix the bug
   → Test: make test

3. @commit
   → Commit fix

4. @pr
   → Create PR
   → Merge after validation
```

### Documentation Update

```
1. @branch
   → Creates docs/update-name branch

2. Build Agent
   → Update documentation
   → Build: make serve (verify changes)

3. @commit
   → Commit changes

4. @pr
   → Create PR and merge
```

### Release Workflow

```
1. On feature branch
   → python3 scripts/bump_version.py minor
   → Fill CHANGELOG.md
   → git commit -m "Release v1.4.0: Description"

2. @pr
   → Push and create PR

3. Merge PR
   → pr-checks validates
   → Merge to main
   → deploy workflow runs
   → GitHub release created
   → Site updated with new version
```

### CI/CD Fix Workflow

```
1. @workflow-cicd-fix
   → Fetches failure logs
   → Analyzes root cause
   → Fixes issues
   → Pushes fix
   → Monitors until pass
```

## Testing and Validation

**See ADR-004 for detailed rationale and decision on testing requirements.**

**See `.kiro/instructions/testing.md` for detailed testing requirements.**

Quick reference:

```bash
# Run appropriate tests based on changes
make test sh           # Shell scripts
make test yaml         # YAML files
make test md           # Markdown files
make test html         # HTML output
make test py           # Python scripts
make test secrets      # Secret scanning
make test links        # Link validation
```

Pre-commit hooks (one-time setup):
```bash
make hooks setup       # Install hooks
make hooks run         # Run manually
make hooks uninstall   # Remove hooks
```

## Code Style Guidelines

See `.kiro/instructions/build.md` for detailed code style guidelines.

Quick reference:
- Hugo content in `website/content/`
- Templates in `website/layouts/`
- Static files in `website/static/`
- Scripts in `scripts/`
- Infrastructure code in `infrastructure/`
- Documentation in `docs/`

## Architecture Decision Records (ADRs)

Significant architectural and technical decisions are documented in ADRs.

### When to Create an ADR

Create an ADR for decisions that:
- **Technology/Framework Choices:** Core dependencies, hosting platforms
- **Major Dependencies:** Third-party services or APIs
- **Patterns & Conventions:** Code organization, naming conventions
- **Data Modeling:** Content structure, API design
- **Security Decisions:** Authentication, authorization approaches
- **Performance Strategies:** Caching, optimization techniques
- **Breaking Changes:** Changes affecting public APIs or requiring migration

### ADR Workflow

1. **Recognize the need:** Identify architecturally significant decision
2. **Notify the user:** "This should be documented in an ADR"
3. **Follow decision-making workflow:**
   - Ask relevant questions (see ADR-002)
   - Research and present alternatives with pros/cons
   - Help draft the ADR after decision is made
4. **Create the ADR:** Use `make adr new TITLE="Decision Title"`
5. **Reference the ADR:** In code comments, PR descriptions, documentation

### ADR Resources

- **Directory:** `/docs/adr/`
- **Template:** `/docs/adr/template.md`
- **Workflow:** See ADR-002 for detailed process
- **Scripts:**
  - `make adr new TITLE="Title"` - Create new ADR
  - `make adr list` - List ADRs

```bash
# Create a new ADR
make adr new TITLE="Choose deployment strategy"

# List all ADRs
make adr list

# List by status
make adr list-accepted
```

## Git Commit Guidelines

See [CONTRIBUTING.md](CONTRIBUTING.md) and `.kiro/instructions/commit.md` for detailed guidelines.

**Quick Reference:**
- Use imperative mood: "Add feature" not "Added feature"
- Keep header under 72 characters
- Add body for non-trivial changes (wrap at 72-74 chars)
- Explain WHY, not just what
- Reference issues: `Fixes #123`
- Branch naming: `type/short-description` (e.g., `feature/user-auth`)

## Deployment

```bash
# Deploy to production
make deploy-production
```

See `docs/DEPLOYMENT.md` for detailed deployment instructions.

## When Making Changes

1. Read existing code to understand patterns
2. Follow established conventions in the codebase
3. Run validation hooks before committing (`make run-hooks`)
4. Update documentation if changing public APIs
5. Keep changes focused and atomic
6. Test locally with `make serve` before deploying

## Project-Specific Notes

- **Hugo version:** 0.128.2 (used in CI/CD)
- **Deployment:** Automatic deployment after pr-checks pass on main
- **CI/CD:** GitHub Actions validates and deploys
- **Branch protection:** Main branch requires PR approval
- **Pre-commit hooks:** Local validation before push (ADR-004)
- **Design system:** Dark minimal aesthetic (ADR-007)
- **Typography:** Typo font for body, Fira Mono for structure (ADR-008)

## Additional Resources

### For AI Agents
- [.kiro/instructions/](.kiro/instructions/) - Agent-specific instructions
  - `build.md` - Build Agent code style and testing
  - `commit.md` - Commit Agent git workflow
  - `test.md` - Test Agent validation commands
  - `testing.md` - Shared testing requirements
  - `plan.md` - Plan Agent ADR workflow
- [.kiro/prompts/](.kiro/prompts/) - Workflow automation prompts
- [docs/adr/](docs/adr/) - Architecture Decision Records
- [docs/CI-CD.md](docs/CI-CD.md) - CI/CD pipeline documentation
- [docs/DESIGN.md](docs/DESIGN.md) - Design system and patterns
- [docs/MARKDOWN-LINTING.md](docs/MARKDOWN-LINTING.md) - Markdown linting rules
- [docs/GITHUB-ACTIONS.md](docs/GITHUB-ACTIONS.md) - GitHub Actions setup

### For Humans
- [README.md](README.md) - Quick start guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Git conventions
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Deployment guide
