# Release Workflow Prompt

Automates the complete release process including version bumping, CHANGELOG updates, tagging, and deployment.

## When to Use

Use this prompt when you're ready to create a new release:
- Feature is complete and merged to main
- Ready to bump version and deploy
- Need to document changes in CHANGELOG

## What This Prompt Does

1. **Determines version bump** - Asks: major, minor, or patch?
2. **Bumps version** - Runs `python3 scripts/bump_version.py [type]`
3. **Prompts for CHANGELOG** - Asks what changed (Added, Changed, Fixed)
4. **Fills CHANGELOG.md** - Updates with your entries
5. **Creates commit** - Proper release commit message
6. **Creates git tag** - Tags with version (e.g., v1.3.0)
7. **Pushes to remote** - Pushes commits and tags
8. **Creates PR** - Opens PR for review
9. **Monitors deployment** - Watches CI/CD until deployed

## Prerequisites

- On a feature branch
- All changes committed
- Tests passing locally

## Usage

```
@workflow-release
```

## Workflow Steps

### 1. Version Bump Selection

Prompt asks:
```
What type of version bump?
- major (1.2.0 → 2.0.0) - Breaking changes
- minor (1.2.0 → 1.3.0) - New features
- patch (1.2.0 → 1.2.1) - Bug fixes
```

### 2. Run Bump Script

Executes:
```bash
python3 scripts/bump_version.py [major|minor|patch]
```

This updates:
- CHANGELOG.md (new version entry)
- website/data/changelog.txt

### 3. Collect CHANGELOG Entries

Prompt asks:
```
What was Added? (new features)
What was Changed? (modifications)
What was Fixed? (bug fixes)
```

### 4. Fill CHANGELOG.md

Updates CHANGELOG.md with your entries:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- Your new features

### Changed
- Your modifications

### Fixed
- Your bug fixes
```

### 5. Create Release Commit

Commits with message:
```
Release vX.Y.Z: Brief description

Updates version to X.Y.Z with the following changes:

Added:
- Feature 1
- Feature 2

Changed:
- Change 1

Fixed:
- Fix 1

Files modified:
- CHANGELOG.md - Version X.Y.Z release notes
- website/data/changelog.txt - Version update
```

### 6. Create Git Tag

```bash
git tag vX.Y.Z
```

### 7. Push to Remote

```bash
git push origin feature/branch
git push --tags
```

### 8. Create Pull Request

Uses GitHub CLI or API to create PR with:
- Title: "Release vX.Y.Z: Brief description"
- Body: CHANGELOG entries
- Auto-opens in browser

### 9. Monitor Deployment

After PR is merged:
- Watches pr-checks workflow
- Watches deploy workflow
- Reports when live at https://obscvrat.fi
- Confirms GitHub release created

## Example Interaction

```
User: @workflow-release

Agent: What type of version bump?
- major (breaking changes)
- minor (new features)
- patch (bug fixes)

User: minor

Agent: Bumping version 1.2.0 → 1.3.0...
✓ Updated CHANGELOG.md
✓ Updated website/data/changelog.txt

What was Added in this release?

User: New media gallery layout
Improved mobile navigation

Agent: What was Changed?

User: Updated footer design
Optimized image loading

Agent: What was Fixed?

User: Mobile menu scroll issue
Link validation errors

Agent: Creating release commit...
✓ Committed: Release v1.3.0: Media gallery and mobile improvements
✓ Tagged: v1.3.0
✓ Pushed to remote

Creating pull request...
✓ PR created: https://github.com/tovrleaf/obscvratfi/pull/123
✓ Opened in browser

Waiting for PR merge...
✓ PR merged to main
✓ pr-checks passed
✓ deploy workflow running...
✓ Deployed to production
✓ GitHub release created: https://github.com/tovrleaf/obscvratfi/releases/tag/v1.3.0

Release v1.3.0 is live at https://obscvrat.fi
```

## Error Handling

**If version bump fails:**
- Check scripts/bump_version.py exists
- Verify CHANGELOG.md format is correct

**If commit fails:**
- Check for uncommitted changes
- Verify git is configured

**If push fails:**
- Check remote access
- Verify branch exists

**If PR creation fails:**
- Check GitHub CLI is installed
- Verify repository permissions

**If deployment fails:**
- Check pr-checks workflow
- Review GitHub Actions logs
- Use @workflow-cicd-fix to resolve

## Agent Delegation

This prompt uses:
- **Build Agent** - Runs bump_version.py, fills CHANGELOG
- **Commit Agent** - Creates commit, tag, pushes
- **Orchestrator Agent** - Monitors workflows, reports status

## Related Prompts

- `@branch` - Create feature branch before starting
- `@commit` - Manual commit workflow
- `@pr` - Manual PR creation
- `@workflow-cicd-fix` - Fix deployment issues

## Notes

- Always test locally before releasing
- Fill CHANGELOG entries thoughtfully
- Use semantic versioning correctly
- Monitor deployment to completion
- Version appears in site footer after deploy
