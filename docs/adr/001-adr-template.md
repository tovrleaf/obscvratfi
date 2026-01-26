# 1. ADR Template Structure

**Status:** Accepted

**Date:** 2025-12-27

## Context

Having decided to use ADRs (see ADR-000), we need a consistent structure
to ensure all ADRs contain the necessary information and are easy to read.
Without a standard template, ADRs might be inconsistent, missing important
details, or difficult to compare.

A good template should:
- Be comprehensive enough to capture key information
- Be simple enough to not discourage creating ADRs
- Guide the author through important considerations
- Be consistent across all decisions

## Decision

We will use the following template structure for all ADRs:

### Required Sections

**Header:**
- Number and title in imperative form
- Status (Proposed, Accepted, Deprecated, Superseded)
- Date of decision

**Context:**
- Problem or situation that prompted the decision
- Background information
- Constraints and requirements
- Forces at play

**Decision:**
- Clear statement of what was decided
- Active voice ("We will...")
- Specific and actionable

**Alternatives Considered:**
- At least 2-3 alternatives
- Pros and cons for each
- Why each was rejected
- Shows thoughtful consideration

**Consequences:**
- Positive outcomes and benefits
- Negative tradeoffs and costs
- Neutral side effects
- Honest assessment of impacts

### Optional Sections

**Notes:**
- Additional context
- Links to resources
- Related decisions
- Implementation details

### Template Usage Guidelines

**Writing the Context:**
- Explain the problem clearly
- Include relevant background
- State constraints explicitly
- Don't assume the reader knows the situation

**Writing the Decision:**
- Be specific and concrete
- Use imperative/active voice
- State what will be done, not what won't
- Keep it concise but complete

**Evaluating Alternatives:**
- Consider at least 2-3 realistic options
- Be honest about pros and cons
- Explain rejection reasons clearly
- Show you considered tradeoffs

**Documenting Consequences:**
- Be realistic about both positive and negative
- Consider short-term and long-term impacts
- Think about who/what is affected
- Don't oversell the decision

## Alternatives Considered

### Alternative 1: Minimal template (just context and decision)
- **Pros:**
  - Very quick to write
  - Less intimidating
  - Lower barrier to creating ADRs
- **Cons:**
  - Missing important information
  - Doesn't capture alternatives considered
  - No explicit consequence analysis
  - Less useful for future reference
- **Why rejected:** Too minimal to be useful for understanding decisions later

### Alternative 2: Comprehensive template (many required sections)
- **Pros:**
  - Very thorough documentation
  - Captures all possible information
  - Extremely detailed
- **Cons:**
  - Too time-consuming to complete
  - Creates friction in decision-making
  - Many sections might not apply to all decisions
  - Could discourage ADR creation
- **Why rejected:** Too heavy; would make people avoid creating ADRs

### Alternative 3: Multiple templates for different decision types
- **Pros:**
  - Tailored to specific needs
  - Only relevant sections for each type
  - More precise guidance
- **Cons:**
  - Confusion about which template to use
  - Harder to maintain consistency
  - More templates to manage
  - Unnecessary complexity for a personal project
- **Why rejected:** Adds complexity without enough benefit

## Consequences

### Positive
- Consistent structure across all ADRs
- Clear guidance on what to include
- Captures both alternatives and consequences
- Easy to review and understand later
- Template is comprehensive but not overwhelming

### Negative
- Some sections might feel unnecessary for simple decisions
- Requires thoughtful writing, not just quick notes
- Takes more time than ad-hoc documentation

### Neutral
- Template will evolve based on experience
- Some sections (like Notes) are optional
- Format is flexible within the structure

## Notes

The template file is stored at `docs/adr/template.md` and is used by the
`make adr-new` command to create new ADRs with proper structure and
placeholders.
