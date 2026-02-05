# Testing Requirements

Shared testing guidelines for Build Agent and Test Agent.

## Script Testing Requirements

**IMPORTANT:** When modifying existing scripts, always test them before committing:

1. **Syntax validation:** Run `bash -n script.sh` to check for syntax errors
2. **Functional testing:** Execute the script with test inputs to verify behavior
3. **Edge cases:** Test with empty inputs, invalid inputs, and boundary conditions
4. **Integration:** Verify the script works with related files and commands
5. **Cleanup:** Remove test artifacts and restore to pre-testing state

### Example Testing Workflow

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

**Do not hand back modified scripts without testing them first.**
**Always restore the repository to the state it was in before testing.**

## Template/Webpage Testing Requirements

**IMPORTANT:** When modifying Hugo templates, layouts, or content in `website/`, always test by building and validating:

1. **Build the site:** Run `cd website && hugo` to compile
2. **Check for build errors:** Look for ERROR messages in output
3. **Validate HTML:** Run `make test html` to validate HTML files
4. **Verify content:** Check generated HTML contains expected content
5. **Clean up:** Remove test artifacts if needed

### Example Testing Workflow

```bash
# Build the site
cd website && hugo

# Check for errors in build output
cd website && hugo 2>&1 | grep ERROR

# Validate HTML from your changes
make test html

# Verify generated HTML content
cat website/public/media/index.html | grep "expected-content"

# Clean up if needed
rm -rf website/public/
```

**Do not hand back modified templates without building and validating the output.**

## General Testing Principles

- Test the specific thing you changed
- Run appropriate linters/validators
- Check for errors in output
- Verify expected behavior
- Clean up test artifacts
- Restore repository state before handing off

## When to Run Which Tests

**Modified shell scripts (.sh):**
- `bash -n script.sh` (syntax)
- `./script.sh` (functional)
- `make test sh` (shellcheck)

**Modified YAML files (.yml, .yaml):**
- `make test yaml` (yamllint)

**Modified markdown (.md):**
- `make test md` (pymarkdown)

**Modified templates (website/layouts/):**
- `cd website && hugo` (build)
- `make test html` (validation)

**Modified Python (.py):**
- `python3 script.py` (functional)
- `make test py` (pytest + ruff)

**Before committing:**
- Run all relevant tests
- Verify no errors
- Clean up artifacts
- Restore repository state
