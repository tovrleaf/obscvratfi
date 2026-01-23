# Agent Guidelines for Obscvrat

This document provides guidelines for AI coding agents working in this repository.

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

## Code Style Guidelines

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
