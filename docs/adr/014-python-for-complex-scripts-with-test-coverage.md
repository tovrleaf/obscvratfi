# 14. Python for Complex Scripts with Test Coverage

**Status:** Accepted

**Date:** 2026-02-04

## Context

The project currently uses shell scripts for automation tasks (version bumping, release creation, content management). While shell scripts work, they have limitations:

**Current challenges:**
- No unit testing capability
- Shellcheck warnings indicate potential bugs
- Complex logic is hard to maintain in bash
- Error handling is verbose and error-prone
- Data processing (YAML, JSON) requires external tools
- Cross-platform compatibility issues

**Scripts at time of decision:**
- `scripts/bump-version.sh` - Version management, CHANGELOG parsing (converted to bump_version.py)
- `scripts/create-github-release.sh` - GitHub API calls, text processing
- `scripts/manage-media.sh` - YAML processing, file operations
- `scripts/manage-live.sh` - Interactive prompts, YAML manipulation
- Simple deployment wrappers - Command execution

**Requirements:**
- Testability (unit tests for automation logic)
- Simplicity (easy to understand and maintain)
- 80% test coverage target
- Keep existing Makefile interface
- Maintain workflow consistency

The question: Should we convert scripts to Python for better testability, or fix shellcheck warnings and continue with shell?

## Decision

We will implement a **hybrid approach**: Python for complex scripts, shell for simple wrappers.

### Decision Criteria

**Use Python when:**
- Script has complex logic (parsing, validation, conditionals)
- File/data manipulation (YAML, JSON, text processing)
- API calls (GitHub, external services)
- Needs unit testing
- More than ~50 lines of code

**Use Shell when:**
- Simple command wrappers (< 30 lines)
- Just calling other tools (git, hugo, docker)
- No complex logic or data processing
- No testing needed

### Scripts to Convert to Python

**High Priority (complex logic, needs testing):**
1. `bump-version.sh` → `scripts/bump_version.py`
   - CHANGELOG parsing
   - Version calculation
   - File manipulation
   
2. `create-github-release.sh` → `scripts/create_release.py`
   - GitHub API calls
   - Markdown processing
   - Error handling

3. `manage-media.sh` → `scripts/manage_media.py`
   - YAML processing
   - File operations
   - Interactive prompts

4. `manage-live.sh` → `scripts/manage_live.py`
   - YAML processing
   - Interactive prompts
   - Data validation

**Keep as Shell (simple wrappers):**
- Deployment scripts (if just calling commands)
- Hugo build wrappers
- Docker command shortcuts
- Git operation wrappers

### Testing Requirements

**Coverage Target: 80% minimum**

**Test Types:**
1. **Unit tests** - Test individual functions
2. **Integration tests** - Test end-to-end workflows
3. **Coverage reporting** - Track coverage in CI/CD

**Test Structure:**
```
scripts/
├── bump_version.py
├── create_release.py
├── manage_media.py
├── manage_live.py
└── tests/
    ├── __init__.py
    ├── test_bump_version.py
    ├── test_create_release.py
    ├── test_manage_media.py
    └── test_manage_live.py
```

**Coverage Enforcement:**
- CI/CD fails if coverage < 80%
- Coverage report generated on every test run
- Exclude simple wrappers from coverage requirements

### Tooling

**Add to `requirements-dev.txt`:**
```txt
# Testing
pytest>=7.4.0
pytest-cov>=4.1.0

# Linting & Formatting
ruff>=0.1.0              # Fast linter + formatter (replaces flake8, black, isort)
mypy>=1.7.0              # Type checking (optional)

# Existing tools
pre-commit>=3.5.0
shellcheck-py>=0.9.0
yamllint>=1.33.0
pymarkdownlnt>=0.9.0
```

**Why Ruff?**
- 10-100x faster than flake8/black
- Replaces multiple tools (linter + formatter)
- Drop-in replacement for existing tools
- Used by major projects (FastAPI, Pydantic)

### Makefile Integration

**No changes to user interface:**

```makefile
# Before (shell)
bump-version:
	@scripts/bump-version.sh $(TYPE)

# After (Python)
bump-version:
	@python scripts/bump_version.py $(TYPE)

# Testing
test-scripts:
	@pytest scripts/tests/ --cov=scripts --cov-report=term-missing
```

Users continue using `make bump-version` - implementation is transparent.

### Implementation Phases

**Phase 1: Setup (Week 1)**
- Add pytest, ruff, mypy to requirements-dev.txt
- Update pre-commit hooks for Python linting
- Create scripts/tests/ directory structure
- Document testing guidelines in CONTRIBUTING.md

**Phase 2: Convert Critical Scripts (Week 2-3)**
- Convert `bump_version.py` with tests (80% coverage)
- Convert `create_release.py` with tests (80% coverage)
- Update Makefile targets
- Test end-to-end workflows

**Phase 3: Convert Content Management (Week 4)**
- Convert `manage_media.py` with tests
- Convert `manage_live.py` with tests
- Update documentation

**Phase 4: CI/CD Integration (Week 5)**
- Add pytest to GitHub Actions
- Add coverage reporting
- Enforce 80% coverage requirement
- Update deployment workflow if needed

## Alternatives Considered

### Alternative 1: Fix Shellcheck Warnings, Keep Shell

**Pros:**
- No language change
- Simpler tooling (just shellcheck)
- Familiar to DevOps/sysadmin
- No migration effort

**Cons:**
- Still no unit testing
- Complex logic remains hard to maintain
- Error handling still verbose
- Data processing still requires external tools
- Shellcheck warnings indicate deeper issues

**Why rejected:** Testability is a priority; fixing warnings doesn't add tests

### Alternative 2: Convert All Scripts to Python

**Pros:**
- Single language for all automation
- Consistent tooling
- Everything is testable

**Cons:**
- Overkill for simple wrappers
- Python overhead for trivial tasks
- More complex than needed
- Longer migration effort

**Why rejected:** Hybrid approach is more pragmatic; keep simple things simple

### Alternative 3: Use Go for Scripts

**Pros:**
- Compiled binaries (fast, portable)
- Strong typing
- Good testing support
- Single binary distribution

**Cons:**
- Steeper learning curve
- Compilation step required
- Overkill for scripting tasks
- More complex than Python for text processing

**Why rejected:** Python is simpler for scripting; Go is overkill

### Alternative 4: Use Node.js/TypeScript

**Pros:**
- Type safety (TypeScript)
- Good testing ecosystem
- Familiar if team knows JavaScript

**Cons:**
- Node.js dependency
- npm/package.json overhead
- Not as common for system scripting
- Python is more standard for DevOps

**Why rejected:** Python is more standard for automation scripts

## Consequences

### Positive

- **Testability:** Unit tests catch bugs before production
- **Maintainability:** Python is easier to read and modify than complex bash
- **Error handling:** Python's exception handling is cleaner than bash
- **Data processing:** Native YAML/JSON support, no external tools
- **Type safety:** Optional mypy type checking
- **Cross-platform:** Python works on Windows, macOS, Linux
- **Coverage tracking:** 80% coverage ensures quality
- **Tooling:** Ruff provides fast linting + formatting
- **Simplicity:** Hybrid approach keeps simple things simple
- **No workflow changes:** Makefile interface stays the same

### Negative

- **Migration effort:** Converting scripts takes time
- **Two languages:** Need to maintain both shell and Python
- **Learning curve:** Team needs Python knowledge (though likely already have it)
- **Dependencies:** pytest, ruff, mypy added to dev requirements
- **Test maintenance:** Tests need to be updated when scripts change
- **Coverage overhead:** Writing tests to reach 80% takes time
- **Linting complexity:** Two linters (shellcheck + ruff) instead of one

### Neutral

- **File count:** More files (Python scripts + tests)
- **Makefile:** Stays the same, just calls Python instead of shell
- **CI/CD:** Needs pytest step, but already has testing infrastructure
- **Documentation:** Need to document Python script structure

## Notes

### Python Script Structure

**Standard structure for all Python scripts:**

```python
#!/usr/bin/env python3
"""
Script description.

Usage:
    python script_name.py [arguments]
"""

import argparse
import sys
from pathlib import Path


def main_function(arg1: str, arg2: int) -> int:
    """
    Main logic function.
    
    Args:
        arg1: Description
        arg2: Description
        
    Returns:
        Exit code (0 for success)
    """
    # Implementation
    return 0


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('arg1', help='Description')
    parser.add_argument('--arg2', type=int, default=0, help='Description')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    sys.exit(main_function(args.arg1, args.arg2))
```

### Testing Guidelines

**Test file naming:** `test_<script_name>.py`

**Test structure:**
```python
import pytest
from scripts.bump_version import parse_changelog, bump_version


def test_parse_changelog_valid():
    """Test parsing valid CHANGELOG.md."""
    content = "## [1.0.0] - 2026-01-01\n### Added\n- Feature"
    result = parse_changelog(content)
    assert result['version'] == '1.0.0'


def test_bump_version_patch():
    """Test patch version bump."""
    result = bump_version('1.0.0', 'patch')
    assert result == '1.0.1'


@pytest.fixture
def temp_changelog(tmp_path):
    """Create temporary CHANGELOG.md for testing."""
    changelog = tmp_path / "CHANGELOG.md"
    changelog.write_text("## [1.0.0] - 2026-01-01\n")
    return changelog
```

**Coverage command:**
```bash
pytest scripts/tests/ --cov=scripts --cov-report=term-missing --cov-fail-under=80
```

### Ruff Configuration

**Create `pyproject.toml`:**
```toml
[tool.ruff]
line-length = 100
target-version = "py39"

[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
]
ignore = [
    "E501",  # line too long (handled by formatter)
]

[tool.pytest.ini_options]
testpaths = ["scripts/tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = "--cov=scripts --cov-report=term-missing --cov-fail-under=80"
```

### Migration Checklist

**For each script conversion:**
- [ ] Create Python script with proper structure
- [ ] Write unit tests (80% coverage minimum)
- [ ] Update Makefile target
- [ ] Test end-to-end workflow
- [ ] Update documentation
- [ ] Remove old shell script
- [ ] Commit with reference to ADR-014

### Future Considerations

- Consider adding type hints to all Python scripts
- Consider using `click` library for CLI argument parsing
- Consider adding integration tests for full workflows
- Monitor test execution time (keep tests fast)
- Consider adding mutation testing (mutmut) for test quality
- Document common testing patterns in CONTRIBUTING.md

## Related Decisions

- **ADR-004:** Development Testing Requirements - defines testing approach
- **ADR-010:** Specialized Agent Architecture - Build Agent handles script conversion
- **ADR-012:** Semantic Versioning - bump_version.py implements this

## References

- pytest documentation: https://docs.pytest.org/
- Ruff documentation: https://docs.astral.sh/ruff/
- Python testing best practices: https://docs.python-guide.org/writing/tests/
- Coverage.py: https://coverage.readthedocs.io/
