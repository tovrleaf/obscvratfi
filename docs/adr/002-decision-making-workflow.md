# 2. Decision-Making Workflow

**Status:** Accepted

**Date:** 2025-12-27

## Context

Having decided to use ADRs with a standard template (see ADR-000 and
ADR-001), we need a clear process for when and how to create them.
Without a defined workflow, ADRs might be created inconsistently or
important decisions might go undocumented.

We need guidelines for:
- When to create an ADR vs when not to
- What questions to consider during decision-making
- How to collaborate with AI agents on decisions
- How ADR status changes over time

## Decision

We will follow this structured workflow for architectural decisions:

### When to Create an ADR

Create an ADR for decisions that:

**Technology/Framework Choices:**
- Selecting frontend frameworks, libraries, or build tools
- Choosing testing frameworks or development tools
- Picking significant dependencies that affect the architecture

**Major Dependencies:**
- Adding third-party services or APIs
- Integrating external platforms (payment, analytics, etc.)
- Selecting hosting or deployment platforms

**Patterns & Conventions:**
- Establishing code organization patterns
- Deciding on state management approaches
- Setting API design patterns (REST, GraphQL, etc.)
- Choosing naming conventions or project structure

**Data Modeling:**
- Database schema design decisions
- Data format choices (JSON, XML, etc.)
- Content modeling for CMS or structured data

**Security Decisions:**
- Authentication and authorization approaches
- Data encryption strategies
- Security best practices implementation

**Performance Strategies:**
- Caching implementations
- Optimization techniques that affect architecture
- Loading and rendering strategies

**Breaking Changes:**
- Changes that affect public APIs
- Modifications requiring data migration
- Updates that change user-facing behavior significantly

### When NOT to Create an ADR

Skip ADRs for:
- Minor bug fixes
- Simple refactoring without architectural impact
- Routine dependency updates
- Cosmetic changes (unless establishing a pattern)
- Reversible decisions with minimal impact
- Trivial choices with no long-term consequences

### Decision-Making Process

#### Phase 1: Identify & Scope
1. Recognize that a decision needs to be made
2. Frame the problem or question clearly
3. Identify constraints and requirements
4. Determine if an ADR is warranted
5. Bring it up for discussion

#### Phase 2: Research & Generate Options
When working with AI agents, the agent will:

**Ask clarifying questions based on decision type:**

For **Technology Choices:**
- What problem does this solve?
- What's your experience level with the options?
- What are your priorities? (development speed, performance, learning opportunity, maintainability)
- Any constraints? (budget, timeline, existing stack compatibility)
- What's the expected scale and complexity?

For **Pattern/Convention Decisions:**
- What's the current pain point or limitation?
- What's your comfort level with different approaches?
- How does this affect other parts of the system?
- What are the long-term maintenance considerations?
- How complex is the implementation?

For **Security/Performance Decisions:**
- What are the requirements or targets?
- What are the risks or bottlenecks?
- What's the tolerance for complexity?
- What are the compliance needs?
- What's the expected impact?

**Research and present options:**
- Identify 2-4 realistic alternatives
- Provide pros and cons for each
- Share relevant context (community support, maturity, tradeoffs)
- Highlight key differentiators

#### Phase 3: Analysis & Discussion
The AI agent will adapt the collaboration approach:

**Option Presentation:**
- Present 2-3 vetted options with balanced pros/cons
- Let you choose based on your priorities
- Used for: Technology choices with clear tradeoffs

**Recommendation with Rationale:**
- Make a clear recommendation
- Explain reasoning thoroughly
- Present counter-arguments for balance
- Used for: Decisions with a clear best practice or when you want guidance

**Socratic Questioning:**
- Ask probing questions to surface priorities
- Help you discover the right choice
- Guide thinking without prescribing
- Used for: Complex decisions where priorities need clarification

**Hybrid Approach:**
- Combine methods as appropriate
- Adapt based on the complexity and your responses
- Used for: Most real-world decisions

**Discussion topics:**
- Alignment with project goals
- Short-term vs long-term implications
- Risk factors and mitigation
- Implementation effort and complexity
- Learning curve considerations

#### Phase 4: Decide & Document
1. You make the final decision
2. AI agent drafts the ADR using the template
3. You review and approve the content
4. ADR is committed to the repository with status "Accepted"

#### Phase 5: Implement
1. Execute the decision in code
2. Reference the ADR in related code comments or documentation
3. Link to the ADR in relevant pull requests
4. Update ADR status if circumstances change later

### ADR Lifecycle & Status

**Status Definitions:**

- **Proposed:** Decision is under active consideration, not yet finalized
- **Accepted:** Decision is approved and should be followed going forward
- **Deprecated:** Decision is no longer recommended but hasn't been formally replaced
- **Superseded by ADR-XXXX:** Decision has been explicitly replaced by a newer ADR

**Status Transitions:**

- **Proposed → Accepted:** After discussion and final decision
- **Accepted → Deprecated:** When circumstances make it no longer ideal but no replacement exists
- **Accepted → Superseded:** When a new ADR explicitly replaces it
- **Proposed → Superseded:** When a proposed ADR is rejected in favor of a different approach

**Immutability Rule:**

Once an ADR is **Accepted**, the content should NOT be edited except to:
- Fix typos or formatting
- Add notes with new information
- Update status to Deprecated or Superseded

For substantial changes:
- Create a new ADR that supersedes the old one
- Update the old ADR's status to "Superseded by ADR-XXXX"
- Explain what changed and why in the new ADR

## Alternatives Considered

### Alternative 1: Lightweight process (just write ADRs as needed)
- **Pros:**
  - Minimal overhead
  - Maximum flexibility
  - No rigid structure to follow
- **Cons:**
  - Inconsistent application
  - Easy to skip documentation
  - No clear trigger for creating ADRs
  - Unclear when AI should prompt for ADRs
- **Why rejected:** Too unstructured, likely to be inconsistently applied

### Alternative 2: Heavyweight process (multiple approval stages, formal reviews)
- **Pros:**
  - Very thorough consideration
  - Multiple perspectives incorporated
  - High confidence in decisions
- **Cons:**
  - Slows down development significantly
  - Overkill for a personal project
  - Too much process overhead
  - Creates bureaucracy and friction
- **Why rejected:** Too heavy for current needs; can add more process later if needed

### Alternative 3: AI makes all architectural decisions automatically
- **Pros:**
  - Fast decision-making
  - No deliberation needed
  - Consistent with best practices
- **Cons:**
  - Removes human judgment and creativity
  - Doesn't account for personal preferences and priorities
  - Decisions might not align with vision
  - No learning opportunity
- **Why rejected:** You should make the final decisions; AI should inform and guide, not decide

## Consequences

### Positive
- Clear trigger points for when to create ADRs
- Structured approach ensures consistency
- AI agents know what questions to ask
- Collaboration pattern is well-defined
- Decision quality improves through structured analysis
- Flexible collaboration styles match different needs

### Negative
- Adds some overhead to decision-making process
- Requires discipline to follow the workflow
- Can feel like extra work for decisions that seem obvious
- Takes time to write good ADRs

### Neutral
- Process will evolve as we learn what works
- The "when to create ADR" list will grow over time
- AI collaboration styles can be adjusted based on preference
- Status transitions might need refinement based on experience

## Notes

Helper scripts support this workflow:
- `scripts/new-adr.sh` - Creates new ADRs with proper numbering and structure
- `scripts/list-adrs.sh` - Lists all ADRs with status filtering

The workflow is designed to be thorough but not burdensome, and can be
adapted as the project and needs evolve.
