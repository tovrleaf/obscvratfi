# Contributing to Obscvrat

Thanks for your interest in contributing! This guide will help you understand our workflow and conventions.

For AI coding agent guidelines, see [AGENTS.md](AGENTS.md).

## Getting Started

### Prerequisites

- Git
- Docker and Docker Compose
- Python 3.9+ (for pre-commit hooks)

### Local Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/tovrleaf/obscvrat.git
   cd obscvrat
   ```

2. **Install pre-commit hooks for local validation:**
   ```bash
   make setup-hooks
   ```
   
   This installs the pre-commit framework and sets up git hooks that automatically validate your changes before pushing. The hooks will:
   - Check shell scripts, YAML, Markdown, and TOML files
   - Validate the Hugo site builds
   - Verify HTML structure
   - Check for accidentally committed secrets
   - Validate critical internal links

3. **Start development:**
   ```bash
   make serve
   ```
   
   The site will be available at http://localhost:1313 with hot reload enabled.

### Validation Before Pushing

When you push code, the pre-commit hooks run automatically. If there are any issues:

1. Read the error message carefully
2. Fix the issues locally
3. Push again - hooks will run again

If you need to bypass hooks for an emergency (use sparingly):
```bash
git push --no-verify
```

See [ADR-005: Local Pre-Commit Hooks](docs/adr/005-local-pre-commit-hooks-for-development-validation.md) for more details on local validation.

## Git Commit Guidelines

Good commit messages make it easier to understand the history of the project and why changes were made. We follow a structured approach inspired by best practices from the Linux kernel community.

### Commit Message Format

```
Short summary (72 characters or less)

More detailed explanatory text, if necessary. Wrap it to 72-74
characters. The blank line separating the summary from the body is
critical (unless you omit the body entirely).

Explain the problem that this commit is solving. Focus on why you
are making this change as opposed to how (the code explains that).
Are there side effects or other unintuitive consequences of this
change? Here's the place to explain them.

Further paragraphs come after blank lines.

- Bullet points are okay, too
- Use a hyphen or asterisk for bullets

Fixes #123
```

### Header Line Rules

The header line is the first line of your commit message. It appears in logs, GitHub UI, and git tools, so make it count!

- **Length:** Keep it under 72 characters
- **Mood:** Use imperative mood ("Add feature" not "Added feature" or "Adds feature")
- **Capitalization:** Capitalize the first word
- **Punctuation:** No period at the end
- **Be specific:** "Fix login timeout issue" not "Fix bug"

**Good action verbs:**
- Fix - for bug fixes
- Add - for new features or files
- Remove - for deletions
- Update - for modifications to existing features
- Refactor - for code restructuring
- Document - for documentation changes
- Improve - for enhancements
- Implement - for new implementations

### Commit Body Guidelines

The body is optional for simple, self-explanatory changes. For anything non-trivial, a good body helps reviewers and your future self understand the context.

**When to include a body:**
- Bug fixes that aren't immediately obvious
- New features or significant changes
- Changes that affect behavior in non-obvious ways
- Anything that might make someone ask "why did they do it this way?"

**What to include:**
- **Why** the change is needed (the motivation)
- **How** your solution works (the approach)
- **Context** about the problem being solved
- **Side effects** or important considerations
- **Alternatives** you considered (if relevant)

**Formatting:**
- Leave a blank line between the header and body
- Wrap lines at 72-74 characters
- Use multiple paragraphs if needed
- Bullet points are fine

**What NOT to do:**
- Don't just describe what changed (the diff shows that)
- Don't be vague ("fixed some stuff")
- Don't use the body to apologize or editorialize

### Footer and References

The footer is where you add metadata and references:

**Issue references:**
- `Fixes #123` - Closes the issue when the commit is merged
- `Closes #456` - Same as Fixes
- `Relates to #789` - References an issue without closing it

**Breaking changes:**
- `BREAKING CHANGE: description of what breaks and why`

**Co-authors:**
- `Co-authored-by: Name <email@example.com>`

### Examples

#### Example 1: Simple commit (no body needed)

```
Add loading spinner to dashboard page
```

For straightforward changes, the header alone is sufficient.

#### Example 2: Bug fix with explanation

```
Fix race condition in authentication middleware

The middleware was checking token validity before the database
connection was fully established, causing intermittent 401 errors
during server startup or after connection pool resets.

This adds a connection readiness check before token validation and
implements a retry mechanism with exponential backoff (max 3 attempts)
for database queries during token verification.

Fixes #142
```

#### Example 3: Feature with detailed body

```
Add user profile export functionality

Users can now export their profile data in JSON or CSV format from
the account settings page. This addresses GDPR data portability
requirements and user requests for backup capabilities.

The export includes:
- User account information
- Activity history and preferences
- Associated metadata (timestamps, locations, etc.)

Large exports are processed asynchronously and delivered via email
to prevent timeout issues. Email notifications include a secure
download link valid for 7 days.

Closes #234
```

#### Example 4: What NOT to do

```
❌ Updated files
❌ Fixed bug
❌ Changed some authentication stuff
❌ WIP - working on user feature
❌ Fixed issue (which issue? how?)

✅ Fix validation error in user registration form
✅ Add password strength indicator to signup page
✅ Refactor authentication middleware for better testability
```

### Additional Commit Guidelines

- **Atomic commits:** Each commit should represent one logical change. If you find yourself using "and" in your commit message, consider splitting it into multiple commits.

- **Test before committing:** Make sure your code builds and tests pass before creating a commit.

- **Clean history:** Avoid committing "WIP", "temp", or "fix typo" commits. Use `git commit --amend` to fix the most recent commit, or use `git rebase -i` to clean up your commits before opening a pull request.

- **Commit often:** Small, focused commits are better than large, sprawling ones. They're easier to review, easier to revert if needed, and make the history more useful.

## Branch Naming Conventions

Using consistent branch names helps everyone understand what's being worked on at a glance.

### Format

```
type/short-description
type/issue-number-short-description
```

### Branch Types

#### `feature/` - New features or enhancements
Use this for any new functionality you're adding to the app.

Examples:
- `feature/user-dashboard`
- `feature/123-email-notifications`
- `feature/payment-integration`

#### `fix/` - Bug fixes
Use this for fixing bugs or issues.

Examples:
- `fix/login-timeout`
- `fix/456-api-error-handling`
- `fix/broken-image-upload`

#### `refactor/` - Code refactoring
Use this when you're restructuring code without changing its behavior.

Examples:
- `refactor/database-layer`
- `refactor/api-structure`
- `refactor/component-hierarchy`

#### `docs/` - Documentation updates
Use this for documentation-only changes.

Examples:
- `docs/api-endpoints`
- `docs/contributing-guide`
- `docs/setup-instructions`

#### `test/` - Adding or updating tests
Use this when adding new tests or modifying existing ones.

Examples:
- `test/authentication-flow`
- `test/api-integration`
- `test/user-profile-component`

#### `chore/` - Maintenance tasks
Use this for dependencies, configuration, build setup, or other housekeeping.

Examples:
- `chore/update-dependencies`
- `chore/configure-ci`
- `chore/upgrade-react-18`

#### `hotfix/` - Urgent production fixes
Use this for critical bugs that need immediate attention in production.

Examples:
- `hotfix/critical-security-patch`
- `hotfix/data-loss-bug`
- `hotfix/payment-processing-error`

### Naming Rules

- **Lowercase:** Always use lowercase letters
- **Hyphens:** Separate words with hyphens (kebab-case), not underscores or spaces
- **Length:** Keep it short but descriptive (2-5 words)
- **Issue numbers:** Include the issue number when applicable: `fix/123-memory-leak`
- **Specificity:** Be specific enough that someone can understand what the branch is about

### Examples

**Good branch names:**
```
✅ feature/payment-integration
✅ fix/789-session-timeout
✅ refactor/api-error-handling
✅ docs/setup-instructions
✅ test/user-authentication
✅ chore/upgrade-react-18
✅ hotfix/security-vulnerability
```

**Bad branch names:**
```
❌ my-branch (not descriptive)
❌ fix_bug (use hyphens, not underscores)
❌ FEATURE/NEW-THING (use lowercase)
❌ test (too vague)
❌ feature/adding-a-really-long-descriptive-name-that-goes-on-and-on (too long)
❌ stuff (completely meaningless)
```

### Branch Lifecycle

- **Create from main:** Always create new branches from an up-to-date `main` branch
- **Stay focused:** Keep each branch focused on a single feature, fix, or task
- **Sync regularly:** Regularly merge or rebase with `main` to avoid conflicts
- **Delete after merge:** Delete branches after they're merged to keep the repository clean

## Getting Help

If you have questions or need help:

- **Bug reports:** Open an issue describing the problem, steps to reproduce, and expected vs actual behavior
- **Feature requests:** Open an issue explaining the feature, the use case, and why it would be valuable
- **Questions:** Check existing issues and documentation first, then open a new issue or discussion if needed

We appreciate your contributions! 🎉
