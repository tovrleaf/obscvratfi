# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the obscvratfi band website project.

## What are ADRs?

ADRs document significant architectural and technical decisions made during the project's development. Each ADR describes the context, the decision made, alternatives considered, and consequences.

## ADR Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [000](000-use-adr-for-architecture-decisions.md) | Use Architecture Decision Records | Accepted | 2025-12-27 |
| [001](001-adr-template.md) | ADR Template Structure | Accepted | 2025-12-27 |
| [002](002-decision-making-workflow.md) | Decision-Making Workflow | Accepted | 2025-12-27 |
| [003](003-website-hosting-static-site-generation-seo-strategy.md) | Website Hosting, Static Site Generation & SEO Strategy | Accepted | 2025-12-27 |
| [004](004-instagram-feed-integration-dynamic-content-strategy.md) | Instagram Feed Integration & Dynamic Content Strategy | Accepted | 2025-12-27 |

## Creating a New ADR

Use the helper script:

```bash
./scripts/new-adr.sh "Your Decision Title"
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
./scripts/list-adrs.sh

# List only accepted ADRs
./scripts/list-adrs.sh Accepted

# List proposed ADRs
./scripts/list-adrs.sh Proposed
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
