# Agent Guidelines for Obscvrat

This document provides guidelines for AI coding agents working in this repository.

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

## Project Overview

Obscvrat is a band website built with Hugo static site generator, deployed to AWS S3 + CloudFront. The project uses shell scripts for deployment and infrastructure management.

## Build and Development Commands

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

## Testing and Validation

**See ADR-004 for detailed rationale and decision on testing requirements.**

Quick reference for local testing:

```bash
# Setup local pre-commit hooks (one-time)
make setup-hooks

# Run all validation hooks manually
make run-hooks

# Uninstall hooks
make uninstall-hooks
```

Local hooks validate:
- Shell scripts (shellcheck)
- YAML files (yamllint)
- Markdown files (markdownlint)
- Hugo site builds
- HTML structure
- Critical internal links
- No secrets committed

### Script Testing Requirements

**IMPORTANT:** When modifying existing scripts, always test them before committing:

1. **Syntax validation:** Run `bash -n script.sh` to check for syntax errors
2. **Functional testing:** Execute the script with test inputs to verify behavior
3. **Edge cases:** Test with empty inputs, invalid inputs, and boundary conditions
4. **Integration:** Verify the script works with related files and commands
5. **Cleanup:** Remove test artifacts and restore to pre-testing state

Example testing workflow:
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

Do not hand back modified scripts without testing them first.
Always restore the repository to the state it was in before testing.

### Template/Webpage Testing Requirements

**IMPORTANT:** When modifying Hugo templates, layouts, or content in `website/`, always test by building and validating:

1. **Build the site:** Run `cd website && hugo` to compile
2. **Check for build errors:** Look for ERROR messages in output
3. **Validate HTML:** Run `make test html-commit` to validate changed HTML files
4. **Verify content:** Check generated HTML contains expected content
5. **Clean up:** Remove test artifacts if needed

Example testing workflow:
```bash
# Build the site
cd website && hugo

# Check for errors in build output
cd website && hugo 2>&1 | grep ERROR

# Validate HTML from your changes
make test html-commit

# Verify generated HTML content
cat website/public/media/index.html | grep "expected-content"

# Clean up if needed
rm -rf website/public/
```

Do not hand back modified templates without building and validating the output.

## Code Style Guidelines

### File Renaming and Moving

**IMPORTANT:** When renaming or moving files tracked by git, always use `git mv` to preserve file history:

```bash
# Correct - preserves history
git mv old-name.sh new-name.sh

# Wrong - breaks history
mv old-name.sh new-name.sh
git add new-name.sh
```

After using `git mv`, make content changes and commit. Git will show the rename with similarity percentage (e.g., "rename scripts/{old.sh => new.sh} (90%)").

### Shell Scripts
- Use shellcheck for validation
- Include error handling (`set -e`)
- Add descriptive comments for complex logic
- Use meaningful variable names
- Quote variables to prevent word splitting

### Hugo Templates
- Follow Go template syntax
- Keep templates focused and modular
- Use partials for reusable components
- Comment complex template logic

### Markdown Content
- Follow markdownlint rules
- Use consistent heading hierarchy
- Keep lines under 120 characters when practical
- Use descriptive link text

### File Organization
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
4. **Create the ADR:** Use `make adr-new TITLE="Decision Title"`
5. **Reference the ADR:** In code comments, PR descriptions, documentation

### ADR Resources

- **Directory:** `/docs/adr/`
- **Template:** `/docs/adr/template.md`
- **Workflow:** See ADR-002 for detailed process
- **Scripts:**
  - `make adr-new TITLE="Title"` - Create new ADR
  - `make adr-list` - List ADRs

```bash
# Create a new ADR
make adr-new TITLE="Choose deployment strategy"

# List all ADRs
make adr-list

# List by status
make adr-list-accepted
```

## Git Commit Guidelines

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

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

- **Hugo version:** 0.128.2 (specified in Dockerfile)
- **Deployment:** Manual deployment via scripts (no auto-deploy)
- **CI/CD:** GitHub Actions validates PRs but doesn't deploy
- **Branch protection:** Main branch requires PR approval
- **Pre-commit hooks:** Local validation before push (ADR-004)
- **Design system:** Dark minimal aesthetic (ADR-007)
- **Typography:** Typo font for body, Fira Mono for structure (ADR-008)

## Additional Resources

- [README.md](README.md) - Project overview and quick start
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [docs/adr/](docs/adr/) - Architecture Decision Records
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Deployment guide
- [docs/CI-CD.md](docs/CI-CD.md) - CI/CD pipeline documentation
