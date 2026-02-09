# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the
Obscvrat band website project.

## What are ADRs?

ADRs document significant architectural and technical decisions made
during the project's development. Each ADR describes the context, the
decision made, alternatives considered, and consequences.

## ADR Index

- **[000](000-use-adr-for-architecture-decisions.md)** - Use ADRs
  (Accepted, 2025-12-27)
- **[001](001-adr-template.md)** - ADR Template (Accepted, 2025-12-27)
- **[002](002-decision-making-workflow.md)** - Decision Workflow
  (Accepted, 2025-12-27)
- **[003](003-website-hosting-static-site-generation-seo-strategy.md)**
  \- Hosting & SEO (Accepted, 2025-12-27)
- **[004](004-instagram-feed-integration-dynamic-content-strategy.md)**
  \- Instagram Feed (Accepted, 2025-12-27)
- **[005](005-local-pre-commit-hooks-for-development-validation.md)**
  \- Pre-Commit Hooks (Accepted, 2025-12-30)
- **[006](006-repository-branch-protection-with-github-rulesets.md)**
  \- Branch Protection (Accepted, 2025-12-30)
- **[007](007-homepage-design-system-dark-minimal-asymmetric.md)**
  \- Design System (Accepted, 2025-01-09)
- **[008](008-typo-font-custom-typography-for-body-text.md)** - Typo
  Font (Accepted, 2025-01-10)
- **[009](009-live-performance-media-management-pictures-videos-data-structure.md)**
  \- Media Management (Proposed, 2026-01-24)
- **[010](010-specialized-agent-architecture-for-development-workflow.md)**
  \- Agent Architecture (Accepted, 2026-01-26)
- **[011](011-yaml-data-files-for-content-management.md)** - YAML Data
  Files (Accepted, 2026-01-31)
- **[012](012-semantic-versioning-for-ai-driven-development.md)** - Semantic Versioning (Accepted, 2026-02-02)
- **[013](013-dual-licensing-strategy-mit-and-cc-by-nc-sa.md)** - Dual Licensing Strategy (Accepted, 2026-02-03)
- **[014](014-python-for-complex-scripts-with-test-coverage.md)** - Python for Complex Scripts (Accepted, 2026-02-04)
- **[015](015-image-optimization-with-hugo-processing.md)** - Image Optimization (Accepted, 2026-02-05)
- **[016](016-cloudfront-analytics-for-website-traffic-monitoring.md)** - CloudFront Analytics (Accepted, 2026-02-09)

## Creating a New ADR

Use the helper script:

```bash
make adr new TITLE="Your Decision Title"
```

This will:

- Create a new ADR file with the next sequential number
- Use the standard template
- Fill in the date automatically
- Update this README with the new entry
- Open the file in nvim for editing

Or manually:
1. Copy `template.md`
2. Rename to `XXX-your-decision-title.md` (next sequential number)
3. Fill in all sections
4. Update this README with a new entry

## Listing ADRs

Use the helper script to list all ADRs:

```bash
# List all ADRs
make adr list

# List only accepted ADRs
make adr list-accepted

# List proposed ADRs
make adr list-proposed
```

## ADR Status

- **Proposed:** Under consideration, not yet finalized
- **Accepted:** Approved and should be followed
- **Deprecated:** No longer recommended but not formally replaced
- **Superseded by ADR-XXX:** Replaced by a newer decision

## When to Create an ADR

Create an ADR for decisions that affect:
- Technology and framework choices
- Major dependencies or integrations
- Code patterns and conventions
- Data modeling and API design
- Security and authentication approaches
- Performance optimization strategies
- Breaking changes

See [ADR-002](002-decision-making-workflow.md) for the complete decision-making workflow.
