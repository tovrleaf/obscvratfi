# 17. Makefile as Universal Command Interface

**Status:** Accepted

**Date:** 2026-02-10

## Context

The Obscvrat project has multiple automation scripts written in different languages (Python, shell) for various tasks:
- Content management (live performances, music, media)
- Testing and validation (linting, HTML validation, link checking)
- Deployment (AWS S3/CloudFront)
- Development tools (ADR creation, version bumping)
- Git hooks setup

Without a consistent interface, users must:
- Remember different command syntaxes (`python3 scripts/X.py`, `./scripts/Y.sh`, `bash scripts/Z.sh`)
- Know which language each script uses
- Understand script locations and naming conventions
- Deal with different argument formats

This creates friction for:
- New contributors learning the project
- AI agents executing commands
- Humans switching between tasks
- Documentation (must explain each script individually)

We need a unified, discoverable interface that abstracts implementation details.

## Decision

We will use **Makefile as the universal command interface** for all project operations.

### Implementation

**All commands accessible via `make`:**
```bash
make serve              # Development server
make test sh            # Test shell scripts
make deploy production  # Deploy to AWS
make live               # Manage live performances
make adr new TITLE="X"  # Create ADR
make hooks setup        # Install pre-commit hooks
```

**Makefile structure:**
- Main `Makefile` includes modular makefiles from `mk/` directory
- Each domain has its own makefile: `mk/test.mk`, `mk/adr.mk`, `mk/deploy.mk`
- `make help` shows all available commands with descriptions
- Subcommands use consistent patterns: `make <domain> <action>`

**Abstraction layer:**
- Makefiles call Python scripts, shell scripts, or commands
- Implementation language hidden from user
- Can change implementation without changing interface
- Example: `make adr new` calls `python3 scripts/new_adr.py` (was `./scripts/new-adr.sh`)

**Discoverability:**
- `make` or `make help` shows all commands
- `make <domain>` shows domain-specific help (e.g., `make test`, `make adr`)
- Consistent help format across all makefiles

## Alternatives Considered

### Alternative 1: Direct Script Execution

Users call scripts directly: `python3 scripts/bump_version.py`, `./scripts/deploy.sh`

**Pros:**
- No abstraction layer
- Direct control
- Simpler for single-script projects

**Cons:**
- Must remember script names and locations
- Must know which language each script uses
- Different argument formats per script
- No unified help system
- Hard to discover available commands

**Why rejected:** Poor discoverability and inconsistent interface

### Alternative 2: Custom CLI Tool (Python Click/Typer)

Create single Python CLI: `obscvrat test`, `obscvrat deploy`, `obscvrat adr new`

**Pros:**
- Modern CLI with subcommands
- Rich help and autocomplete
- Consistent argument parsing
- Single entry point

**Cons:**
- Requires Python installation
- Additional dependency (Click/Typer)
- More complex than Makefile
- Not standard for build/dev tools
- Harder to extend with shell scripts

**Why rejected:** Makefile is simpler and more standard for development tools

### Alternative 3: Shell Script Wrapper

Create `obscvrat.sh` wrapper calling all scripts

**Pros:**
- Single entry point
- No Make dependency
- Portable shell script

**Cons:**
- Must maintain argument parsing
- No parallel execution
- Less standard than Make
- Harder to organize by domain
- No built-in help system

**Why rejected:** Makefile provides better organization and is more standard

### Alternative 4: Task Runner (npm scripts, just, task)

Use modern task runner like `just` or npm scripts

**Pros:**
- Modern syntax (just uses better syntax than Make)
- Better error messages
- More features

**Cons:**
- Additional dependency to install
- Less ubiquitous than Make
- Team must learn new tool
- Not standard for non-JS projects

**Why rejected:** Make is already installed on all Unix systems; no new dependencies

## Consequences

### Positive

- **Consistent interface:** All commands follow `make <domain> <action>` pattern
- **Discoverable:** `make help` shows everything; `make <domain>` shows domain help
- **Language-agnostic:** Can use Python, shell, or any tool behind the scenes
- **Easy to change:** Can swap implementations without changing interface
- **Standard tool:** Make is ubiquitous on Unix systems
- **Self-documenting:** Help text embedded in Makefile
- **Modular:** Domain-specific makefiles keep organization clean
- **AI-friendly:** Agents can easily discover and execute commands
- **Parallel execution:** Make can run tasks in parallel when safe

### Negative

- **Make syntax:** Makefile syntax can be cryptic (tabs vs spaces, escaping)
- **Windows compatibility:** Make not standard on Windows (requires WSL or installation)
- **Learning curve:** New contributors must understand basic Make concepts
- **Indirection:** Extra layer between user and actual scripts
- **Debugging:** Harder to debug Make targets than direct script calls

### Neutral

- **Convention over configuration:** Enforces consistent patterns
- **Modular makefiles:** More files to maintain but better organization
- **Help text maintenance:** Must keep help text in sync with functionality

## Notes

### Current Makefile Structure

```
Makefile                 # Main entry point, includes all mk/*.mk
mk/
├── adr.mk              # ADR commands (new, list)
├── deploy.mk           # Deployment commands
├── generate.mk         # Markdown generation
├── hooks.mk            # Pre-commit hooks
├── live.mk             # Live performance management
├── media.mk            # Media management
├── music.mk            # Music management
├── site.mk             # Hugo build commands
└── test.mk             # Testing commands
```

### Help System Pattern

Each makefile includes help target:
```makefile
.PHONY: help
help:
	@echo "Domain Name"
	@echo "==========="
	@echo ""
	@echo "Commands:"
	@echo "  make domain action  - Description"
```

### Implementation Examples

**Before (direct script call):**
```bash
python3 scripts/new_adr.py "Decision Title"
```

**After (Make interface):**
```bash
make adr new TITLE="Decision Title"
```

**Makefile implementation:**
```makefile
new:
	@python3 scripts/new_adr.py "$(TITLE)"
```

### Migration from Shell to Python

When migrating scripts from shell to Python (see ADR-014):
1. Create Python version: `scripts/script_name.py`
2. Update Makefile to call Python version
3. Remove shell version
4. User interface stays the same: `make command`

Example: `new-adr.sh` → `new_adr.py`
- Makefile changed from `./scripts/new-adr.sh` to `python3 scripts/new_adr.py`
- User still runs: `make adr new TITLE="..."`

### Interactive Menu Selection Strategy

**For commands requiring user selection** (e.g., `make live`, `make media`, `make music`):

**Primary method: fzf (fuzzy finder)**
- Use `fzf` for interactive fuzzy selection when available
- Better UX: type to filter, arrow keys to navigate
- Example: Select live performance from list with fuzzy search

**Fallback: Numbered selection**
- If `fzf` not installed, fall back to numbered menu (1-9)
- Simple, works everywhere, no dependencies
- Example: "Select: 1) Performance A, 2) Performance B, 3) Performance C"

**Implementation pattern:**
```bash
if command -v fzf >/dev/null 2>&1; then
    # Use fzf for selection
    selected=$(echo "$options" | fzf)
else
    # Fall back to numbered menu
    echo "Select option (1-9):"
    read -r choice
fi
```

**Benefits:**
- Enhanced UX when fzf available
- Graceful degradation without fzf
- No hard dependency on external tools
- Consistent across all interactive commands

### Future Considerations

- Consider adding shell completion for Make targets
- Document Make patterns in CONTRIBUTING.md
- Add `make doctor` command to check prerequisites
- Consider `make watch` for continuous testing

## Related Decisions

- **ADR-014:** Python for Complex Scripts - Makefile abstracts Python vs shell choice
- **ADR-004:** Development Testing Requirements - Testing commands unified under `make test`
- **ADR-012:** Semantic Versioning - Version commands accessible via `make bump-version`

## References

- GNU Make Manual: https://www.gnu.org/software/make/manual/
- Make Best Practices: https://tech.davis-hansson.com/p/make/
- Self-Documenting Makefiles: https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
